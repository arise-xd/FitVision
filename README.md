# FitVision

FitVision is a university project for exercise technique analysis using computer vision and machine learning.

The planned application allows users to upload an exercise video, select the camera view, and receive feedback for individual repetitions. The initial focus is squat analysis from side and front views.

## Current Status

The components are being developed separately. The complete mobile-backend-ML workflow is not connected yet.

### Implemented in main

- Video validation, metadata extraction, and frame-by-frame reading using OpenCV.
- Body landmark extraction using MediaPipe Pose Landmarker.
- A frame-by-frame pose inspection tool.
- Side-view squat repetition detection based on knee angles.
- Frame numbers and timestamps for the start, bottom, and end of each detected repetition.
- Automated Python tests.
- A Java/Spring Boot backend with an analysis creation API and S3-compatible upload URL generation.
- A local MinIO configuration.
- GitHub Actions for Python checks and backend builds.

### In Progress

- Testing repetition detection on real videos and improving landmark preprocessing.
- Front-view squat repetition detection.
- PostgreSQL persistence and RabbitMQ integration — [PR #23](https://github.com/arise-xd/FitVision/pull/23).
- Flutter interface with mock API responses and Flutter CI checks — [PR #25](https://github.com/arise-xd/FitVision/pull/25).
- Agreement on the shared analysis result format and component integration.

### Next Steps

- Improve handling of noisy and missing landmarks.
- Connect the application, backend, and Python processing pipeline.
- Prepare labeled data and train models for predefined technique errors.

## ML Processing

Video -> Frames -> Body Landmarks -> Movement Features -> Repetition Detection

The current side-view implementation uses knee angles to detect completed repetitions. Technique error classification is a later stage.

Strong motion blur may produce landmark jumps and false repetitions. The current detection thresholds require further testing on different recordings.

## Technologies

- ML: Python 3.11, OpenCV, MediaPipe, NumPy.
- Backend: Java 17, Spring Boot, Gradle, S3-compatible storage.
- Mobile application: Flutter and Dart, currently in development.
- Infrastructure in development: PostgreSQL and RabbitMQ.
- Development tools: uv, pytest, Ruff, GitHub Actions.

## Repository Structure

```text
fitvision_ml/
├── core/              # Shared video and pose processing
└── squat/
    ├── side/          # Side-view analysis
    └── front/         # Front-view analysis

scripts/               # Model download and pose inspection
tests/                 # Python tests
backend-new/           # Spring Boot backend and local infrastructure
.github/workflows/     # CI configuration
```

## Run the ML Pipeline

Install [uv](https://docs.astral.sh/uv/getting-started/installation/), then run:

```bash
git clone https://github.com/arise-xd/FitVision.git
cd FitVision
uv python install
uv sync --locked
uv run --locked python scripts/download_models.py
```

Use a local side-view squat video. Replace `path/to/video.mp4` with its actual path.

Inspect body landmarks frame by frame:

```bash
uv run --locked python -m scripts.inspect_pose "path/to/video.mp4"
```

Press a key to advance to the next frame or `q` to exit.

Detect repetitions:

```bash
uv run --locked python -m fitvision_ml.squat.side.repetitions "path/to/video.mp4" --side left
```

Use `--side right` to track the right leg.

The command prints the number of completed repetitions and their start, bottom, and end timestamps.

Videos and model files are stored locally and are not included in the repository.

## Development Checks

```bash
uv run --locked python -m pytest -v
uv run --locked ruff check .
uv run --locked ruff format --check .
```

Backend build, from `backend-new/`:

```bash
# macOS / Linux
bash gradlew build

# Windows
gradlew.bat build
```

Backend runtime requires local infrastructure configuration. The PostgreSQL/RabbitMQ setup is currently being completed in PR #23.

## Project Links

- [Project Vision](https://github.com/arise-xd/FitVision/wiki/Project-Vision)
- [Development Board](https://github.com/users/arise-xd/projects/1)
- [Wiki](https://github.com/arise-xd/FitVision/wiki)
