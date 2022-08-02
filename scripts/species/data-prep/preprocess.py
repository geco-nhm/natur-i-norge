# %%
import pandas as pd
from src.helpers import get_gbif_id
import numpy as np

# %%
# %%
raw_data = pd.read_excel('raw/Arter_AR8v23_20220404.xlsx', header=0, sheet_name='Artsliste')
# %%
raw_data['gbif_id'] = raw_data['scientificName'].apply(get_gbif_id)
# %%
raw_data.to_csv('output/species_with_gbif_id.csv')
# %%
raw_data[np.isnan(raw_data['gbif_id'])]
# %%
