# %%
from glob import glob
import os
import shutil
from zipfile import ZipFile
import logging
# %%


# %%
dirs_in_data = glob('data/*')
# %%
def clear_dir(dir):
    all_files_in_dir = set(glob(f'{dir}{os.sep}*'))
    zip_files_in_dir = set(glob(f'{dir}{os.sep}*.zip'))

    files_to_remove = list(all_files_in_dir.difference(zip_files_in_dir))
    # print(files_to_remove)
    for file_to_remove in files_to_remove:
        if os.path.isdir(file_to_remove):
            shutil.rmtree(file_to_remove)
        else:
            os.remove(file_to_remove)

def unzip(dir):
    files_in_dir = glob(f'{dir}/*.zip')
    if len(files_in_dir) == 0:
        logging.warn(f'No zipfile in {dir}')
        return
    if len(files_in_dir) > 1:
        logging.warn(f'Multiple zip files in {dir}')
        return
    try:
        with ZipFile(files_in_dir[0], 'r') as zip_object:
            zip_object.extract('multimedia.txt', f'{dir}')
    except:
        print(f'\nunable to unzip dir: {dir}')
# unzip(dirs_in_data[1])
# %%
def run():
    logging.basicConfig(level=logging.DEBUG)
    for data_dir in dirs_in_data:
        clear_dir(data_dir)
        unzip(data_dir)
        print('.', end='')

if __name__ == '__main__':
    run()
# %%
