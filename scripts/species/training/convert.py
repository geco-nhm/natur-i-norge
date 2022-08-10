# %%
import tensorflow as tf
# %%
model = tf.keras.models.load_model('trained_model_1.h5')
# %%
converter = tf.lite.TFLiteConverter.from_keras_model(new_model)
tfmodel = converter.convert()
with open ("model_1.tflite" , "wb") as f:
    f.write(tfmodel)
# %%
input = model.layers[0]
# %%
new_input = tf.keras.layers.Input(shape=(224, 224, 3), name="input_1", dtype='uint8')
new_outputs = model(new_input)
new_model = tf.keras.Model(new_input, new_outputs)

# %%
model.layers[0].shape
# %%
model.layers[0] = input_layer
# %%
