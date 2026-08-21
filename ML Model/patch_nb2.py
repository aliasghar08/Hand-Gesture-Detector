import json

notebook_path = r'c:\Hand Gesture Detector using Custom Model\ML Model\model_training_pipeline.ipynb'

with open(notebook_path, 'r', encoding='utf-8') as f:
    nb = json.load(f)

for cell in nb['cells']:
    if cell['cell_type'] == 'code' and len(cell['source']) > 0:
        source_text = ''.join(cell['source'])
        if '# train_dataset = create_dataset' in source_text:
            new_source = []
            for line in cell['source']:
                if line.startswith('# train_dataset = '):
                    new_source.append(line.replace('# ', '', 1))
                elif line.startswith('# val_dataset = '):
                    new_source.append(line.replace('# ', '', 1))
                else:
                    new_source.append(line)
            cell['source'] = new_source

with open(notebook_path, 'w', encoding='utf-8') as f:
    json.dump(nb, f, indent=1)

print('Notebook successfully patched!')
