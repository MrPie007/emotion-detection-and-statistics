import csv

import cv2
import pickle
import numpy as np
with open("log.csv", "w", newline="") as f:
    writer = csv.writer(f)

    writer.writerow([
        "student_id",
        "timestamp",
        "emotion",
        "confidence",
        "Lecture_id"

    ])