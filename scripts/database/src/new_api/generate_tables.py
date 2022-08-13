# %%
from sqlalchemy import create_engine
import sqlalchemy as sa
import importlib
import model
import pandas as pd
import new_api.artsdatabanken_nin_api
importlib.reload(model)
importlib.reload(new_api.artsdatabanken_nin_api)
from model import model
from new_api.artsdatabanken_nin_api import ArtsdatabankenNinApi
from sqlalchemy.orm import sessionmaker
# %%
api = ArtsdatabankenNinApi('https://nin-kode-api.artsdatabanken.no')
# %%
database_file = '/data/assets/nin_database.db'
engine = create_engine(f'sqlite:///{database_file}')
Session = sessionmaker(bind=engine)
session = Session()
# %%

def get_name_for_adb_code(code):
    resp = api.get_specific_code(code)
    return resp['Navn']

def get_name_detail_for_db_code(code):
    return session.query(model.Detail).where(
        model.Detail._id == code,
        model.Detail.key == '__name__',
        model.Detail.language_id == 'nb'
    ).first()
def strip_na(text):
    return text.split(' ')[-1]
def add_na(text):
    return f'NA {text}'
# %%

mtgs_adb = [x for x in api.all_codes if x['Kategori'] == 'Naturmangfoldnivå']
assert(len(mtgs_adb) == 1)
mtgs_adb = mtgs_adb[0]['UnderordnetKoder']
mtgs_adb = [x['Id'] for x in mtgs_adb]

# %%

def add_es(ss_adb, lkm_db, mt_db, ss_id_db):
    es_ids = ss_adb['Basistrinn'].split(', ')
    for es_id in es_ids:
        print(f'Elementary segment: {es_id}')
        value = es_id.split('-')[-1]
        es_db = session.query(model.ElementarySegment).where(
            model.ElementarySegment._id == es_id).all()
        assert(len(es_db) <=1)
        if len(es_db) == 0:
            session.add(model.ElementarySegment(
                _id = es_id,
                lec_id = lkm_db._id,
                value=value,
                order=0
            ))
        session.add(model.ElementarySegmentGroup(
            _id = es_id,
            elementarySegment_id = es_id,
            majorType_id = mt_db._id,
            lec_id = lkm_db._id,
            standardSegment_id = ss_id_db
        ))
        sse_db = session.query(model.StandardSegmentElement).where(
            model.StandardSegmentElement.standardSegment_id == ss_id_db,
            model.StandardSegmentElement.elementarySegment_id == es_id
        )
        if sse_db.count() == 0:
            session.add(model.StandardSegmentElement(
                standardSegment_id = ss_id_db,
                elementarySegment_id = es_id
            ))
        session.flush()
def add_ss(ss_adb, lkm_db, mt_db, mt_lec_id_db, order):
    ss_id_db = ss_adb['Kode']
    detail_id = f'standard_segment_{ss_id_db}'
    session.add(model.StandardSegment(
        _id=ss_id_db,
        majorTypeLEC_id=mt_lec_id_db,
        order = order,
        detail_id = detail_id,
        lec_id = lkm_db._id,
        majorType_id = mt_db._id,
        selected = (order==0)
    ))
    add_es(ss_adb, lkm_db, mt_db, ss_id_db)

