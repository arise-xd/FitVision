from unittest.mock import Mock

import numpy as np
import pytest

from fitvision_ml.core import video_reader


def test_missing_video_raises_error(tmp_path) -> None:
    missing_video_path = tmp_path / "missing.mp4"

    with pytest.raises(video_reader.VideoReadError, match="Video file does not exist"):
        video_reader.read_video_metadata(missing_video_path)


def test_non_video_file_raises_error(tmp_path) -> None:
    invalid_video_path = tmp_path / "invalid.mp4"
    invalid_video_path.write_bytes(b"invalid video")

    with pytest.raises(video_reader.VideoReadError, match="Video file cannot be opened"):
        video_reader.read_video_metadata(invalid_video_path)


def test_video_frame_reader_reads_frames_in_order(tmp_path, monkeypatch) -> None:
    video_path = tmp_path / "video.mp4"
    video_path.write_bytes(b"fake video")

    first_image = np.zeros((2, 2, 3), dtype=np.uint8)
    second_image = np.ones((2, 2, 3), dtype=np.uint8)

    metadata_capture = Mock()
    metadata_capture.isOpened.return_value = True
    metadata_capture.get.side_effect = lambda property_id: {
        video_reader.cv2.CAP_PROP_FRAME_WIDTH: 2.0,
        video_reader.cv2.CAP_PROP_FRAME_HEIGHT: 2.0,
        video_reader.cv2.CAP_PROP_FPS: 10.0,
        video_reader.cv2.CAP_PROP_FRAME_COUNT: 2.0,
    }[property_id]

    frame_capture = Mock()
    frame_capture.isOpened.return_value = True
    frame_capture.read.side_effect = [
        (True, first_image),
        (True, second_image),
        (False, None),
    ]

    timestamps = iter([0.0, 100.0])
    frame_capture.get.side_effect = lambda property_id: next(timestamps)

    capture_factory = Mock(side_effect=[metadata_capture, frame_capture])
    monkeypatch.setattr(video_reader.cv2, "VideoCapture", capture_factory)

    with video_reader.VideoFrameReader(video_path) as reader:
        frames = list(reader)

    assert [frame.frame_index for frame in frames] == [0, 1]
    assert [frame.frame_timestamp_ms for frame in frames] == [0.0, 100.0]

    np.testing.assert_array_equal(frames[0].bgr_image, first_image)
    np.testing.assert_array_equal(frames[1].bgr_image, second_image)

    assert reader.capture is None
    metadata_capture.release.assert_called_once()
    frame_capture.release.assert_called_once()
