# %%
import tensorflow as tf
# %%
model = tf.keras.models.load_model('trained_model_2.h5')
# %%
converter = tf.lite.TFLiteConverter.from_keras_model(model)
tfmodel = converter.convert()
with open ("model_2.tflite" , "wb") as f:
    f.write(tfmodel)
# %%
