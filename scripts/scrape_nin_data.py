import requests
import sqlite3
import json
from bs4 import BeautifulSoup
from tqdm import tqdm
import time
import os
import hashlib
import zipfile
from PIL import Image
from io import BytesIO
from concurrent.futures import ProcessPoolExecutor, as_completed
from requests_cache import CachedSession
from nin_variable_steps import build_steps_from_variabeltrinn, format_steps_for_description

# --- CONFIGURATION ---
BASE_URL = 'https://nin-kode-api.artsdatabanken.no/v3.0'
WEB_BASE_URL = 'https://artsdatabanken.no/naturtyper/natur-i-norge'
DB_PATH = 'assets/nin_database.sqlite'
FOOTER_KEYWORDS = ['havnegata', 'trondheim', 'postboks', 'organisasjonsnummer', 'redaksjonen@artsdatabanken.no', 'postmottak', 'torgarden']

# Set to False to bypass cache and get fresh data from the server
USE_CACHE = True
_session = None

def get_session():
    global _session
    if _session is None:
        if USE_CACHE:
            _session = CachedSession('web_cache', backend='filesystem', expire_after=3600*24*7)
        else:
            _session = requests.Session()
    return _session

MAX_WORKERS = 4

# Official icons for top-level categories that lack natural photos
OFFICIAL_ICONS = {
    'C-PE-NA': 'https://artsdatabanken.no/Media/F53505', # Natursystem
    'C-SE-NK': 'https://artsdatabanken.no/Media/F53504', # Naturkompleks
    'C-PE-LA': 'https://artsdatabanken.no/Media/F53500', # Landskapstype
    'A-MV-0': 'https://artsdatabanken.no/Media/F53502',  # Marine vannmasser
    'C-LI-0': 'https://artsdatabanken.no/Media/F53501',  # Livsmedium
    'NA-I': 'https://artsdatabanken.no/Media/F53436',    # Snø- og issystemer
    'NA-M': 'https://artsdatabanken.no/Media/F53735',    # Marine bunnsystemer
    'NA-S': 'https://artsdatabanken.no/Media/F16499',    # Marine vannmassesystemer
    'NA-T': 'https://artsdatabanken.no/Media/F53715',    # Fastmarkssystemer
    'NA-V': 'https://artsdatabanken.no/Media/F53716',    # Våtmarkssystemer
    'NA-F': 'https://artsdatabanken.no/Media/F53749',    # Limniske vannmassesystemer
    'NA-L': 'https://artsdatabanken.no/Media/F53745',    # Innsjøbunnsystemer
    'NA-O': 'https://artsdatabanken.no/Media/F53450',    # Elvebunnsystemer
    'A-LV-FL': 'https://artsdatabanken.no/Media/F53498', # Landformer i fast fjell og løsmasser
    'A-LV-EL': 'https://artsdatabanken.no/Media/F53492', # Elveløp
    'A-LV-IB': 'https://artsdatabanken.no/Media/F53497', # Innsjøbasseng
    'A-LV-TM': 'https://artsdatabanken.no/Media/F53508', # Torvmarksmassiv
    'A-LV-BM': 'https://artsdatabanken.no/Media/F53491', # Bremassiv
}

def setup_db():
    if os.path.exists(DB_PATH): os.remove(DB_PATH) # ALWAYS clean run
    # Also wipe temp_images for a 100% clean run
    import shutil
    if os.path.exists('temp_images'): shutil.rmtree('temp_images')
    os.makedirs('temp_images', exist_ok=True)
    os.makedirs('assets', exist_ok=True)
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    cursor.execute('''CREATE TABLE nin_types (
        id TEXT PRIMARY KEY, 
        navn TEXT, 
        kategori TEXT, 
        parent_id TEXT, 
        ecosystnivaa_navn TEXT, 
        typekategori_navn TEXT, 
        langkode TEXT, 
        definisjon TEXT, 
        image_url TEXT, 
        description TEXT, 
        lkm_data TEXT,
        scale TEXT,
        contains_types TEXT
    )''')
    cursor.execute('''CREATE TABLE nin_variables (
        id TEXT PRIMARY KEY, 
        navn TEXT, 
        kategori TEXT, 
        parent_id TEXT, 
        ecosystnivaa_navn TEXT,
        variabelkategori_navn TEXT,
        langkode TEXT,
        description TEXT,
        steps_json TEXT
    )''')
    conn.commit()
    return conn

