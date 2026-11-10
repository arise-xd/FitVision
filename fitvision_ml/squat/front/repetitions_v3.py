import argparse
import sys
from pathlib import Path
import math
import time

sys.path.append(str(Path(__file__).resolve().parent.parent.parent.parent))

from fitvision_ml.core.video_reader import VideoFrameReader
from fitvision_ml.core.pose_analyzer import PoseAnalyzer, Keypoint


def calculate_knee_angle(hip, knee, ankle):
    x_knee, y_knee = knee
    x_hip, y_hip = hip
    x_ankle, y_ankle = ankle

    u = ((x_hip - x_knee), (y_hip - y_knee))
    v = ((x_ankle - x_knee), (y_ankle - y_knee))

    u_length = math.hypot(*u)
    v_length = math.hypot(*v)

    if u_length * v_length == 0:
        return None

    cos_val = ((u[0] * v[0]) + (u[1] * v[1])) / (u_length * v_length)
    cos_val = max(-1.0, min(1.0, cos_val))

    return math.degrees(math.acos(cos_val))


def get_average_knee_angle(keypoints: list[Keypoint]) -> float | None:

    coords = {kp.name: (kp.x, kp.y, kp.visibility) for kp in keypoints}
    angles = []

    if all(k in coords and coords[k][2] >= 0.5 for k in ["LEFT_HIP", "LEFT_KNEE", "LEFT_ANKLE"]):
        left = calculate_knee_angle(coords["LEFT_HIP"][:2], coords["LEFT_KNEE"][:2], coords["LEFT_ANKLE"][:2])
        if left is not None:
            angles.append(left)

    if all(k in coords and coords[k][2] >= 0.5 for k in ["RIGHT_HIP", "RIGHT_KNEE", "RIGHT_ANKLE"]):
        right = calculate_knee_angle(coords["RIGHT_HIP"][:2], coords["RIGHT_KNEE"][:2], coords["RIGHT_ANKLE"][:2])
        if right is not None:
            angles.append(right)

    if not angles:
        return None
    return sum(angles) / len(angles)


def analyze_video_angles(video_path, step: int = 2) -> list[tuple[int, float, float | None]]:
    frame_angles = []
    start_time = time.perf_counter()

    with VideoFrameReader(video_path) as reader, PoseAnalyzer() as analyzer:
        meta = reader.video_metadata
        total_frames = meta.frame_count
        
        print(f"Total frames: {total_frames}")
        print(f"FPS: {meta.frame_rate:.2f} | Skipped frame is every {step}")

   
        while reader.next_frame_index < total_frames:
            frame_index = reader.next_frame_index
            
            
            if frame_index % 10 == 0 or frame_index >= total_frames - step:
                print(f"  -> Frames done: {frame_index + 1}/{total_frames}", end="\r")

            
            frame = reader.read_next_frame()
            if frame is None:
                break

            keypoints = analyzer.get_points(frame)
            avg_angle = get_average_knee_angle(keypoints)
            frame_angles.append((frame.frame_index, frame.frame_timestamp_ms, avg_angle))


            if frame_index % step == 0 :
                if reader.next_frame_index >= total_frames:
                    break
                
                reader.capture.grab()
                reader.next_frame_index += 1

        processing_time = time.perf_counter() - start_time

        print(f"Time: {processing_time:.2f} sec.")

    return frame_angles



def detect_repetitions(frame_angles: list[tuple[int, float, float | None]], window_size) -> list[dict]:
    valid_data = [(idx, ts, ang) for idx, ts, ang in frame_angles if ang is not None]
    if len(valid_data) < window_size:
        return []

    smoothed_data = []
    for i in range(len(valid_data)):
        start_win = max(0, i - window_size + 1)
        window = valid_data[start_win:i + 1]
        avg_ang = sum(item[2] for item in window) / len(window)
        smoothed_data.append((valid_data[i][0], valid_data[i][1], avg_ang))

    results = []
    current_rep = {}
    state = "SETUP"
    
    ANGLE_STANDING_MIN = 160.0
    ANGLE_DEEP_SQUAT = 142.0 

    min_angle_in_rep = 180.0
    prev_angle = None

    for frame_index, timestamp_ms, angle in smoothed_data:
        if prev_angle is not None:
            delta = angle - prev_angle

            if state == "SETUP":
                if angle >= ANGLE_STANDING_MIN:
                    state = "STANDING"

            elif state == "STANDING":
                if delta < -0.4 and angle < ANGLE_STANDING_MIN:
                    state = "DESCENDING"
                    min_angle_in_rep = angle
                    current_rep = {
                        "start": {"frame_index": frame_index, "timestamp_ms": timestamp_ms},
                        "bottom": {"frame_index": frame_index, "timestamp_ms": timestamp_ms}
                    }

            elif state == "DESCENDING":
                if angle < min_angle_in_rep:
                    min_angle_in_rep = angle
                    current_rep["bottom"] = {"frame_index": frame_index, "timestamp_ms": timestamp_ms}
                
                if delta > 0.4:
                    state = "ASCENDING"

            elif state == "ASCENDING":
                if angle >= ANGLE_STANDING_MIN:
                    if min_angle_in_rep <= ANGLE_DEEP_SQUAT:
                        current_rep["end"] = {"frame_index": frame_index, "timestamp_ms": timestamp_ms}
                        results.append(current_rep)
                    
                    state = "STANDING"
                    current_rep = {}

        prev_angle = angle

    return results



def main():
    parser = argparse.ArgumentParser(description="Front-view squat repetition detector.")
    parser.add_argument("video_path", type=Path, help="Path to the video file.")
    args = parser.parse_args()

    try:
        STEP = 3
        
        angles = analyze_video_angles(args.video_path, step=STEP)
    except Exception as error:
        print(f"Error: {error}")
        return


    reps = detect_repetitions(angles, window_size = 4)

    print(f"\nVideo: {args.video_path.name}")
    print(f"Repetition counts: {len(reps)}")
    
    if reps:
        print(f"\n{'№':>2}  {'Fase':<8}  {'Frame':>6}  {'Time (мс)':>10}")
        for idx, rep in enumerate(reps, start=1):
            for phase in ("start", "bottom", "end"):
                pt = rep[phase]
                print(f"{idx:>2}  {phase:<8}  {pt['frame_index']:>6}  {pt['timestamp_ms']:>10.1f}")



if __name__ == "__main__":
    main()
