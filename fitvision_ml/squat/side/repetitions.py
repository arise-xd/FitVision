import argparse
import math
from pathlib import Path

from fitvision_ml.core.pose_analyzer import Keypoint, PoseAnalyzer
from fitvision_ml.core.video_reader import VideoFrameReader, VideoReadError


def calculate_knee_angle(pelvis, knee, ankle):
    x_knee, y_knee = knee
    x_pelvis, y_pelvis = pelvis
    x_ankle, y_ankle = ankle

    u = ((x_pelvis - x_knee), (y_pelvis - y_knee))
    v = ((x_ankle - x_knee), (y_ankle - y_knee))

    u_lenght = math.hypot(*u)
    v_lenght = math.hypot(*v)

    if u_lenght * v_lenght == 0:
        return None

    cos = ((u[0] * v[0]) + (u[1] * v[1])) / (u_lenght * v_lenght)

    if cos < -1:
        cos = -1
    if cos > 1:
        cos = 1

    return math.degrees(math.acos(cos))


def get_knee_angle_from_keypoints(keypoints: list[Keypoint], frame_width, frame_height, side):
    x_knee = y_knee = 0
    knee_visibility = 0
    x_pelvis = y_pelvis = 0
    pelvis_visibility = 0
    x_ankle = y_ankle = 0
    ankle_visibility = 0

    if side == "left":
        for point in keypoints:
            if point.name == "LEFT_KNEE":
                x_knee, y_knee = (point.x * frame_width, point.y * frame_height)
                knee_visibility = point.visibility
            if point.name == "LEFT_HIP":
                x_pelvis, y_pelvis = (point.x * frame_width, point.y * frame_height)
                pelvis_visibility = point.visibility
            if point.name == "LEFT_ANKLE":
                x_ankle, y_ankle = (point.x * frame_width, point.y * frame_height)
                ankle_visibility = point.visibility
    elif side == "right":
        for point in keypoints:
            if point.name == "RIGHT_KNEE":
                x_knee, y_knee = (point.x * frame_width, point.y * frame_height)
                knee_visibility = point.visibility
            if point.name == "RIGHT_HIP":
                x_pelvis, y_pelvis = (point.x * frame_width, point.y * frame_height)
                pelvis_visibility = point.visibility
            if point.name == "RIGHT_ANKLE":
                x_ankle, y_ankle = (point.x * frame_width, point.y * frame_height)
                ankle_visibility = point.visibility
    else:
        return None

    if knee_visibility < 0.5 or pelvis_visibility < 0.5 or ankle_visibility < 0.5:
        return None

    return calculate_knee_angle((x_pelvis, y_pelvis), (x_knee, y_knee), (x_ankle, y_ankle))


def knee_angle_video(video_path, side):
    result = []
    with VideoFrameReader(video_path) as reader, PoseAnalyzer() as analyzer:
        for frame in reader:
            frame_height, frame_width = frame.bgr_image.shape[:2]
            keypoints = analyzer.get_points(frame)
            knee_angle = get_knee_angle_from_keypoints(keypoints, frame_width, frame_height, side)
            result.append([frame.frame_index, frame.frame_timestamp_ms, knee_angle])
    return result


def detect_repetitions(angles):
    up_state = 0
    repetition_state = 0
    result = []
    current_repetition = dict()
    min_angle = 1000
    repetition_count = 0
    for angle in angles:
        frame_index = angle[0]
        frame_timestamp_ms = angle[1]
        knee_angle = angle[2]

        if knee_angle is None:
            continue

        if knee_angle >= 168 and up_state == 0 and repetition_state == 0:
            up_state = 1
            repetition_count += 1

        if knee_angle <= 165 and up_state == 1 and repetition_state == 0:
            up_state = 0
            repetition_state = 1
            min_angle = knee_angle
            current_repetition["start"] = {
                "frame_index": frame_index,
                "timestamp_ms": frame_timestamp_ms,
            }

            current_repetition["bottom"] = {
                "frame_index": frame_index,
                "timestamp_ms": frame_timestamp_ms,
            }

        if knee_angle <= 165 and repetition_state == 1 and up_state == 0:
            if knee_angle < min_angle:
                min_angle = knee_angle
                current_repetition["bottom"] = {
                    "frame_index": frame_index,
                    "timestamp_ms": frame_timestamp_ms,
                }

        if knee_angle >= 168 and up_state == 0 and repetition_state == 1:
            up_state = 1
            repetition_state = 0
            current_repetition["end"] = {
                "frame_index": frame_index,
                "timestamp_ms": frame_timestamp_ms,
            }
            result.append(current_repetition)
            current_repetition = dict()
    return result


def main() -> None:
    parser = argparse.ArgumentParser(description="Detect squat repetitions in a side-view video.")
    parser.add_argument("video_path", type=Path, help="Path to the video file.")
    parser.add_argument(
        "--side",
        choices=("left", "right"),
        default="left",
        help="Leg to track (default: left).",
    )
    args = parser.parse_args()

    try:
        angles = knee_angle_video(args.video_path, args.side)
    except (VideoReadError, FileNotFoundError) as error:
        parser.exit(1, f"Error: {error}\n")

    repetitions = detect_repetitions(angles)
    print(f"Video: {args.video_path.name} | Leg: {args.side}")
    print(f"Completed repetitions: {len(repetitions)}")
    if not repetitions:
        return

    print(f"\n{'Rep':>4}  {'Phase':<6}  {'Frame':>6}  {'Time (ms)':>10}")
    for number, repetition in enumerate(repetitions, start=1):
        for phase in ("start", "bottom", "end"):
            point = repetition[phase]
            print(
                f"{number:>4}  {phase:<6}  {point['frame_index']:>6}  {point['timestamp_ms']:>10.1f}"
            )


if __name__ == "__main__":
    main()
