import os
import pickle
from deepface import DeepFace

DATASET_PATH = "DB"

database = {}

for student_id in os.listdir(DATASET_PATH):

    student_folder = os.path.join(DATASET_PATH, student_id)

    if not os.path.isdir(student_folder):
        continue

    embeddings = []

    for img_name in os.listdir(student_folder):

        img_path = os.path.join(student_folder, img_name)

        try:
            representation = DeepFace.represent(
                img_path=img_path,
                model_name="Facenet512",
                enforce_detection=False
            )

            embedding = representation[0]["embedding"]
            embeddings.append(embedding)

            print(f"Processed {img_path}")

        except Exception as e:
            print(f"Error with {img_path}: {e}")

    if embeddings:
        database[student_id] = embeddings

with open("embeddings.pkl", "wb") as f:
    pickle.dump(database, f)

print("Embeddings saved.")