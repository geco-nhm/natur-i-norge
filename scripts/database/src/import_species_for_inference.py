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
import re
import json
import numpy as np
# %%
api = ArtsdatabankenNinApi('https://nin-kode-api.artsdatabanken.no')
# %%
database_file = '/data/assets/nin_database.db'
engine = create_engine(f'sqlite:///{database_file}')
Session = sessionmaker(bind=engine)
session = Session()
# %%
orig = pd.read_excel('/data/data-prep/raw/Arter_AR8v23_20220404.xlsx', sheet_name='AR8', header=[0])
orig = orig[['KE','Kode_AR8', 'scientificNameID']]
gbif_mapping = pd.read_csv('/data/data-prep/output/species_with_gbif_id.csv')
gbif_mapping = gbif_mapping[['scientificNameID', 'gbif_id']]
types = pd.merge(orig,gbif_mapping)
types.columns = ['minorTypeScaled_id', 'full_code', 'scientificNameID', 'gbif_id']
types = types[types.columns.drop('scientificNameID')]
def get_code(text):
    try:
        return json.dumps(re.findall(r'([mvst][-+*]?)', text))
    except Exception as e: 
        # print(f'unable to parse {text}\n{e}')
        return
types['code'] = types['full_code'].apply(get_code)
# %%
species = pd.read_excel('/data/data-prep/raw/Arter_AR8v23_20220404.xlsx', sheet_name='Artsliste', header=[0])
species = species[['Latinsk navn', 'Norsk navn', 'scientificNameID']]
species.columns = ['name_latin', 'name_nb', 'scientificNameID']
species = pd.merge(species, gbif_mapping)
species = species[species.columns.drop('scientificNameID')]
species = species.drop_duplicates()
# %%
mints_to_add = []
for mints in types['minorTypeScaled_id'].unique():
    mints_db = session.query(model.MinorTypeScaled).where(model.MinorTypeScaled._id==mints).first()
    if mints_db == None:
        mints_to_add.append(mints)
# %%
for mints in mints_to_add:
    parts = re.findall(r'([A-Z]\d+)-([A-Z])-(\d+)',mints)
    parts = parts[0]
    adb_mt = f'NA {parts[0]}'
    print(adb_mt)
    adb_resp = api.get_specific_code(adb_mt)
    mint_id = f'{parts[0]}-{parts[2]}'
    mint_detail_id = f'minor_type_{mint_id}'
    mints_id = mints
    mints_detail_id = f'minor_type_scaled_{mints_id}'
    mt_parts = re.findall(r'([A-Z])(\d+)', mints)[0]
    mt_id = f'{mt_parts[0]}-{mt_parts[1]}'
    print(mint_id)
    print(mint_detail_id)
    print(mints_id)
    print(mints_detail_id)
    print(mt_id)
    session.add(model.MinorType(
        _id=mint_id,
        majorType_id=mt_id,
        detail_id=mint_detail_id))
    session.add(model.Detail(
        _id=mint_detail_id,
        language_id='nb',
        key='__name__',
        value=adb_resp['Navn'],
    ))
    session.add(model.MinorTypeScaled(
        _id=mints_id,
        minorType_id=mint_id,
        mappingScale_id=5000,
        detail_id=mints_detail_id,
        is_implemented=True,
    ))
    session.add(model.Detail(
        _id=mints_detail_id,
        language_id='nb',
        key='__name__',
        value=adb_resp['Navn'],
    ))
session.commit()
# %%
model.InferenceSpecies.__table__.drop(engine)
model.InferenceTypes.__table__.drop(engine)
# %%
model.Base.metadata.create_all(engine)
# %%
for _, row in types.iterrows():
    session.add(model.InferenceTypes(
        minorTypeScaled_id=row['minorTypeScaled_id'],
        full_code=row['full_code'],
        gbif_id=row['gbif_id'],
        code=row['code']
    ))

# %%
for _, row in species.iterrows():
    session.add(model.InferenceSpecies(
        name_latin=row['name_latin'],
        gbif_id=row['gbif_id'],
        name_nb=row['name_nb']
    ))
# %%
session.commit()
# %%
from tools.moor_exporter import generate_moor
generate_moor(engine, '/data/db/schema.moor')
# %%
from tools.schema_creator import create_schema
create_schema(model)
# %%
