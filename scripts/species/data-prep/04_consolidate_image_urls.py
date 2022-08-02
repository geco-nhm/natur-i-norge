# %%
from glob import glob
import pandas as pd
import logging
import os
# %%
def run():
    dirs_in_data = glob(f'data{os.sep}*')
    list_of_multimedia_dfs = []
    dtypes = {'gbifID' : int,
            'type': str,
            'format': str,
            'identifier': str,
            'references': str,
            'title': str,
            'description': str,
            'source': str,
            'audience': str,
            'created': str,
            'creator': str,
            'contributor': str,
            'publisher': str,
            'license': str,
            'rightsHolder': str}
    for dir_in_data in dirs_in_data:
        try:
            multimedia = pd.read_csv(f'{dir_in_data}{os.sep}multimedia.txt', sep='\t', dtype=dtypes, usecols=['gbifID', 'identifier'])
        except Exception as e:
            print(f'unable to load {dir_in_data}')
            print(e)
            return
        gbif_key = int(dir_in_data.split(os.sep)[-1])
        multimedia['gbifKey'] = gbif_key
        multimedia = multimedia[['gbifKey', 'identifier', 'gbifID']]
        list_of_multimedia_dfs.append(multimedia)
    res = pd.concat(list_of_multimedia_dfs)
    res.to_csv(f'partial{os.sep}04_species_urls.csv')
# %%
def stats(df, treshold_num=10):
    input_num = df.groupby(['gbifKey']).agg(lambda x: len(x))
    input_num = input_num[['identifier']]
    input_num.columns = ['count']

    return {
        'Treshold' : treshold_num,
        'Number of species with observation' : len(input_num),
        'Number of species with more than treshold' : {sum(input_num['count']>treshold_num)},}


# %%
if __name__ == "__main__":
    run()
# %%
