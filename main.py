import cv2
import csv
import time
import pickle

import keyboard
import numpy as np
import sqlite3

from datetime import datetime
from deepface import DeepFace
from scipy.spatial.distance import cosine

# ==========================================
# CONFIG
# ==========================================

PROCESS_EVERY = 10
LOG_INTERVAL = 1.0  # seconds
RECOGNITION_THRESHOLD = 0.2
lecture_id = "1235_3"  # Default lecture
CSV_FILE = "log.csv"
ATTENDANCE_FILE = "attendance.csv"


# ==========================================
# INITIALIZE ATTENDANCE CSV
# ==========================================

def init_attendance_file():
    """Create attendance.csv with header if it doesn't exist"""
    try:
        with open(ATTENDANCE_FILE, 'r') as f:
            pass  # File exists, do nothing
    except FileNotFoundError:
        with open(ATTENDANCE_FILE, 'w', newline='') as f:
            writer = csv.writer(f)
            writer.writerow(['student_id', 'timestamp', 'lecture_id'])
        print(f"[INIT] Created {ATTENDANCE_FILE}")


init_attendance_file()

# ==========================================
# LOAD EXISTING ATTENDANCE
# ==========================================

attendance_marked = set()


def load_existing_attendance():
    """Load students already marked present for current lecture"""
    global attendance_marked
    attendance_marked.clear()

    try:
        with open(ATTENDANCE_FILE, 'r') as f:
            reader = csv.DictReader(f)
            for row in reader:
                if row['lecture_id'] == lecture_id:
                    attendance_marked.add(row['student_id'])
        print(f"[LOAD] Found {len(attendance_marked)} students already marked for lecture {lecture_id}")
    except FileNotFoundError:
        pass


load_existing_attendance()


# ==========================================
# ATTENDANCE FUNCTION
# ==========================================

def mark_attendance(student_id):
    """Mark a student as present if not already marked"""
    global attendance_marked

    if student_id == "Unknown" or student_id in attendance_marked:
        return False

    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    # Mark in memory
    attendance_marked.add(student_id)

    # Write to CSV
    with open(ATTENDANCE_FILE, 'a', newline='') as f:
        writer = csv.writer(f)
        writer.writerow([student_id, timestamp, lecture_id])

    print(f"[ATTENDANCE] ✅ {student_id} marked present for lecture {lecture_id} (Total: {len(attendance_marked)})")
    return True


# ==========================================
# LOAD STUDENT EMBEDDINGS
# ==========================================

with open("embeddings.pkl", "rb") as f:
    database = pickle.load(f)


# ==========================================
# RECOGNITION FUNCTION
# ==========================================

def recognize_face(face_embedding, threshold=0.2):
    best_match = None
    best_distance = 999

    for student_id, embeddings in database.items():
        for db_embedding in embeddings:
            distance = cosine(face_embedding, db_embedding)
            if distance < best_distance:
                best_distance = distance
                best_match = student_id

    if best_distance < threshold:
        return best_match, best_distance
    return "Unknown", best_distance


# ==========================================
# CHANGE LECTURE
# ==========================================

def change_lecture(new_id):
    global lecture_id
    lecture_id = new_id
    print(f"\n{'=' * 50}")
    print(f"[LECTURE] Changed to: {lecture_id}")
    load_existing_attendance()
    print(f"[LECTURE] Attendance tracking active")
    print(f"{'=' * 50}\n")


# ==========================================
# WEBCAM
# ==========================================

cap = cv2.VideoCapture(0)
frame_count = 0

# Stores: { student_id: (emotion, confidence) }
best_results = {}
last_log_time = time.time()

print(f"\n{'=' * 50}")
print(f"[START] System Started")
print(f"[START] Current Lecture: {lecture_id}")
print(f"[START] Students in database: {len(database)}")
print(f"[START] Controls: 'Q' = Quit | 'ctrl' = Change Lecture")
print(f"{'=' * 50}\n")

while True:
    ret, frame = cap.read()
    if not ret:
        break

    frame_count += 1

    # Process every N frames
    if frame_count % PROCESS_EVERY == 0:
        small_frame = cv2.resize(frame, (640, 480))

        try:
            analyses = DeepFace.analyze(
                small_frame,
                actions=['emotion'],
                detector_backend='opencv',
                enforce_detection=False
            )

            if not isinstance(analyses, list):
                analyses = [analyses]

            for analysis in analyses:
                # Face region
                region = analysis['region']
                x, y, w, h = region['x'], region['y'], region['w'], region['h']

                # Emotion
                emotion = analysis['dominant_emotion']
                emotion_scores = analysis['emotion']
                confidence = emotion_scores[emotion]

                # Face crop
                face_img = small_frame[y:y + h, x:x + w]
                if face_img.size == 0:
                    continue

                # Face embedding
                representation = DeepFace.represent(
                    face_img,
                    model_name="Facenet512",
                    enforce_detection=False
                )
                embedding = representation[0]["embedding"]

                student_id, distance = recognize_face(
                    embedding, RECOGNITION_THRESHOLD
                )

                # Mark attendance
                if student_id != "Unknown":
                    mark_attendance(student_id)

                # Store best result per student for this second
                if student_id not in best_results:
                    best_results[student_id] = (emotion, confidence)
                else:
                    old_emotion, old_confidence = best_results[student_id]
                    if confidence > old_confidence:
                        best_results[student_id] = (emotion, confidence)

                # Draw UI
                attended = "Y" if student_id in attendance_marked else "N"
                text = f"{student_id} {attended} | {emotion} ({confidence:.1f}%)"

                cv2.rectangle(small_frame, (x, y), (x + w, y + h), (0, 255, 0), 2)
                cv2.putText(small_frame, text, (x, y - 10),
                            cv2.FONT_HERSHEY_SIMPLEX, 0.6, (0, 255, 0), 2)

        except Exception as e:
            print("Analysis error:", e)

        # Show processed frame
        cv2.imwrite("www/latest_frame.jpg", small_frame)

    # Log every second
    current_time = time.time()
    if current_time - last_log_time >= LOG_INTERVAL:
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

        with open(CSV_FILE, "a", newline="") as f:
            writer = csv.writer(f)
            for student_id, data in best_results.items():
                emotion, confidence = data
                if student_id == "Unknown":
                    continue
                writer.writerow([
                    student_id, timestamp, emotion,
                    round(confidence, 2), lecture_id
                ])

        best_results = {}
        last_log_time = current_time

    # Check for lecture change
    if keyboard.is_pressed('ctrl'):
        print("\n[INPUT] Enter new lecture ID:")
        new_id = input("> ").strip()
        if new_id:
            change_lecture(new_id)
        time.sleep(0.5)  # Prevent multiple triggers

    # Exit
    if keyboard.is_pressed('q'):
        print(f"\n{'=' * 50}")
        print(f"[STOP] System Stopped")
        print(f"[STOP] Lecture: {lecture_id}")
        print(f"[STOP] Students marked present: {len(attendance_marked)}")
        print(f"[STOP] Students: {sorted(attendance_marked)}")
        print(f"{'=' * 50}\n")
        break

# Cleanup
cap.release()
cv2.destroyAllWindows()