# %%
import logging
from PIL import Image
import requests
import pandas as pd
from tqdm import tqdm
import os
from io import BytesIO
from google.cloud import storage
import hashlib
import shutil
import logging
import time
import gc

# %%
class ImageDigestor():
    def __init__(self) -> None:
        os.environ["GOOGLE_APPLICATION_CREDENTIALS"]="/home/amarok/src/natur-i-norge/scripts/species/secret/natur-i-norge-training-bfcd40f1165d.json"
        # os.environ["GOOGLE_APPLICATION_CREDENTIALS"]="/Users/amarok/src/natur-i-norge/scripts/species/secret/natur-i-norge-training-bfcd40f1165d.json"
        self.storage_client = storage.Client()
        self.bucket = self.storage_client.get_bucket('nin_species')
        tqdm.pandas()
        self.species_urls = pd.read_csv(f'partial{os.sep}04_species_urls.csv')

    def _get_file_path(self, specie):
        hash_object = hashlib.sha224(specie['identifier'].encode('utf-8'))
        hex_dig = hash_object.hexdigest()
        return f'{specie.gbifKey}/{hex_dig}.jpg'

    def is_specie_in_bucket(self, file_path):
        blob = storage.Blob(name=file_path, bucket=self.bucket)
        return blob.exists();

    def get_image(self, specie):
        resp = requests.get(specie['identifier'])
        if resp.status_code != 200:
            logging.warning(f'Unable to download {specie.identifier}')
            return None;

        file_jpgdata = BytesIO(resp.content)

        return Image.open(file_jpgdata)

    def crop_img(self, img):
        width, height = img.size   # Get dimensions
        new_size = min([width, height])
        left = (width - new_size)/2
        top = (height - new_size)/2
        right = (width + new_size)/2
        bottom = (height + new_size)/2
        # Crop the center of the image
        return img.crop((left, top, right, bottom))

    def resize_img(self, img :Image):
        img.thumbnail(size=(224,224), resample=Image.ANTIALIAS)
        return img

    def create_tmp_dir(self, specie):
        name = specie.gbifKey
        tmp_dir = f'tmp{os.sep}{name}'
        if os.path.isdir(tmp_dir):
            return
        else:
            os.mkdir(tmp_dir)

    def run_on_specie(self, specie):
        self.create_tmp_dir(specie)
        file_path = self._get_file_path(specie)
        if self.is_specie_in_bucket(file_path):
            return True
        img = self.get_image(specie)
        if img == None:
            return False
        img_crop = self.crop_img(img)
        img_crop_resize = self.resize_img(img_crop)
        tmp_path = f'tmp{os.sep}{file_path}'
        img_crop_resize.save(tmp_path)
        self.upload(tmp_path, file_path)
        shutil.rmtree(f'tmp{os.sep}{specie.gbifKey}')
        time.sleep(0.1)
        if specie['Unnamed: 0'] % 100 == 0:
            gc.collect()
        return True

    def try_run_on_specie(self, specie):
        try:
            self.run_on_specie(specie)
        except:
            logging.warning(f'Unable to digest : {specie}')
            gc.collect()

    def upload(self, source, destination):
        blob = self.bucket.blob(destination)
        blob.upload_from_filename(source)

    def run_all(self):
        self.species_urls.progress_apply(self.try_run_on_specie, axis=1)
# %%
if __name__ == '__main__':
    image_digestor = ImageDigestor()
    image_digestor.run_all()
    exit()

# %%
