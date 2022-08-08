# %%
from google.cloud import storage
import os
import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.utils import class_weight
import numpy as np

# %%
os.environ["GOOGLE_APPLICATION_CREDENTIALS"]="/srv/secret/natur-i-norge-training-bfcd40f1165d.json"
storage_client = storage.Client()
bucket = storage_client.get_bucket('nin_species')
# %%
files = []
for file in bucket.list_blobs():
    try:
        files.append(file.name)
    except Exception as e:
        print(e)
# %%
files_df = pd.DataFrame({'path' : files})

# %%
files_df['gbif_id'] = files_df['path'].apply(lambda x: int(x.split('/')[0]))
# %%
files_df.to_csv('files.csv')
# %%
species_urls = pd.read_csv('04_species_urls.csv')
# %%
