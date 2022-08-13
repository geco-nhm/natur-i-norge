#%%
import pandas as pd
# %%
mapping = pd.read_csv('classes_mapping.csv')
# %%
mapping
# %%
with open('labels.txt', 'w') as f:
    for _, row in mapping.iterrows():
        f.write(str(row['gbif_id']))
        f.write('\n')
# %%
