import json

notebook_path = r'c:\Hand Gesture Detector using Custom Model\ML Model\model_training_pipeline.ipynb'

with open(notebook_path, 'r', encoding='utf-8') as f:
    nb = json.load(f)

for cell in nb['cells']:
    if cell['cell_type'] == 'code' and len(cell['source']) > 0:
        source_text = ''.join(cell['source'])
        if 'base_model.trainable = True' in source_text:
            new_source = [
                "# Extract the base model from our wrapped model\n",
                "base_model = None\n",
                "for layer in model.layers:\n",
                "    if hasattr(layer, 'layers'):\n",
                "        base_model = layer\n",
                "        break\n\n",
                "base_model.trainable = True\n",
                "fine_tune_at = 100\n",
                "for layer in base_model.layers[:fine_tune_at]:\n",
                "    layer.trainable = False\n",
                "\n",
                "model.compile(optimizer=tf.keras.optimizers.Adam(learning_rate=0.0001), loss='sparse_categorical_crossentropy', metrics=['accuracy'])\n",
                "history_fine = model.fit(train_dataset, validation_data=val_dataset, epochs=10, callbacks=callbacks)\n"
            ]
            cell['source'] = new_source

with open(notebook_path, 'w', encoding='utf-8') as f:
    json.dump(nb, f, indent=1)

print('Notebook successfully patched!')