lec_type_map = {
    'dLKM' : 'dLEC',
    'tLKM' : 'iLEC',
    'hLKM' : 'mLEC',
    'uLKM' : 'uLEC',
    '_null' : 'null'
}
def add_segments(mt_id_adb, mt_db):
    mt_adb = api.get_specific_code_from_net(mt_id_adb)
    if 'Miljovariabler' not in mt_adb.keys():
        return
    lkms_adb = mt_adb['Miljovariabler']
    for idx, lkm_adb in enumerate(lkms_adb):
        lkm_q = session.query(model.LEC).where(model.LEC._id==lkm_adb['Kode'])
        
        if lkm_q.count() < 1:
            lkm_detail_id = f"lec_{lkm_adb['Kode']}"
            lkm_db = model.LEC(
                _id = lkm_adb['Kode'],
                detail_id = lkm_detail_id
            )
            session.add(lkm_db)
            session.add(model.Detail(
                _id = lkm_detail_id,
                language_id = 'nb',
                key = '__name__',
                value = lkm_adb['Navn']
            ))
            session.flush()
        else:
            lkm_db = lkm_q[0]
        mt_lec_id_db = f'{mt_db._id}-{lkm_db._id}'
        mt_lec_db = model.MajorTypeLEC(
            _id = mt_lec_id_db,
            lec_id = lkm_db._id,
            majorType_id = mt_db._id,
            lecType_id = lec_type_map[lkm_adb['LKM Kategori']],
            axis = None
        )
        session.add(mt_lec_db)
        detail = get_name_detail_for_db_code(lkm_db.detail_id)
        detail.value = lkm_adb['Navn']
        standart_segments_adb = lkm_adb['Trinn']
        for ss_idx, ss_adb in enumerate(standart_segments_adb):
            add_ss(ss_adb=ss_adb,
            lkm_db=lkm_db,
            mt_db=mt_db,
            mt_lec_id_db=mt_lec_db._id,
            order=ss_idx
            )
        session.flush()

def add_mintss(mints_id_adb, mint_id_db, mappingScale_id):
    mappingScale_id = int(mappingScale_id)
    mints_id_db = strip_na(mints_id_adb)
    mintss = session.query(model.MinorTypeScaled)\
        .where(model.MinorTypeScaled.mappingScale_id == mappingScale_id,
        model.MinorTypeScaled._id == mints_id_db,
        model.MinorTypeScaled.minorType_id == mint_id_db
        )
    if mintss.count() > 0:
        return
    mints_detail_id = f'minor_type_scaled_{mints_id_db}'
    session.add(model.MinorTypeScaled(
        _id=mints_id_db,
        minorType_id=mint_id_db,
        mappingScale_id=mappingScale_id,
        detail_id=mints_detail_id,
        is_implemented=True,
    ))
    
    session.add(model.Detail(_id=mints_detail_id,
        language_id = 'nb',
        key = '__name__',
        value = get_name_for_adb_code(mints_id_adb)
    ))
    session.flush()


    
def add_mints(mt_id_db, mint_id_adb, used_lec_ids):
    mint_adb = api.get_specific_code_from_net(mint_id_adb)
    mint_id_db = strip_na(mint_id_adb)
    detail_id = f'minor_type_{mint_id_db}'

    print(f'To Write MINT {mint_id_db}')
    session.add(model.MinorType(_id = mint_id_db,
        majorType_id=mt_id_db,
        detail_id=detail_id))
    session.add(model.Detail(_id=detail_id,
            language_id = 'nb',
            key = '__name__',
            value = mint_adb['Navn']
        ))
    
    add_mintss(mints_id_adb=mint_id_adb,
    mappingScale_id=500,
    mint_id_db=mint_id_db)
    if 'Kartleggingsenheter' not in mint_adb.keys():
        print(f'Kartleggingsenheter not in {mint_adb}')
        return
    for scale in mint_adb['Kartleggingsenheter']:
        for mints in mint_adb['Kartleggingsenheter'][scale]:
            add_mintss(mints_id_adb=mints['Id'],
            mappingScale_id=scale,
            mint_id_db=mint_id_db)
    # add minorTypeSegment link
    session.flush()


def add_mts(mtg_id_db, mt_id_adb):
    mt_db_id = strip_na(mt_id_adb)
    mt_db_id = f'{mt_db_id[0]}-{mt_db_id[1:]}'

    order = int(mt_db_id.split('-')[-1])
    detail_id = f'major_type_{mt_db_id}'

    print(f'Write {mt_db_id}')
    
    mt_db = model.MajorType(_id=mt_db_id,
        majorTypeGroup_id=mtg_id_db,
        order=order,
        detail_id=detail_id,
    )
    session.add(mt_db)
    session.add(model.Detail(_id=detail_id,
        language_id = 'nb',
        key = '__name__',
        value = get_name_for_adb_code(mt_id_adb)
    ))
    # Add segments
    add_segments(mt_id_adb=mt_id_adb, mt_db=mt_db)
    
    
    # Add minor types
    
    mints = api.get_specific_code(mt_id_adb)
    if 'UnderordnetKoder' not in mints.keys():
        print(f'No `UnderordnetKoder` : {mints}')
        return
    mint_adb_ids = [x['Id'] for x in mints['UnderordnetKoder']]
    for mint_adb_id in mint_adb_ids:
        add_mints(mt_db_id, mint_adb_id, used_lec_ids)
        # except Exception as e:
        #     print(f'Unable to update mint: {mint_adb_id}\n\t{e}')