def extract_text_from_soup(soup):
    content = soup.find('main', id='main-content') or soup.find('article') or soup.body
    if not content: return ""
    
    # Filter out obvious UI elements
    for nav in content.find_all(['nav', 'button', 'script', 'style', 'header', 'footer']): 
        nav.decompose()
    
    captured = []
    found_start = False
    
    # Common start markers
    start_markers = ['Inndeling', 'Beskrivelse', 'Bruk av variabelen', 'Definisjon', 'Identifisering', 'Innhold']
    
    for el in content.find_all(['h2', 'h3', 'h4', 'p', 'ul', 'ol']):
        text = el.get_text(separator=' ', strip=True)
        if not text: continue
        
        # Skip breadcrumbs/nav
        if not found_start:
            if el.name == 'p' and len(text) > 100 and 'Forside' not in text:
                found_start = True
            elif el.name.startswith('h') and any(m in text for m in start_markers):
                found_start = True
            
            if not found_start: continue

        # Stop markers
        if any(kw in text.lower() for kw in FOOTER_KEYWORDS) or 'Siden siteres som' in text:
            break
        
        if el.name.startswith('h'):
            captured.append(f"### {text}")
        elif el.name == 'ul' or el.name == 'ol':
            items = [li.get_text(strip=True) for li in el.find_all('li')]
            for item in items:
                if len(item) > 5:
                    captured.append(f"- {item}")
        else:
            if len(text) > 20:
                captured.append(text)
    
    return "\n\n".join(captured)

def fetch_metadata(langkode):
    """Scrape ALL available descriptions and merge them."""
    if not langkode: return None, None
    headers = {'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'}
    
    short_desc = ""
    long_desc = ""
    img_url = None
    
    # 1. Main Page (Short Ingress + Image + Potential Long Desc)
    try:
        url = f"{WEB_BASE_URL}/{langkode}"
        r = get_session().get(url, headers=headers, timeout=10)
        if r.status_code == 200:
            soup = BeautifulSoup(r.text, 'html.parser')
            ingress = soup.find(class_='ingress')
            if ingress: short_desc = ingress.get_text().strip()
            
            # For variables, everything is usually on the main page
            long_desc = extract_text_from_soup(soup)
            
            # Harvesting Image
            content = soup.find(class_='main-content') or soup.find(id='main-content') or soup.body
            img_containers = [soup.find(class_='image'), soup.find(class_='image-and-caption__picture'), content]
            for container in img_containers:
                if not container: continue
                for img in container.find_all('img'):
                    src = img.get('src', '')
                    if not src: continue
                    src_lower = src.lower()
                    if ('/public/' in src or '/sites/default/files/' in src) and \
                       not any(x in src_lower for x in ['icon', 'logo', 'social', 'user', 'theme', 'avatar', 'favicons']):
                        img_url = src if src.startswith('http') else f"https://artsdatabanken.no{src}"
                        break
                if img_url: break
    except: pass

    # 2. Description Page (Deep Biological Detail - often for Types)
    try:
        desc_url = f"{WEB_BASE_URL}/{langkode}/beskrivelse"
        r = get_session().get(desc_url, headers=headers, timeout=10)
        if r.status_code == 200:
            soup_desc = BeautifulSoup(r.text, 'html.parser')
            desc_long = extract_text_from_soup(soup_desc)
            if desc_long and len(desc_long) > len(long_desc):
                long_desc = desc_long
    except: pass

    # Merge them intelligently
    full_text = short_desc
    if long_desc:
        # Avoid duplicate starting text if long_desc repeats short_desc
        if full_text and long_desc.startswith(full_text[:50]):
            full_text = long_desc
        else:
            full_text = f"{full_text}\n\n{long_desc}".strip()
            
    return full_text if full_text else None, img_url

def download_and_optimize_image(url, type_id):
    if not url: return None
    try:
        filename = f"{hashlib.md5(type_id.encode()).hexdigest()}.webp"
        filepath = os.path.join('temp_images', filename)
        if os.path.exists(filepath): return filename
        
        r = get_session().get(url, headers={'User-Agent': 'Mozilla/5.0'}, timeout=15)
        if r.status_code == 200:
            img = Image.open(BytesIO(r.content))
            if img.mode in ('RGBA', 'P'): img = img.convert('RGB')
            img.save(filepath, 'WEBP', quality=85)
            return filename
    except: pass
    return None

