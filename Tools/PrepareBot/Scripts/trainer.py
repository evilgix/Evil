# -*- coding: utf-8 -*-
"""
    training image classifier
    """

import sys
import getopt
import keras
import coremltools

from keras.models import Sequential
from keras.layers import Conv2D, MaxPooling2D, Dense, Dropout, Flatten
from keras.preprocessing.image import ImageDataGenerator
from keras import backend as k

k.set_image_dim_ordering('tf')

num_rows = 28
num_cols = 28
num_channels = 1
num_classes = 11

opts, args = getopt.getopt(sys.argv[1:], "i:o:l:")

images = "./output"
model_name = "ChineseIDCard.mlmodel"
labels = "0123456789X"

for op, value in opts:
    if op == "-i":
        images = value
    elif op == "-o":
        model_name = value
    elif op == "-l":
        labels = value
    else:
        print("非法参数")
        sys.exit()

train_data_generator = ImageDataGenerator(rescale=1. / 255).flow_from_directory(
            directory=images + '/train',
            target_size=(28, 28),
            color_mode='grayscale',
            batch_size=200)
test_data_generator = ImageDataGenerator(rescale=1. / 255).flow_from_directory(
            directory=images + '/test',
            target_size=(28, 28),
            color_mode='grayscale',
            batch_size=200)

model = Sequential()

model.add(Conv2D(32, (5, 5), input_shape=(28, 28, 1), activation='relu'))
model.add(MaxPooling2D(pool_size=(2, 2)))
model.add(Dropout(0.5))
model.add(Conv2D(64, (3, 3), activation='relu'))
model.add(MaxPooling2D(pool_size=(2, 2)))
model.add(Dropout(0.2))
model.add(Conv2D(128, (1, 1), activation='relu'))
model.add(MaxPooling2D(pool_size=(2, 2)))
model.add(Dropout(0.2))
model.add(Flatten())
model.add(Dense(128, activation='relu'))
model.add(Dense(num_classes, activation='softmax'))

model.compile(loss='categorical_crossentropy', optimizer='adam', metrics=['accuracy'])

# Training
model.fit_generator(generator=train_data_generator, steps_per_epoch=840, epochs=5, workers=4)
score = model.evaluate_generator(generator=test_data_generator, steps=100, workers=4)

print('Test score:', score[0])
print('Test accuracy:', score[1])
# Prepare model for inference
for k in model.layers:
    if type(k) is keras.layers.Dropout:
        model.layers.remove(k)
        model.save("./temp.model")

core_ml_model = coremltools.converters.keras.convert("./temp.model",
                                                     input_names='image',
                                                     image_input_names='image',
                                                     output_names='output',
                                                     class_labels=list(labels),
                                                     image_scale=1 / 255.)

core_ml_model.author = 'gix.evil'
core_ml_model.license = 'MIT license'
core_ml_model.short_description = 'model to classify chinese IDCard numbers'

core_ml_model.input_description['image'] = 'Grayscale image of card number'
core_ml_model.output_description['output'] = 'Predicted digit'

core_ml_model.save(model_name)

print('done')

