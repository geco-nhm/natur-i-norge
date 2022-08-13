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
# api = ArtsdatabankenNinApi('https://nin-kode-api.artsdatabanken.no')
# %%
database_file = '/data/assets/nin_database.db'
engine = create_engine(f'sqlite:///{database_file}')
Session = sessionmaker(bind=engine)
session = Session()
# %%
orig = pd.read_excel('/data/data-prep/raw/Arter_AR8v23_20220404.xlsx', sheet_name='AR8', header=[0])
orig = orig[['KE','Latinsk navn_AR8', 'Norsk navn_AR8', 'Kode_AR8', 'scientificNameID']]
gbif_mapping = pd.read_csv('/data/data-prep/output/species_with_gbif_id.csv')
gbif_mapping = gbif_mapping[['scientificNameID', 'gbif_id']]
merged = pd.merge(orig,gbif_mapping)
merged.columns = ['minorType_id', 'name_latin', 'name_nb', 'full_code', 'scientificNameID', 'gbif_id']
merged = merged[merged.columns.drop('scientificNameID')]
# %%
def get_code(text):
    try:
        return json.dumps(re.findall(r'([mvst][-+*]?)', text))
    except Exception as e: 
        # print(f'unable to parse {text}\n{e}')
        return
# %%
merged['code'] = merged['full_code'].apply(get_code)
# %%
merged
# %%
model.Base.metadata.create_all(engine)
# %%
for _, row in merged.iterrows():
    session.add(model.InferenceSpecies(
        minorType_id=row['minorType_id'],
        name_latin=row['name_latin'],
        name_nb=row['name_nb'],
        full_code=row['full_code'],
        gbif_id=row['gbif_id'],
        code=row['code']
    ))
# %%
session.commit()
# %%
from tools.moor_exporter import generate_moor
generate_moor(engine, 'schema.moor')
# %%
from tools.schema_creator import create_schema
create_schema(model)
# %%