# %% Delete mtgs from db
session.query(model.MajorTypeGroup).delete()
session.query(model.MajorType).delete()
session.query(model.MinorType).delete()
session.query(model.MinorTypeScaled).delete()
session.query(model.ElementarySegment).delete()
session.query(model.ElementarySegmentGroup).delete()
session.query(model.StandardSegmentElement).delete()
session.query(model.StandardSegment).delete()
session.query(model.MajorTypeLEC).delete()
session.query(model.MinorTypeStandardSegment).delete()


to_delete = session.query(model.Detail)\
    .filter(model.Detail._id.startswith('major_type'))\
    .where(model.Detail.key == '__name__').all()
for item in to_delete:
    session.delete(item)
to_delete = session.query(model.Detail)\
    .filter(model.Detail._id.startswith('minor_type'))\
    .where(model.Detail.key == '__name__').all()
for item in to_delete:
    session.delete(item)
session.commit()

# %% add MajorTypeGroups
for mtg_id_adb in mtgs_adb:
    mtg_id_db = strip_na(mtg_id_adb)
    
    
    _id = mtg_id_db
    detail_id = f'major_type_group_details_{_id}'
    
    print(f'Write {mtg_id_adb}')
    session.add(model.MajorTypeGroup(_id=_id, detail_id=detail_id))
    session.add(model.Detail(_id=detail_id,
        language_id = 'nb',
        key = '__name__',
        value = get_name_for_adb_code(mtg_id_adb))
    )
    # session.commit()
    mtg = api.get_specific_code(mtg_id_adb)
    mts_ids_adb = mtg['UnderordnetKoder']
    mts_ids_adb = [x['Id'] for x in mts_ids_adb]
    for mt_id_adb in mts_ids_adb:
        add_mts(mtg_id_db, mt_id_adb)
session.commit()


# %% add order to elementary segments
lec_ids = session.query(model.ElementarySegment.lec_id).distinct()
for lec_id in lec_ids:
    lec_id =lec_id[0]
    print(lec_id)
    q = session.query(model.ElementarySegment).where(
        model.ElementarySegment.lec_id == lec_id
    ).all()
    full_list=[
        'A', 'B', 'C', 'D',
        '0',
        'a',
        'b',
        'c',
        'd',
        'e',
        'f',
        'g',
        'h',
        'i',
        'j',
        'k',
        'l',
        'm',
        'n',
        'o',
        'p',
        'q',
        'r',
        's',
        't',
        'u',
        'v',
        '+',
        '¤',
    ]
    res_list = full_list.copy()
    used_values = [x.value for x in q]
    for value in full_list:
        if value not in used_values:
            res_list.remove(value)
    for idx, val in enumerate(res_list):
        es = session.query(model.ElementarySegment).where(
            model.ElementarySegment.lec_id == lec_id,
            model.ElementarySegment.value == val
        ).first()
        es.order = idx
        session.flush()
    session.commit()
    print(res_list)
 # %% Fix majorTypeLEC axis
import pandas as pd
import numpy as np
old_mt_lec = pd.read_csv('majorTypeLec.csv')
undecided = []
mt_lecs = session.query(model.MajorTypeLEC).all()
for mt_lec in mt_lecs:
    mt_lec.axis = None
    if mt_lec.lecType_id == 'null':
        mt_lec.lecType_id = 'uLEC'
    
    if mt_lec.lecType_id not in ['uLEC', 'dLEC', 'null']:
        old = old_mt_lec[
            (old_mt_lec['majorType_id'] == mt_lec.majorType_id) &\
            (old_mt_lec['lec_id'] == mt_lec.lec_id)    
                ]
        if len(old) != 1 or np.isnan(old['axis']).any():
            undecided.append(mt_lec)
            print(f'unable to find old: {mt_lec._id}')
        else:
            old =old.iloc[0]
            mt_lec.axis = int(old['axis'])
    session.flush()
