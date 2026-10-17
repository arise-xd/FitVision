from dataclasses import dataclass
from video_reader import VideoFrame

import cv2
import mediapipe as mp



@dataclass(frozen=True, slots=True)
class Keypoint:
    name: str
    x: float
    y: float
    z: float
    visibility: float


class PoseAnalyzer:

    def __init__(self, min_detection_confidence: float = 0.6, min_tracking_confidence: float = 0.7):
        self.mp_pose = mp.solutions.pose
        self.pose = self.mp_pose.Pose(
            static_image_mode=False,
            min_detection_confidence=min_detection_confidence,
            min_tracking_confidence=min_tracking_confidence
        )

    def get_points(self, frame: VideoFrame) -> list[Keypoint]:
        frame_rgb = cv2.cvtColor(frame.bgr_image, cv2.COLOR_BGR2RGB)
        
        results = self.pose.process(frame_rgb)
        
        keypoints: list[Keypoint] = []
        
        if results.pose_landmarks:
            for landmark_id, landmark in enumerate(results.pose_landmarks.landmark):
                keypoints.append(
                    Keypoint(
                        name=self.mp_pose.PoseLandmark(landmark_id).name,
                        x=landmark.x,
                        y=landmark.y,
                        z=landmark.z,
                        visibility=landmark.visibility
                    )
                )
        return keypoints

    def close(self) -> None:
        self.pose.close()

    # For wirking with "with . as ."
    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        self.close()