def fix_broken_encoding(s):
    """Fix common encoding issues from the NiN API where some fields use mixed encodings."""
    if not s: return s
    mapping = {
        'milj\ufffdvariabel': 'miljøvariabel',
        'milj\ufffddynamikk': 'miljødynamikk',
        'artsfordelingsm\ufffdnster': 'artsfordelingsmønster',
    }
    for broken, fixed in mapping.items():
        s = s.replace(broken, fixed)
    return s.replace('\ufffd', 'ø') # Fallback: most remaining broken chars in categories are 'ø'

def process_single_type(t):
    # Heartbeat
    print(f"Processing {t['id']}...") 
    
    try:
        # 1. Matrix Data & Relationships
        if t['kategori'] in ['Grunntype', 'Kartleggingsenhet']:
            try:
                endpoint = "kodeforGrunntype" if t['kategori'] == 'Grunntype' else "kodeforKartleggingsenhet"
                dr = get_session().get(f"{BASE_URL}/typer/{endpoint}/{t['id']}", timeout=10)
                if dr.status_code == 200:
                    data = dr.json()
                    
                    # Parse LKM data
                    def parse_lkm(obj):
                        l_list = []
                        def w(o, current_var_name=None):
                            if isinstance(o, dict):
                                # Capture variable name if present at this level
                                # In NiN 3.0, variabelnavn is an object containing a 'navn' field
                                var_obj = o.get('variabelnavn')
                                var_name = current_var_name
                                if isinstance(var_obj, dict):
                                    var_name = var_obj.get('navn') or current_var_name
                                elif isinstance(var_obj, str):
                                    var_name = var_obj
                                
                                if o.get('registert') == True and o.get('kode'):
                                    k = o['kode']
                                    ki = k['id'] if isinstance(k, dict) else str(k)
                                    vi = ki.split('_')[0] if '_' in ki else ki
                                    if any(p in vi for p in ['LM-', 'KM-', 'KA-', 'UF-', 'HI-', 'VM-']):
                                        l_list.append({
                                            'v_kode': vi, 
                                            'v_navn': var_name, 
                                            'v_trinn': o.get('verdi'), 
                                            'v_trinn_navn': o.get('beskrivelse')
                                        })
                                
                                # Recursively process children
                                for v in o.values(): w(v, var_name)
                            elif isinstance(o, list):
                                for i in o: w(i, current_var_name)
                        w(obj)
                        return json.dumps(l_list) if l_list else None
                    
                    t['lkm_data'] = parse_lkm(data)
                    
                    # For Kartleggingsenhet, also capture constituent Grunntyper if not already present
                    if t['kategori'] == 'Kartleggingsenhet' and data.get('grunntyper'):
                        t['contains_types'] = json.dumps([g['kode']['id'] for g in data['grunntyper']])
            except Exception as e:
                pass

        # 2. Metadata (Strict match)
        img_url = OFFICIAL_ICONS.get(t['id'])
        desc, web_img = fetch_metadata(t['langkode'])
        if not img_url: img_url = web_img
        
        t['description'] = desc
        if img_url:
            t['image_url'] = download_and_optimize_image(img_url, t['id'])
            
    except Exception as e:
        print(f"\nError processing {t['id']}: {e}")
        
    return t

def process_single_variable(v):
    # Try to fetch long description from web
    desc, _ = fetch_metadata(v['langkode'])
    
    parts = []
    if desc:
        parts.append(desc)
        parts.append("\n---\n") # Visual separator
    
    # Always add synthesized metadata/trinn for consistency
    if v.get('kategori'): parts.append(f"Kategori: {v['kategori']}")
    if v.get('ecosystnivaa_navn'): parts.append(f"Økosystemnivå: {v['ecosystnivaa_navn']}")
    
    if v.get('steps_json'):
        try:
            steps = json.loads(v['steps_json'])
            parts.extend(format_steps_for_description(steps))
        except: pass
            
    v['description'] = "\n".join(parts)
    return v