session.commit()

undecided_mt_ids = list(set([x.majorType_id for x in undecided]))
# undecidete_mt_id = undecided_mt_ids[0]
for undecidete_mt_id in undecided_mt_ids:
    problematic = session.query(model.MajorTypeLEC)\
        .where(
        model.MajorTypeLEC.majorType_id == undecidete_mt_id)\
        .filter(model.MajorTypeLEC.lecType_id.in_(['mLEC', 'iLEC']))\
        .order_by(model.MajorTypeLEC.lecType_id.desc())\
        .all()

    for idx, prob in enumerate(problematic):
        if idx < 2:
            prob.axis=idx
        else:
            prob.axis=2
    session.flush()

session.commit()
# %% Add minorTypeSegments
def add_mtsegs(mint_adb, used_lec_ids, mt_id_db, mint_id_db):
    if 'Basistrinn' not in mint_adb.keys():
        print(f'No Basistrinn in {mint_adb}')
        return
    ess_adb = [x['Id'] for x in mint_adb['Basistrinn']]
    ess_adb_df = pd.DataFrame({'es': ess_adb})
    ess_adb_df['lec_id'] = ess_adb_df['es'].apply(lambda x: x.split('-')[0])
    ess_adb_lec_set = set(ess_adb_df['lec_id'])
    for used_lec_id in used_lec_ids:
        if used_lec_id in ess_adb_lec_set:
            ess = list(ess_adb_df[ess_adb_df['lec_id']==used_lec_id]['es'])
            ss_ids = session.query(model.ElementarySegmentGroup.standardSegment_id.distinct())\
                .where(
                    model.ElementarySegmentGroup.majorType_id == mt_id_db,
                    model.ElementarySegmentGroup.lec_id == used_lec_id)\
                .filter(
                    model.ElementarySegmentGroup.elementarySegment_id.in_(ess)
                ).all()
            ss_ids = [x[0] for x in ss_ids]
            for ss_id in ss_ids:
                session.add(model.MinorTypeStandardSegment(
                    minorType_id=mint_id_db,
                    standardSegment_id=ss_id
                ))
        else:
            ss_id = session.query(model.StandardSegment._id).where(
                model.StandardSegment.order==0,
                model.StandardSegment.lec_id==used_lec_id,
                model.StandardSegment.majorType_id==mt_id_db
            ).all()
            try:
                assert(len(ss_id)==1)
            except:
                raise Exception(f'wrong number of ss found lec_id:{used_lec_id}\n\tmt_id:{mt_id_db}')
            ss_id = ss_id[0][0]
            session.add(model.MinorTypeStandardSegment(
                    minorType_id=mint_id_db,
                    standardSegment_id=ss_id
                ))
        session.flush()

for mt_db in session.query(model.MajorType).all():
    # get distinct used lec
    used_lec_ids = [x[0] for x in session.query(model.MajorTypeLEC.lec_id.distinct())\
        .filter(model.MajorTypeLEC.lecType_id.in_(['iLEC','mLEC']))\
        .where(model.MajorTypeLEC.majorType_id==mt_db._id).all()]
    print(f'used Lec_ids: {used_lec_ids}')
    mints_q = session.query(model.MinorType).where(model.MinorType.majorType_id==mt_db._id)
    for mint_db in mints_q.all():
        mint_adb = api.get_specific_code_from_net(add_na(mint_db._id))
        print
        add_mtsegs(mint_adb=mint_adb,mint_id_db=mint_db._id,mt_id_db=mt_db._id, used_lec_ids=used_lec_ids)
session.commit()

# %% Delete duplicate details
# Create a query that identifies the row for each domain with the lowest id
inner_q = session.query(sa.func.min(model.Detail.pid)).group_by(
    model.Detail._id,
    model.Detail.key,
    model.Detail.language_id)
aliased = sa.alias(inner_q)
# Select the rows that do not match the subquery
q = session.query(model.Detail).filter(~model.Detail.pid.in_(aliased))

# %% Delete the unmatched rows (SQLAlchemy generates a single DELETE statement from this loop)
for domain in q:
    session.delete(domain)
session.commit()



