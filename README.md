# Classroom Emotion Detection and Statistical Analysis System

> An AI-powered system for real-time student emotion recognition, attendance tracking, and engagement analytics — built with Python, DeepFace, and R Shiny.

---

## Overview

Traditional attendance systems capture presence, but not engagement. This project goes further: it automatically detects student faces via webcam, recognizes emotions in real-time, logs attendance, and visualizes engagement trends through an interactive R Shiny dashboard — giving instructors immediate, data-driven feedback on classroom dynamics.

**Developed as part of (EBA3201) Advanced Statistics**
Arab Academy for Science, Technology, and Maritime Transport — College of Computing and Information Technology, Cairo
Supervised by: **Dr. Mohamed Fathy** | May 2026

---

## Features

-  **Face Recognition** — FaceNet512 embeddings with cosine similarity matching
-  **Emotion Detection** — Classifies 7 emotions: Happy, Sad, Angry, Neutral, Surprise, Fear, Disgust
-  **Automated Attendance** — Logs recognized students to CSV and SQLite
-  **R Shiny Dashboard** — Interactive visualizations of engagement, emotions, and attendance trends
-  **Role-Based Access** — Admin, Professor, and Teaching Assistant roles
-  **Live Camera Feed** — Real-time face detection overlay in the dashboard

---

## Screenshots

### Dashboard + Emotion Statistics

![Dashboard Overview](screenshots/emotionstats.png)

### Time Trends

![Dashboard Overview](screenshots/timetrendStats.png)

##  System Architecture

The system is composed of four core modules:

| Module | Description |
|--------|-------------|
| **Face Registration** | Captures multiple images per student, generates FaceNet512 embeddings, stores in a pickle database |
| **Real-time Recognition** | Processes live webcam feed via OpenCV, identifies students using cosine similarity |
| **Emotion Detection** | Analyzes facial expressions in real-time with confidence scores |
| **Statistical Dashboard** | R Shiny app that loads log data, computes engagement metrics, and renders interactive charts |

---

## 🔄 System Workflow

```
Camera → OpenCV face detection → DeepFace embedding + emotion analysis
       → Cosine similarity match against DB → Attendance logged (CSV/SQLite)
       → Emotion data written to CSV → R Shiny dashboard visualizes in real-time
```

---

##  Statistical Methods

### Engagement Score

Each detected face receives an engagement score:

```
Engagement = Emotion Weight × Confidence
```

| Emotion  | Weight |
|----------|--------|
| Happy    | 1.0    |
| Surprise | 0.8    |
| Neutral  | 0.5    |
| Sad      | 0.3    |
| Fear     | 0.2    |
| Angry    | 0.1    |
| Disgust  | 0.0    |

### Face Recognition (Cosine Similarity)

```
Similarity = (A · B) / (‖A‖ × ‖B‖)
```

Where `A` and `B` are 512-dimensional face embeddings. A match is declared when the cosine **distance** falls below `0.2`.

---

##  Tech Stack

| Technology | Role |
|------------|------|
| **Python** | Core language for detection, recognition, and embedding |
| **DeepFace** | Face recognition and emotion analysis library |
| **OpenCV** | Camera capture, face region extraction, image preprocessing |
| **FaceNet512** | Deep learning model generating 512-dim face embeddings |
| **SQLite & CSV** | Attendance and emotion log storage |
| **R** | Statistical computing and data analysis |
| **R Shiny** | Interactive real-time web dashboard |
| **ggplot2 & dplyr** | Data visualization and manipulation in R |

---

##  Dashboard Panels

| Tab | Contents |
|-----|----------|
| **Attendance** | Pie chart of present vs. absent students + detailed list |
| **Overview** | Emotion frequency distribution and engagement score histograms |
| **Time Trends** | Engagement and emotion trends over lecture duration |
| **Students** | Per-student engagement averages and lecture heatmaps |
| **Live Camera** | Real-time video feed with face detection overlay |
| **Raw Data** | Latest 50 emotion detection records |

---

##  Authentication

The dashboard supports three access levels (currently not fully implemented):

- **Administrator** — Full system access
- **Professor** — View all lecture data and analytics
- **Teaching Assistant** — Limited view access


---

##  License

This project was developed for academic purposes. Please check with the team before using or adapting it commercially.

---

##  Keywords

Face Recognition · Emotion Detection · Deep Learning · Statistical Analysis · R Shiny · Classroom Engagement · DeepFace · FaceNet512 · OpenCV
