# %%
from google.cloud import storage
import os
import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.utils import class_weight
import numpy as np
from keras.utils import img_to_array
from PIL import Image
from io import BytesIO
from tqdm import tqdm
from pathlib import Path
import tensorflow as tf
tqdm.pandas()
# %%

# %%
species_dirs = Path('/data').glob('[0-9]*')
for specie_dir in species_dirs:
    specie_images = list(specie_dir.glob('*.jpg'))
    if len(specie_images) > 500:
        img_df = pd.DataFrame({'img' : specie_images})
        to_delete = img_df.sample(n=len(specie_images) - 500)
        print(f'specie_dir: {specie_dir.name}\n\tto_delete: {len(to_delete)} out of {len(specie_images)}')
        to_delete['img'].apply(lambda x: x.unlink())

# %%
images = Path('/data').rglob('*.jpg')
images = list(images)
# %%
images_df = pd.DataFrame({'file': images})
images_df['gbif_id'] = images_df['file'].apply(lambda x: int(x.parent.name))
# %%
classes_mapping = pd.read_csv('classes_mapping.csv')
images_df['class'] = None
for idx, row in classes_mapping.iterrows():
    class_id = row['gbif_id']
    images_df.loc[images_df['gbif_id'] == class_id, 'class'] = idx
# %%
images_df = images_df.sample(frac=1, ignore_index=True)
# %%
num_samples = 4096
num_tfrecords = len(images_df) // num_samples
#%%
def image_feature(value):
    """Returns a bytes_list from a string / byte."""
    return tf.train.Feature(
        bytes_list=tf.train.BytesList(value=[tf.io.encode_jpeg(value).numpy()])
    )

def int64_feature(value):
    """Returns an int64_list from a bool / enum / int / uint."""
    return tf.train.Feature(int64_list=tf.train.Int64List(value=[value]))

def create_example(image, example):
    feature = {
        "image": image_feature(image),
        "category_id": int64_feature(example["class"])}
    return tf.train.Example(features=tf.train.Features(feature=feature))


for tfrec_num in range(num_tfrecords):
# for tfrec_num in range(3):
    samples = images_df.loc[(tfrec_num * num_samples) : ((tfrec_num + 1) * num_samples)]

    with tf.io.TFRecordWriter(
        "tf_records/nin_species_%.2i-%i.tfrec" % (tfrec_num, len(samples))
    ) as writer:
        for _, sample in samples.iterrows():
            image_path = sample['file'].as_posix()
            image = tf.io.decode_jpeg(tf.io.read_file(image_path))
            example = create_example(image, sample)
            writer.write(example.SerializeToString())
            print(f'{tfrec_num}/{num_tfrecords}         ', end='\r')


# %%
images_df.to_csv('files.csv')

# %%
os.environ["GOOGLE_APPLICATION_CREDENTIALS"]="/srv/secret/natur-i-norge-training-bfcd40f1165d.json"
storage_client = storage.Client()
bucket = storage_client.get_bucket('nin_training_asia')
# %%
tf_records = Path('tf_records').glob('*.tfrec')
for tf_record in tf_records:
    blob = bucket.blob(tf_record.name)
    blob.upload_from_filename(tf_record)
    print(f'Uploaded: {tf_record}')
# train, test = train_test_split(files_df, test_size=0.2)