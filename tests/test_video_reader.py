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
