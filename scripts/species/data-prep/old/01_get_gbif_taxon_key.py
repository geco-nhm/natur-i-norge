# %%
import pygbif
from qwikidata.sparql import (get_subclasses_of_item,
                              return_sparql_query_results)
import pandas as pd
from tqdm import tqdm
import os
import logging
import time
import numpy as np

# %%



def get_gbif_taxon_key(nbic_taxon_id):
    """ Get GBIF taxonKey for scientificNameID given. This ID is requested from
    wikidata NBIC taxon ID (https://www.wikidata.org/wiki/Property:P8707).
    Returns None when no match or multiple matches were found.

    Parameters:
    -----------
    nbic_taxon_id : int
        Taxon Id (eg. 104789)

    Returns:
    --------
    int, None
        TaxonKey for equivalent GBIF specie.

    """
    # logging.info(nbic_taxon_id)
    sparql_query = f"""
    SELECT ?item ?label
        WHERE {{ ?item wdt:P8707 '{nbic_taxon_id}'.
        ?item wdt:P846 ?label.
        SERVICE wikibase:label {{ bd:serviceParam wikibase:language '[AUTO_LANGUAGE],en'. }}
    }}
    """
    resp = None
    while resp == None:
        try:
            resp = return_sparql_query_results(sparql_query)
        except:
            pass
    time.sleep(0.2)
    # logging.info(resp)
    # return resp
    res = resp['results']['bindings']
    if len(res) == 1:
        return res[0]['label']['value']
    if len(res) == 0:
        logging.warning(f'No matches for nbic_taxon_id: {nbic_taxon_id}')
        return None
    else:
        logging.error(f'Multiple matches for nbic_taxon_id: {nbic_taxon_id}')
    return None

  # %%
def search_gbif_taxon_key(name, gbif_taxon_key=None):
    """ Searches GBIF taxonKey for scientificNameID given. This is name based
    search and returns the most likely accepted candidate.

    Parameters:
    -----------
    name : str
        Taxon name (eg. `Abietinella abietina`)
    gbif_taxon_key : int, optional
        TaxonKey that might have been already found (Usefull for reruns do avoid
        duplicate queries)

    Returns:
    --------
    int
        TaxonKey for equivalent GBIF specie.

    """
    if gbif_taxon_key != None:
        return gbif_taxon_key
    logging.debug(f'Getting {name}')
    resp = pygbif.name_backbone(name=name)
    if 'usageKey' not in resp.keys():
        logging.error(f'Name not found: {name}')
        return None

    return resp['usageKey'];_
#%% Main
if __name__ == '__main__':
    logging.basicConfig(level=logging.DEBUG)
    tqdm.pandas()
    # Load dataset from `raw` folder
    species_list = pd.read_excel('raw/arter_AR8.xlsx', sheet_name='Artsliste')
    # Get matching GBIF TaxonKey if partial/01-with-most-gbif-ids.csv is not
    # present
    if not os.path.exists('partial/01-with-most-gbif-ids.csv'):
        species_list['gbif_taxon_id'] = species_list.scientificNameID.\
            progress_apply(get_gbif_taxon_key)
        species_list.to_csv('partial/01-with-most-gbif-ids.csv')
    else:
        logging.warning('Skipping WikiData query because 01 file is already\
            in the partial directory')
        species_list = pd.read_csv('partial/01-with-most-gbif-ids.csv')
        species_list = species_list.replace({np.NAN: None})
    # Search most likely for GBIF TaxonKey
    species_list['gbif_taxon_id'] = species_list.progress_apply(lambda x: search_gbif_taxon_key(x['scientificName'], x['gbif_taxon_id']), axis=1)
    species_list.to_csv('partial/02-with-all-gbif-ids.csv')
    logging.info('Finished.')


# %%
