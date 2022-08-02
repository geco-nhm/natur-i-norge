# %%
from glob import glob
import pandas as pd
import os
import logging
import shutil
logging.basicConfig(level=logging.DEBUG)
# %%

if __name__ == '__main__':
    if not os.path.exists(f'partial{os.sep}02-with-all-gbif-ids.csv'):
        logging.error('02-with-all-gbif-ids.csv does not exist. Run 02 first.')
        exit(code=1)
    species_list = pd.read_csv(f'partial{os.sep}02-with-all-gbif-ids.csv')
    taxon_key_list = list(species_list['gbif_taxon_id'].apply(lambda x: int(x)))

    dirs_in_data = glob(f'data{os.sep}*')
    for dir_in_data in dirs_in_data:
        dir_name = dir_in_data.split(os.sep)[-1]
        try:
            dir_name_int = int(dir_name)
        except:
            continue
        if dir_name_int not in taxon_key_list:
            shutil.move(dir_in_data, f'data_useless{os.sep}{dir_name_int}')



# %%
