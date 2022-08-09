# %%
import tensorflow as tf
import numpy as np
# %%
model = tf.keras.models.load_model('trained_model_1.h5')
# %%
img_path = '/data/2529264/076ab3514cea9e9f316e57f041c5059dedeb5ffe80c310cec3c48117.jpg'
img = tf.io.decode_jpeg(tf.io.read_file(img_path))
img = np.expand_dims(img, axis=0)
# %%
model.predict([img])
# %%
img.shape
# %%
