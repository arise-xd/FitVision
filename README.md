# FitVision

FitVision is an application for exercise technique analysis using computer vision and machine learning.

The user records or uploads an exercise video and selects the camera view. The system will extract body landmarks, divide the exercise set into repetitions, detect predefined technique errors, and provide feedback.

The first prototype focuses on squat analysis from two views:

- side view;
- front view.

Each view will be processed by a separate analysis module.

## Current Status

The project is currently in early development.

Implemented:

- cross-platform Python environment using `uv`;
- shared ML package structure;
- video file validation;
- extraction of video width, height, frame rate, and frame count;
- automated tests for missing and invalid video files.

In progress:

- frame-by-frame video reading;
- body landmark extraction using MediaPipe Pose Landmarker.

Planned:

- movement feature extraction;
- repetition detection;
- technique error classification;
- backend video processing;
- mobile application for video upload and result display.

## Processing Pipeline

Video -> Frames -> Body Landmarks -> Movement Features -> Repetition Detection -> ML Analysis -> Feedback

## Technologies

- Python 3.11
- OpenCV
- MediaPipe
- NumPy
- scikit-learn
- pytest
- Ruff
- uv
- Java
  
Others technologies will be here later on next development stages.

## Project Structure

```text
fitvision_ml/
├── core/
│   └── shared video processing tools
└── squat/
    ├── side/
    └── front/

tests/
└── automated tests
```

## Setup

Install `uv`, clone the repository, and install the project dependencies:

```bash
git clone https://github.com/arise-xd/FitVision.git
cd FitVision
uv python install
uv sync --locked
```

Run the tests:

```bash
uv run --locked python -m pytest -v
```

Run code checks:

```bash
uv run --locked ruff check .
uv run --locked ruff format --check .
```

## Project Links

- [Project Vision](https://github.com/arise-xd/FitVision/wiki/Project-Vision)
- [Development Board](https://github.com/users/arise-xd/projects/1)
- [Wiki Home](https://github.com/arise-xd/FitVision/wiki)
