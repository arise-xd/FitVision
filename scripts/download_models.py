import shutil
from pathlib import Path
from urllib.request import urlopen

MODEL_URL = (
    "https://storage.googleapis.com/mediapipe-models/"
    "pose_landmarker/pose_landmarker_lite/float16/1/"
    "pose_landmarker_lite.task"
)
PROJECT_ROOT = Path(__file__).resolve().parents[1]
MODEL_PATH = PROJECT_ROOT / "models" / "pose_landmarker_lite.task"
EXPECTED_SIZE = 5777746


def download_model() -> None:
    if MODEL_PATH.is_file() and MODEL_PATH.stat().st_size == EXPECTED_SIZE:
        print(f"Model already exists: {MODEL_PATH}")
        return

    MODEL_PATH.parent.mkdir(parents=True, exist_ok=True)
    temporary_path = MODEL_PATH.with_suffix(".task.tmp")

    print(f"Downloading model to {MODEL_PATH}...")

    try:
        with urlopen(MODEL_URL) as response:
            with temporary_path.open("wb") as model_file:
                shutil.copyfileobj(response, model_file)

        actual_size = temporary_path.stat().st_size
        if actual_size != EXPECTED_SIZE:
            raise RuntimeError(f"Incorrect model size: expected {EXPECTED_SIZE}, got {actual_size}")

        temporary_path.replace(MODEL_PATH)
    except Exception:
        temporary_path.unlink(missing_ok=True)
        raise

    print("Model downloaded successfully")


if __name__ == "__main__":
    download_model()
