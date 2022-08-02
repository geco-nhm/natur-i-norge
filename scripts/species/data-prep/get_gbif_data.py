# %%
from tqdm import tqdm
import pandas as pd
from src.gbif_data import initiate_gbif_download

# %%
species_df = pd.read_csv('output/species_with_gbif_id.csv')
# %%
tqdm.pandas()
species_df['gbif_id'].progress_apply(initiate_gbif_download)
# %%
