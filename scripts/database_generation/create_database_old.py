# %%
import os
from sqlalchemy.orm import sessionmaker
from sqlalchemy import create_engine
import pandas as pd
import model
from model import Base
import logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# logging.basicConfig(filename='./info.log', format='%(levelname)s:%(message)s', filemode='w+', level=logging.INFO)


database_file = 'db/v002.db'
try:
    os.remove(database_file)
except:
    pass

engine = create_engine(f'sqlite:///{database_file}')
Base.metadata.create_all(engine)


def populate_major_type_group(data):
    for row in data.itertuples():
        code = row.Co
        name = row._2
        description_en = row.Description
        print('Major-type group %s', name)
        majorTypeGroup = model.MajorTypeGroup(_id=code)
        majorTypeGroupInfo = model.MajorTypeGroupInfo(majorTypeGroup=majorTypeGroup,
                                                      language=english,
                                                      name=name,
                                                      description=description_en)
        session.add(majorTypeGroup)
        session.add(majorTypeGroupInfo)
        populate_major_type(majorType_data, majorTypeGroup)


def populate_major_type(data, majorTypeGroup):
    data = majorType_data[majorType_data.Co.substr(0, 1) == majorTypeGroup._id]
    for row in data.itertuples():
        print(row)


def populate_structuring_process():
    for row in structuring_process_data.itertuples():
        id = row.Co
        desc_en = row.Desc_en
        struct_process = model.StructuringProcess(_id=id)
        structuring_process_info = model.StructuringProcessInfo(
            description=desc_en, language=english, structuringProcess=struct_process)
        session.add(struct_process)
        session.add(structuring_process_info)


def populate_lec():
    for row in lec_data.itertuples():
        id = row.Co
        name_en = row.LEC
        desc_en = row.Description
        structuring_process = row.PC


# run populate
session = sessionmaker(bind=engine)()

# Create languages
english = model.Language(name='English')
session.add(english)
populate_structuring_process()
# %%
# session.commit()
session.query(model.StructuringProcess).first()
# populate_major_type_group(majorTypeGroup_data)
# session.rollback()
# session.commit()
# session.close()


##
# t4_data_file = 'data/GAD3v2.xlsm'
# types_file = 'data/types.xlsx'

##
