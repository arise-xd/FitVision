from dataclasses import dataclass
from pathlib import Path

import cv2
import mediapipe as mp
from mediapipe.tasks import python
from mediapipe.tasks.python import vision

from .video_reader import VideoFrame

DEFAULT_MODEL_PATH = Path(__file__).resolve().parents[2] / "models" / "pose_landmarker_lite.task"


@dataclass(frozen=True, slots=True)
class Keypoint:
    name: str
    x: float
    y: float
    z: float
    visibility: float


class PoseAnalyzer:
    def __init__(
        self,
        model_path: str | Path = DEFAULT_MODEL_PATH,
        min_detection_confidence: float = 0.6,
        min_tracking_confidence: float = 0.7,
    ):
        self.model_path = Path(model_path)

        if not self.model_path.is_file():
            raise FileNotFoundError(
                f"Pose model does not exist: {self.model_path}. "
                "Run: uv run --locked python scripts/download_models.py"
            )

        options = vision.PoseLandmarkerOptions(
            base_options=python.BaseOptions(model_asset_path=str(self.model_path)),
            running_mode=vision.RunningMode.VIDEO,
            num_poses=1,
            min_pose_detection_confidence=min_detection_confidence,
            min_pose_presence_confidence=min_detection_confidence,
            min_tracking_confidence=min_tracking_confidence,
        )

        self.pose = vision.PoseLandmarker.create_from_options(options)

    def get_points(self, frame: VideoFrame) -> list[Keypoint]:
        rgb_image = cv2.cvtColor(frame.bgr_image, cv2.COLOR_BGR2RGB)

        mediapipe_image = mp.Image(
            image_format=mp.ImageFormat.SRGB,
            data=rgb_image,
        )

        result = self.pose.detect_for_video(
            mediapipe_image,
            round(frame.frame_timestamp_ms),
        )

        if not result.pose_landmarks:
            return []

        landmarks = result.pose_landmarks[0]

        return [
            Keypoint(
                name=vision.PoseLandmark(index).name,
                x=landmark.x,
                y=landmark.y,
                z=landmark.z,
                visibility=(landmark.visibility if landmark.visibility is not None else 0.0),
            )
            for index, landmark in enumerate(landmarks)
        ]

    def close(self) -> None:
        self.pose.close()

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        self.close()
