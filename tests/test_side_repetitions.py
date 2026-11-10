from fitvision_ml.squat.side.repetitions import detect_repetitions


def test_detects_one_complete_rep_between_partial_movements() -> None:
    angles = [
        [0, 0.0, 98],
        [1, 66.7, 172],
        [2, 133.3, 162],
        [3, 200.0, 91],
        [4, 266.7, 120],
        [5, 333.3, 170],
        [6, 400.0, 160],
    ]

    assert detect_repetitions(angles) == [
        {
            "start": {"frame_index": 2, "timestamp_ms": 133.3},
            "bottom": {"frame_index": 3, "timestamp_ms": 200.0},
            "end": {"frame_index": 5, "timestamp_ms": 333.3},
        }
    ]


def test_does_not_count_rep_without_return_to_top() -> None:
    angles = [[0, 0.0, 172], [1, 66.7, 162], [2, 133.3, 91]]

    assert detect_repetitions(angles) == []


def test_skips_missing_angle_without_losing_rep_boundaries() -> None:
    angles = [
        [0, 0.0, 170],
        [1, 66.7, 162],
        [2, 133.3, None],
        [3, 200.0, 91],
        [4, 266.7, 170],
    ]

    assert detect_repetitions(angles) == [
        {
            "start": {"frame_index": 1, "timestamp_ms": 66.7},
            "bottom": {"frame_index": 3, "timestamp_ms": 200.0},
            "end": {"frame_index": 4, "timestamp_ms": 266.7},
        }
    ]
