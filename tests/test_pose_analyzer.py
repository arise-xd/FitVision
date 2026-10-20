from types import SimpleNamespace
from unittest.mock import Mock

import numpy as np

from fitvision_ml.core import pose_analyzer
from fitvision_ml.core.pose_analyzer import Keypoint, PoseAnalyzer
from fitvision_ml.core.video_reader import VideoFrame


def test_pose_analyzer_returns_keypoints(tmp_path, monkeypatch):
    model_path = tmp_path / "pose_landmarker.task"
    model_path.write_bytes(b"fake model")

    detected_landmark = SimpleNamespace(
        x=0.1,
        y=0.2,
        z=-0.3,
        visibility=0.9,
    )
    detection_result = SimpleNamespace(pose_landmarks=[[detected_landmark]])

    landmarker = Mock()
    landmarker.detect_for_video.return_value = detection_result

    monkeypatch.setattr(
        pose_analyzer.vision.PoseLandmarker,
        "create_from_options",
        Mock(return_value=landmarker),
    )

    frame = VideoFrame(
        frame_index=0,
        frame_timestamp_ms=125.0,
        bgr_image=np.zeros((480, 640, 3), dtype=np.uint8),
    )

    with PoseAnalyzer(model_path=model_path) as analyzer:
        points = analyzer.get_points(frame)

    assert points == [
        Keypoint(
            name="NOSE",
            x=0.1,
            y=0.2,
            z=-0.3,
            visibility=0.9,
        )
    ]

    landmarker.detect_for_video.assert_called_once()
    landmarker.close.assert_called_once()
