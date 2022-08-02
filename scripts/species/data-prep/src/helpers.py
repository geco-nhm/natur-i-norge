# %%
from pygbif import species
# %%
def get_gbif_id(name):
    res = species.name_backbone(name)
    if 'usageKey' in res.keys():
        return res['usageKey']

res = get_gbif_id('Abietinella abietina')
# %%
res
# %%
