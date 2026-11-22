from dataclasses import dataclass
from typing import Literal

from .pose_analyzer import Keypoint


def distance_between_points(first_point, second_point):
    x1, y1 = first_point
    x2, y2 = second_point
    return (((x2 - x1) ** 2) + ((y2 - y1) ** 2)) ** (1 / 2)


@dataclass
class PoseFrame:
    frame_index: int
    frame_timestamp_ms: float
    points: list[Keypoint]


@dataclass
class FilteredPoseFrame(PoseFrame):
    status: Literal["accepted", "missing", "suspect"]


@dataclass
class PoseFilterResult:
    frames: list[FilteredPoseFrame]
    unreliable_fraction: float
    longest_gap_ms: float


def filter_poses(
    frames: list[PoseFrame], frame_width, frame_height, frame_rate, side
) -> PoseFilterResult:
    result_frames = []
    suspect_value = 0.1
    longest_gap = 0
    gap_start_ms = None
    unreliable_frames = 0
    total_frames = 0
    last_measurements = None
    status = ""
    last_frame_timestamp = None
    for frame in frames:
        last_frame_timestamp = frame.frame_timestamp_ms
        total_frames += 1

        if not frame.points:
            status = "missing"

        else:
            new_x_knee = new_y_knee = 0
            new_knee_visibility = 0
            new_x_pelvis = new_y_pelvis = 0
            new_pelvis_visibility = 0
            new_x_shoulder = new_y_shoulder = 0
            new_shoulder_visibility = 0

            if side == "left":
                for point in frame.points:
                    if point.name == "LEFT_KNEE":
                        new_x_knee, new_y_knee = (point.x * frame_width, point.y * frame_height)
                        new_knee_visibility = point.visibility
                    if point.name == "LEFT_HIP":
                        new_x_pelvis, new_y_pelvis = (point.x * frame_width, point.y * frame_height)
                        new_pelvis_visibility = point.visibility
                    if point.name == "LEFT_SHOULDER":
                        new_x_shoulder = point.x * frame_width
                        new_y_shoulder = point.y * frame_height
                        new_shoulder_visibility = point.visibility

            elif side == "right":
                for point in frame.points:
                    if point.name == "RIGHT_KNEE":
                        new_x_knee, new_y_knee = (point.x * frame_width, point.y * frame_height)
                        new_knee_visibility = point.visibility
                    if point.name == "RIGHT_HIP":
                        new_x_pelvis, new_y_pelvis = (point.x * frame_width, point.y * frame_height)
                        new_pelvis_visibility = point.visibility
                    if point.name == "RIGHT_SHOULDER":
                        new_x_shoulder = point.x * frame_width
                        new_y_shoulder = point.y * frame_height
                        new_shoulder_visibility = point.visibility

            torso_length = distance_between_points(
                (new_x_shoulder, new_y_shoulder), (new_x_pelvis, new_y_pelvis)
            )
            if (
                new_knee_visibility < 0.5
                or new_pelvis_visibility < 0.5
                or new_shoulder_visibility < 0.5
                or torso_length == 0
            ):
                status = "suspect"
            elif last_measurements is None:
                status = "accepted"
            else:
                old_knee, old_pelvis, last_torso_length = last_measurements
                knee_distance = distance_between_points(old_knee, (new_x_knee, new_y_knee))
                pelvis_distance = distance_between_points(old_pelvis, (new_x_pelvis, new_y_pelvis))
                if (
                    knee_distance / last_torso_length > suspect_value
                    and pelvis_distance / last_torso_length > suspect_value
                ):
                    status = "suspect"
                else:
                    status = "accepted"

        if status == "accepted":
            filtered_frame = FilteredPoseFrame(
                frame_index=frame.frame_index,
                frame_timestamp_ms=frame.frame_timestamp_ms,
                points=frame.points,
                status=status,
            )
            last_measurements = (new_x_knee, new_y_knee), (new_x_pelvis, new_y_pelvis), torso_length
            if gap_start_ms is not None:
                longest_gap = max(longest_gap, frame.frame_timestamp_ms - gap_start_ms)
                gap_start_ms = None
        else:
            filtered_frame = FilteredPoseFrame(
                frame_index=frame.frame_index,
                frame_timestamp_ms=frame.frame_timestamp_ms,
                points=[],
                status=status,
            )
            unreliable_frames += 1
            if gap_start_ms is None:
                gap_start_ms = frame.frame_timestamp_ms

        result_frames.append(filtered_frame)

    if gap_start_ms is not None:
        current_timestamp = last_frame_timestamp + (1000 / frame_rate)
        longest_gap = max(longest_gap, current_timestamp - gap_start_ms)

    if not total_frames:
        result = PoseFilterResult(
            frames=result_frames,
            unreliable_fraction=0.0,
            longest_gap_ms=longest_gap,
        )
    else:
        result = PoseFilterResult(
            frames=result_frames,
            unreliable_fraction=unreliable_frames / total_frames,
            longest_gap_ms=longest_gap,
        )

    return result
