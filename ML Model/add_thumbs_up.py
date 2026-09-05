import csv

input_file = 'extracted_landmarks.csv'
output_file = 'hand_gestures.csv'
labels_file = 'hand_gesture_labels.csv'

# Read thumbs up data
thumbs_up_data = []
with open(input_file, 'r', encoding='utf-8') as f:
    reader = csv.reader(f)
    for row in reader:
        if row[-1] == '05_thumb':
            # We need to prepend class index 4 and remove the label
            new_row = ['4'] + row[:-1]
            thumbs_up_data.append(new_row)

print(f"Extracted {len(thumbs_up_data)} thumbs up gestures.")

# Append to hand_gestures.csv
with open(output_file, 'a', encoding='utf-8', newline='') as f:
    writer = csv.writer(f)
    writer.writerows(thumbs_up_data)

print(f"Appended to {output_file}")

# Check if 'Thumbs Up' is already in labels
with open(labels_file, 'r', encoding='utf-8') as f:
    labels = [line.strip() for line in f if line.strip()]

if 'Thumbs Up' not in labels:
    with open(labels_file, 'a', encoding='utf-8') as f:
        f.write('Thumbs Up\n')
    print(f"Appended 'Thumbs Up' to {labels_file}")
else:
    print("'Thumbs Up' already in labels.")
