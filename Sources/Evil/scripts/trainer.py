# -*- coding: utf-8 -*-
"""
    training image classifier
"""
import turicreate as tc
import sys
import getopt
import coremltools

opts, args = getopt.getopt(sys.argv[1:], "i:o:")

images = "./images"
model_name = "evil.mlmodel"

for op, value in opts:
    if op == "-i":
        images = value
    elif op == "-o":
        model_name = value
    else:
        print("非法参数")
        sys.exit()

# Load images
DATA = tc.image_analysis.load_images(images, with_path=True)

# From the path-name, create a label column
DATA['label'] = DATA['path'].apply(lambda path: path.split('/')[-2])

# Make a train-test split
train_data, test_data = DATA.random_split(0.8)

# Automatically picks the right model based on your data.
model = tc.image_classifier.create(
                                   train_data, target='label', model='squeezenet_v1.1', max_iterations=400)

# Save predictions to an SArray
predictions = model.predict(test_data)

# Evaluate the model and save the results into a dictionary
metrics = model.evaluate(test_data)
print(metrics['accuracy'])

# Export for use in Core ML
model.export_coreml(model_name)

core_ml_model = coremltools.models.MLModel(model_name)
core_ml_model.author = 'gix.evil'
core_ml_model.license = 'MIL LICENSE'
core_ml_model.save(model_name)

