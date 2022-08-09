# %%
from google.cloud import storage
import os
import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.utils import class_weight
import numpy as np
from pathlib import Path
import tensorflow as tf
from tensorflow.keras.layers import GlobalAveragePooling2D, Dense
from tensorflow.keras import Model
# %%
files = pd.read_csv('files.csv')
classes = np.unique(files['class'])
classes_num = len(classes)
TPU_ADDRESS = '10.14.21.82'

# %%
classes_mapping = pd.DataFrame({'gbif_id' : classes})
classes_mapping.to_csv('classes_mapping')
# %%
tf_files = list(Path('tf_records').glob('*.tfrec'))
# %%
batch_size = 1024
# %%
mobile = tf.keras.applications.MobileNetV3Large(
    input_shape=None,
    alpha=1.0,
    minimalistic=True,
    include_top=False,
    weights='imagenet',
    input_tensor=None,
    pooling=None,
    dropout_rate=0.2,
    include_preprocessing=True
)

x=mobile.output
x=GlobalAveragePooling2D()(x)
x=Dense(1024,activation='relu')(x) #we add dense layers so that the model can learn more complex functions and classify for better results.
x=Dense(1024,activation='relu')(x) #dense layer 2
x=Dense(512,activation='relu')(x) #dense layer 3
preds=Dense(classes_num,activation='softmax')(x) #final layer with
model=Model(inputs=mobile.input,outputs=preds)
# %% Freeze all but last few layers
for layer in model.layers:
    layer.trainable=False
for layer in model.layers[-5:]:
    layer.trainable=True
for idx, layer in enumerate(model.layers):
    print(f'{idx}:{layer.trainable} - {layer.name}')

# %%
AUTOTUNE = tf.data.AUTOTUNE
def parse_tfrecord_fn(example):
    feature_description = {
        "image": tf.io.FixedLenFeature([], tf.string),
        "category_id": tf.io.FixedLenFeature([], tf.int64),
    }
    example = tf.io.parse_single_example(example, feature_description)
    example["image"] = tf.io.decode_jpeg(example["image"], channels=3)
    return example
def prepare_sample(features):
    image = tf.image.resize(features["image"], size=(224, 224))
    # category_id = classes_mapping.index[classes_mapping['gbif_id'] == features["category_id"]][0]
    return image, features['category_id']

def get_dataset(filenames, batch_size):
    dataset = (
        tf.data.TFRecordDataset(filenames, num_parallel_reads=AUTOTUNE)
        .map(parse_tfrecord_fn, num_parallel_calls=AUTOTUNE)
        .map(prepare_sample, num_parallel_calls=AUTOTUNE)
        .shuffle(batch_size * 10)
        .batch(batch_size)
        .cache()
        .prefetch(AUTOTUNE)
    )
    return dataset
# %%
y_train = files['class']
class_weights = class_weight.compute_class_weight(class_weight = 'balanced',
                                                 classes = np.unique(y_train),
                                                 y = y_train)
class_weights = dict(enumerate(class_weights))

# %% Train
dataset=get_dataset(tf_files,batch_size)
model.compile(optimizer=tf.optimizers.Adam(), 
              loss='sparse_categorical_crossentropy')

# %%
tpu_model = tf.contrib.tpu.keras_to_tpu_model(
    model,
    strategy=tf.contrib.tpu.TPUDistributionStrategy(
        tf.contrib.cluster_resolver.TPUClusterResolver(TPU_ADDRESS)))
# %%
tpu_model.fit(dataset, 
          steps_per_epoch=10, # needed for repeated datasets
          epochs=40,
          class_weight=class_weights)
# %% Save model
tpu_model.save('model.h5')
tpu_model = tf.keras.models.load_model('model.h5')
converter = tf.lite.TFLiteConverter.from_keras_model(model)
tfmodel = converter.convert()
with open ("model.tflite" , "wb") as f:
    f.write(tfmodel)
# %%
