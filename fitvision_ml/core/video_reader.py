from dataclasses import dataclass
from pathlib import Path

import cv2
import numpy as np
import numpy.typing as npt

BGRImage = npt.NDArray[np.uint8]


@dataclass(frozen=True, slots=True)
class VideoMetadata:
    width: int
    height: int
    frame_rate: float
    frame_count: int


@dataclass(frozen=True, slots=True)
class VideoFrame:
    frame_index: int
    frame_timestamp_ms: float
    bgr_image: BGRImage


class VideoReadError(RuntimeError):
    """Raised when a video cannot be opened or decoded."""


def read_video_metadata(video_path: str | Path) -> VideoMetadata:
    video_path = Path(video_path)

    if not video_path.is_file():
        raise VideoReadError(f"Video file does not exist: {video_path}")

    video_file = cv2.VideoCapture(str(video_path))

    try:
        if not video_file.isOpened():
            raise VideoReadError(f"Video file cannot be opened: {video_path}")

        video_width = video_file.get(cv2.CAP_PROP_FRAME_WIDTH)
        video_height = video_file.get(cv2.CAP_PROP_FRAME_HEIGHT)
        video_frame_rate = video_file.get(cv2.CAP_PROP_FPS)
        video_frame_count = video_file.get(cv2.CAP_PROP_FRAME_COUNT)

        if video_width <= 0 or video_height <= 0 or video_frame_rate <= 0 or video_frame_count <= 0:
            raise VideoReadError(f"Video contains invalid metadata: {video_path}")

        video_metadata = VideoMetadata(
            width=int(video_width),
            height=int(video_height),
            frame_rate=video_frame_rate,
            frame_count=int(video_frame_count),
        )

        return video_metadata

    finally:
        video_file.release()
