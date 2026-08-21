import json

notebook_path = r'c:\Hand Gesture Detector using Custom Model\ML Model\model_training_pipeline.ipynb'

with open(notebook_path, 'r') as f:
    nb = json.load(f)

for cell in nb['cells']:
    if cell['cell_type'] == 'code' and len(cell['source']) > 0:
        if '!pip install' in cell['source'][0] or '%pip install' in cell['source'][0]:
            cell['source'][0] = "%pip install kaggle tensorflow matplotlib\n"

with open(notebook_path, 'w') as f:
    json.dump(nb, f, indent=1)

print("Notebook updated to use %pip install magic command.")