def main():
    conn = setup_db()
    cursor = conn.cursor()
    os.makedirs('temp_images', exist_ok=True)

    print("Step 1: Fetching NiN 3.0 Variables (LKM)...")
    v_r = get_session().get(f"{BASE_URL}/variabler/allekoder", timeout=15)
    var_data = v_r.json()
    all_vars = []
    
    def walk_vars(item, parent_id=None):
        kode = item.get('kode')
        if not kode: return
        
        k_id = kode['id']
        
        # Keep måleskala identity — do not flatten all variabeltrinn into one list
        scales = build_steps_from_variabeltrinn(item.get('variabeltrinn'))
        
        all_vars.append({
            'id': k_id,
            'navn': item.get('navn', k_id),
            'kategori': fix_broken_encoding(item.get('kategori') or item.get('variabelkategori2Navn') or item.get('variabelkategoriNavn') or 'Lokal kompleks miljøvariabel (LKM)'),
            'parent_id': parent_id,
            'ecosystnivaa_navn': fix_broken_encoding(item.get('ecosystnivaaNavn')),
            'variabelkategori_navn': fix_broken_encoding(item.get('variabelkategoriNavn')),
            'langkode': kode.get('langkode'),
            'steps_json': json.dumps(scales, ensure_ascii=False) if scales else None
        })
        
        # Recursive keys in NiN 3.0 structure
        for key in ['variabelnavn', 'underordneteVariabler', 'underordneteKoder', 'variabler']:
            if item.get(key):
                for sub in item[key]: 
                    walk_vars(sub, k_id)

    for root in var_data['variabler']: walk_vars(root)

    print(f"Step 2: Deep Scrape Variables ({len(all_vars)} items)...")
    with ProcessPoolExecutor(max_workers=MAX_WORKERS) as executor:
        future_to_var = {executor.submit(process_single_variable, v): v for v in all_vars}
        for future in tqdm(as_completed(future_to_var), total=len(all_vars)):
            v = future.result()
            cursor.execute('''INSERT OR REPLACE INTO nin_variables VALUES (?,?,?,?,?,?,?,?,?)''', (
                v['id'], v['navn'], v['kategori'], v['parent_id'], 
                v['ecosystnivaa_navn'], v['variabelkategori_navn'], v['langkode'], v['description'], v['steps_json']
            ))
    conn.commit()

    print("Step 3: Building Type Hierarchy...")
    r = get_session().get(f"{BASE_URL}/typer/allekoder")
    data = r.json()
    all_types = []

    def walk_types(item, parent_id=None):
        kode = item['kode']
        contains = None
        if item.get('grunntyper') and item['kategori'] == 'Kartleggingsenhet':
            contains = json.dumps([g['kode']['id'] for g in item['grunntyper']])
        all_types.append({
            'id': kode['id'], 'navn': item['navn'], 'kategori': item['kategori'], 'parent_id': parent_id,
            'ecosystnivaa_navn': item.get('ecosystnivaaNavn'), 'typekategori_navn': item.get('typekategoriNavn'),
            'langkode': kode.get('langkode'), 'definisjon': kode.get('definisjon'),
            'image_url': None, 'description': None, 'lkm_data': None,
            'scale': item.get('maalestokkEnum'), 'contains_types': contains
        })
        for key in ['hovedtypegrupper', 'hovedtyper', 'grunntyper', 'kartleggingsenheter']:
            if item.get(key):
                for sub in item[key]: walk_types(sub, kode['id'])

    for root in data['typer']: walk_types(root)
    
    print(f"Step 4: Gold Run Deep Scrape Types ({len(all_types)} items)...")
    with ProcessPoolExecutor(max_workers=MAX_WORKERS) as executor:
        future_to_type = {executor.submit(process_single_type, t): t for t in all_types}
        for i, future in enumerate(tqdm(as_completed(future_to_type), total=len(all_types))):
            t = future.result()
            cursor.execute('''INSERT OR REPLACE INTO nin_types VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)''', (
                t['id'], t['navn'], t['kategori'], t['parent_id'], t['ecosystnivaa_navn'], 
                t['typekategori_navn'], t['langkode'], t['definisjon'], t['image_url'], 
                t['description'], t['lkm_data'], t['scale'], t['contains_types']
            ))
            if i % 100 == 0: conn.commit()
    conn.commit()

    print("Step 5: Bundling images.zip...")
    if os.path.exists('assets/images.zip'): os.remove('assets/images.zip')
    with zipfile.ZipFile('assets/images.zip', 'w', zipfile.ZIP_DEFLATED) as img_zip:
        for img_file in os.listdir('temp_images'):
            img_zip.write(os.path.join('temp_images', img_file), img_file)

    print(f"Done! Final Database: {DB_PATH}")
    conn.close()

if __name__ == "__main__":
    main()
