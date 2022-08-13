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
# api = ArtsdatabankenNinApi('https://nin-kode-api.artsdatabanken.no')
# %%
database_file = '/data/assets/nin_database.db'
engine = create_engine(f'sqlite:///{database_file}')
Session = sessionmaker(bind=engine)
session = Session()

# %%
to_delete = session.query(model.GadValue).where(
    model.GadValue.valueM7Scale_id == 0
).all()
for item in to_delete:
    session.delete(item)
session.commit()
# %%
for esc in session.query(model.ElementarySegmentCombination).all():
    esg_id = esc.elementarySegmentGroup_id
    lec_id = esg_id.split('.')[0]
    suffixes = esg_id.split('.')[1]
    for letter in suffixes:
        elementarySegmentGroup_id = f'{lec_id}-{letter}'
        session.add(model.ElementarySegmentCombination(
            _id=esc._id,
            elementarySegmentGroup_id=elementarySegmentGroup_id,
            majorTypeLEC_id=lec_id
        ))
    session.delete(esc)
session.commit()
    

# %%

