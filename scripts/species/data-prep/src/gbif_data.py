# %%
import pygbif
import pandas as pd
from tqdm import tqdm
import os
import time
from glob import glob


# %%
def initiate_gbif_download(taxon_id):
    try:
        taxon_id = int(taxon_id)
    except:
        print(f'Unable to get taxon_id: {taxon_id}')
        return
    download_path = f'data/{taxon_id}'
    try:
        os.mkdir(download_path)
    except:
        pass
    zips_in_download = glob(f'data/{taxon_id}/*.zip')
    if (len(zips_in_download) > 0):
        return
    res = pygbif.occurrences.download([f"taxonKey = {taxon_id}","mediatype = StillImage","basisOfRecord = HUMAN_OBSERVATION"],\
        user='michaltorma',\
        email='miso.torma@gmail.com',\
        pwd='etAQnyTDVUGis67dUUKKQK7PJ5oHUkYYsYF57d2',\
        )
    job_id = res[0]
    download = None

    while download == None:
        try:
            download = pygbif.occurrences.download_get(job_id, path=download_path)
        except:
            time.sleep(5)

if __name__ == '__main__':
    tqdm.pandas()
    species_list = pd.read_csv('partial/02-with-all-gbif-ids.csv')
    species_list['gbif_taxon_id'].progress_apply(initiate_gbif_download)
# %%
