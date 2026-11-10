import math

from fitvision_ml.core.pose_analyzer import Keypoint, PoseAnalyzer
from fitvision_ml.core.video_reader import VideoFrameReader


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
