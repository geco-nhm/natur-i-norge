# %%
from google.cloud import storage
import pandas as pd
# %%
species_df = pd.read_csv('output/species_with_gbif_id.csv')
os.environ["GOOGLE_APPLICATION_CREDENTIALS"]="/srv/species/secret/natur-i-norge-training-bfcd40f1165d.json"
# %%
taxon_ids = [int(x) for x in species_df['gbif_id']]
# %%
storage_client = storage.Client()
bucket = storage_client.get_bucket('nin_species')
# %%
to_delete = []
for file in bucket.list_blobs():
    taxon_id = int(file.name.split('/')[0])
    if taxon_id not in taxon_ids:
        to_delete.append(file)

# %%
taxon_ids_to_delete = []
for file in to_delete:
    taxon_id = int(file.name.split('/')[0])
    taxon_ids_to_delete.append(taxon_id)

taxon_ids_to_delete = list(set(taxon_ids_to_delete))
# %%
for file in to_delete:
    try:
        file.delete()
        print('.', end='')
    except:
        print('x', end='')
# %%
