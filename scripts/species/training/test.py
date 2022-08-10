# %%
import tensorflow as tf
import numpy as np
# %%
# model = tf.keras.models.load_model('trained_model_1.h5')
interpreter = tf.lite.Interpreter(model_path='model_1.tflite')
# interpreter = tf.lite.Interpreter(model_path='mobilenet_v1_1.0_224_quant.tflite')
interpreter.allocate_tensors()
# %%
img_path = '/data/2529264/076ab3514cea9e9f316e57f041c5059dedeb5ffe80c310cec3c48117.jpg'
img = tf.io.decode_jpeg(tf.io.read_file(img_path))
img = np.expand_dims(img, axis=0)
# %%
# %%
# Get input and output tensors.
input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()

# Test model on random input data.
input_shape = input_details[0]['shape']
input_data = img
interpreter.set_tensor(input_details[0]['index'], input_data)

interpreter.invoke()

# The function `get_tensor()` returns a copy of the tensor data.
# Use `tensor()` in order to get a pointer to the tensor.
output_data = interpreter.get_tensor(output_details[0]['index'])
print(output_data)
# %%
