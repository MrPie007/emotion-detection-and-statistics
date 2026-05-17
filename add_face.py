# add_student.py
import os
import cv2
import pickle
import sqlite3
import numpy as np
from deepface import DeepFace
from datetime import datetime

# ==========================================
# CONFIG
# ==========================================
DATASET_PATH = "DB"
EMBEDDINGS_FILE = "embeddings.pkl"
DB_FILE = "attendance.db"
CAMERA_INDEX = 0
NUM_PHOTOS = 5  # Number of photos to take (can be increased for better accuracy)


# ==========================================
# DATABASE SETUP
# ==========================================
def init_database():
    """Initialize database tables if they don't exist"""
    conn = sqlite3.connect(DB_FILE)
    cursor = conn.cursor()
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS attendance (
            ID INT,
            lecture VARCHAR(50),
            PRIMARY KEY(ID, lecture)
        )
    """)
    conn.commit()
    conn.close()


def student_exists_in_db(student_id):
    """Check if student ID already exists in database"""
    conn = sqlite3.connect(DB_FILE)
    cursor = conn.cursor()
    cursor.execute("SELECT COUNT(*) FROM attendance WHERE ID = ?", (student_id,))
    count = cursor.fetchone()[0]
    conn.close()
    return count > 0


# ==========================================
# EMBEDDINGS MANAGEMENT
# ==========================================
def load_embeddings():
    """Load existing embeddings or create new dictionary"""
    if os.path.exists(EMBEDDINGS_FILE):
        with open(EMBEDDINGS_FILE, "rb") as f:
            return pickle.load(f)
    return {}


def save_embeddings(database):
    """Save embeddings to file"""
    with open(EMBEDDINGS_FILE, "wb") as f:
        pickle.dump(database, f)
    print(f"✓ Embeddings saved to {EMBEDDINGS_FILE}")


def student_exists_in_embeddings(student_id, database):
    """Check if student already has embeddings"""
    return str(student_id) in database


# ==========================================
# CAMERA FUNCTIONS
# ==========================================
def init_camera():
    """Initialize camera"""
    cap = cv2.VideoCapture(CAMERA_INDEX)
    if not cap.isOpened():
        print("✗ Error: Could not open camera")
        return None

    # Test if we can read frames
    ret, frame = cap.read()
    if not ret:
        print("✗ Error: Could not read from camera")
        cap.release()
        return None

    print("✓ Camera initialized")
    return cap


def capture_photos(student_id, num_photos=NUM_PHOTOS):
    """Capture multiple photos of a student"""
    cap = init_camera()
    if cap is None:
        return []

    photos = []
    photo_count = 0

    print(f"\n📸 Preparing to capture {num_photos} photos for Student ID: {student_id}")
    print("Instructions:")
    print("  - Look directly at the camera")
    print("  - Ensure good lighting on your face")
    print("  - Try different angles (slight left, right, up, down)")
    print("  - Press SPACE to capture a photo")
    print("  - Press ESC to cancel")
    print("-" * 50)

    while photo_count < num_photos:
        ret, frame = cap.read()
        if not ret:
            print("✗ Error reading frame")
            break

        # Add countdown and instructions overlay
        display_frame = frame.copy()
        cv2.putText(display_frame, f"Student: {student_id}", (10, 30),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.8, (0, 255, 0), 2)
        cv2.putText(display_frame, f"Photos: {photo_count}/{num_photos}", (10, 70),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.8, (0, 255, 0), 2)
        cv2.putText(display_frame, "SPACE: Capture | ESC: Cancel", (10, 110),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.6, (255, 255, 255), 1)

        # Show frame
        cv2.imshow("Add New Student", display_frame)

        key = cv2.waitKey(1) & 0xFF

        if key == 32:  # SPACE key
            photos.append(frame.copy())
            photo_count += 1
            print(f"✓ Photo {photo_count}/{num_photos} captured")

            # Flash effect
            cv2.putText(display_frame, "CAPTURED!", (200, 240),
                        cv2.FONT_HERSHEY_SIMPLEX, 2, (0, 255, 0), 3)
            cv2.imshow("Add New Student", display_frame)
            cv2.waitKey(200)  # Brief pause to show the flash

        elif key == 27:  # ESC key
            print("\n⚠ Capture cancelled by user")
            break

    cap.release()
    cv2.destroyAllWindows()

    return photos


# ==========================================
# FACE DETECTION AND EMBEDDING
# ==========================================
def detect_and_crop_face(image):
    """Detect and crop face from image"""
    try:
        # Use DeepFace to detect face
        face_objs = DeepFace.extract_faces(
            img_path=image,
            detector_backend='opencv',
            enforce_detection=True
        )

        if face_objs and len(face_objs) > 0:
            # Get the first face
            face = face_objs[0]
            facial_area = face['facial_area']

            # Crop the face
            x = facial_area['x']
            y = facial_area['y']
            w = facial_area['w']
            h = facial_area['h']

            face_crop = image[y:y + h, x:x + w]
            return face_crop, True

    except Exception as e:
        print(f"  ⚠ Face detection warning: {e}")

    return image, False


def generate_embeddings(photos):
    """Generate face embeddings from photos"""
    embeddings = []

    print("\n🔍 Generating embeddings...")

    for i, photo in enumerate(photos):
        print(f"  Processing photo {i + 1}/{len(photos)}...", end=" ")

        # Try to detect and crop face
        face_img, face_detected = detect_and_crop_face(photo)

        if not face_detected:
            print("⚠ No face detected, using full image")

        try:
            # Generate embedding
            representation = DeepFace.represent(
                img_path=face_img,
                model_name="Facenet512",
                enforce_detection=False
            )

            embedding = representation[0]["embedding"]
            embeddings.append(embedding)
            print("✓")

        except Exception as e:
            print(f"✗ Error: {e}")

    return embeddings


# ==========================================
# MAIN FUNCTION
# ==========================================
def add_student():
    """Main function to add a new student"""
    print("=" * 50)
    print("    STUDENT REGISTRATION SYSTEM")
    print("=" * 50)

    # Initialize database
    init_database()

    # Load existing embeddings
    database = load_embeddings()

    # Get student ID
    while True:
        try:
            student_id = input("\nEnter Student ID (numbers only): ").strip()
            student_id_int = int(student_id)  # Validate it's a number

            # Check if already exists
            if student_exists_in_embeddings(student_id, database):
                print(f"⚠ Student ID {student_id} already exists in embeddings!")
                overwrite = input("Do you want to overwrite? (y/n): ").lower()
                if overwrite != 'y':
                    print("Registration cancelled.")
                    return

            break

        except ValueError:
            print("✗ Please enter a valid number")

    # Create student folder
    student_folder = os.path.join(DATASET_PATH, str(student_id))

    # Capture photos
    photos = capture_photos(student_id, NUM_PHOTOS)

    if len(photos) == 0:
        print("✗ No photos captured. Registration cancelled.")
        return

    # Generate embeddings
    embeddings = generate_embeddings(photos)

    if len(embeddings) == 0:
        print("✗ Could not generate embeddings. Registration failed.")
        return

    # Save photos to disk
    print(f"\n💾 Saving photos...")
    os.makedirs(student_folder, exist_ok=True)

    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    for i, photo in enumerate(photos):
        filename = f"{student_id}_{timestamp}_{i + 1}.jpg"
        filepath = os.path.join(student_folder, filename)
        cv2.imwrite(filepath, photo)
        print(f"  ✓ Saved: {filepath}")

    # Update embeddings database
    database[str(student_id)] = embeddings
    save_embeddings(database)

    # Summary
    print("\n" + "=" * 50)
    print("✓ REGISTRATION COMPLETE")
    print("=" * 50)
    print(f"Student ID: {student_id}")
    print(f"Photos saved: {len(photos)}")
    print(f"Embeddings generated: {len(embeddings)}")
    print(f"Photo location: {student_folder}")
    print("\nNote: The student will now be recognized by the main system.")
    print("=" * 50)


# ==========================================
# RUN
# ==========================================
if __name__ == "__main__":
    try:
        add_student()
    except KeyboardInterrupt:
        print("\n\n⚠ Registration cancelled by user")
    except Exception as e:
        print(f"\n✗ Unexpected error: {e}")
    finally:
        cv2.destroyAllWindows()