import json

notebook_path = r'c:\Hand Gesture Detector using Custom Model\ML Model\model_training_pipeline.ipynb'

with open(notebook_path, 'r', encoding='utf-8') as f:
    nb = json.load(f)

for cell in nb['cells']:
    if cell['cell_type'] == 'code' and len(cell['source']) > 0:
        source_text = ''.join(cell['source'])
        
        # 1. Fix NUM_CLASSES dynamically
        if 'NUM_CLASSES = 5' in source_text:
            new_source = []
            for line in cell['source']:
                if line.startswith('NUM_CLASSES = '):
                    new_source.append("NUM_CLASSES = len(train_dataset.class_names) # Dynamically inferred from dataset\n")
                    new_source.append("print(f'Detected {NUM_CLASSES} classes: {train_dataset.class_names}')\n")
                else:
                    new_source.append(line)
            cell['source'] = new_source
            
        # 2. Uncomment export function
        if '# export_to_tflite(model)' in source_text:
            new_source = []
            for line in cell['source']:
                if line.startswith('# export_to_tflite'):
                    new_source.append(line.replace('# ', '', 1))
                else:
                    new_source.append(line)
            cell['source'] = new_source

with open(notebook_path, 'w', encoding='utf-8') as f:
    json.dump(nb, f, indent=1)

print('Notebook finally patched!')
