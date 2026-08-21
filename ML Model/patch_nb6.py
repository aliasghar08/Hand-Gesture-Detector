import json

notebook_path = r'c:\Hand Gesture Detector using Custom Model\ML Model\model_training_pipeline.ipynb'

with open(notebook_path, 'r', encoding='utf-8') as f:
    nb = json.load(f)

for cell in nb['cells']:
    if cell['cell_type'] == 'code' and len(cell['source']) > 0:
        source_text = ''.join(cell['source'])
        if 'cjmill/hagrid-classification-512p' in source_text:
            new_source = []
            for line in cell['source']:
                if 'cjmill/hagrid-classification-512p' in line:
                    new_source.append(line.replace('cjmill/hagrid-classification-512p', 'innominate817/hagrid-sample-30k-384p'))
                else:
                    new_source.append(line)
            cell['source'] = new_source

with open(notebook_path, 'w', encoding='utf-8') as f:
    json.dump(nb, f, indent=1)

print('Notebook updated back to unlocked dataset!')
