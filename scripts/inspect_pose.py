# Run from the project root: uv run --locked python -m scripts.inspect_pose
import argparse
from pathlib import Path

import cv2
from mediapipe.tasks.python.vision import PoseLandmark, PoseLandmarksConnections

from fitvision_ml.core.pose_analyzer import PoseAnalyzer
from fitvision_ml.core.video_reader import VideoFrameReader

POSE_CONNECTIONS = PoseLandmarksConnections.POSE_LANDMARKS


def draw_skeleton(image, keypoints, visibility_threshold=0.5):
    h, w, _ = image.shape
    coord_map = {}

    for i in range(11, len(keypoints)):
        kp = keypoints[i]
        if kp.visibility >= visibility_threshold:
            cx, cy = int(kp.x * w), int(kp.y * h)
            coord_map[kp.name] = (cx, cy)
            cv2.circle(image, (cx, cy), 4, (0, 0, 255), -1)

    for connection in POSE_CONNECTIONS:
        try:
            start_idx = connection.start
            end_idx = connection.end

            start_name = PoseLandmark(start_idx).name
            end_name = PoseLandmark(end_idx).name

            if start_name in coord_map and end_name in coord_map:
                cv2.line(image, coord_map[start_name], coord_map[end_name], (255, 0, 0), 2)
        except (ValueError, IndexError, AttributeError):
            continue


def main():
    parser = argparse.ArgumentParser(
        description="Frame-by-frame video preview with MediaPipe pose landmarks."
    )

    parser.add_argument(
        "video_path",
        type=Path,
        help="Path to the video file.",
    )

    args = parser.parse_args()
    video_path = args.video_path

    print(f"Opening video: {video_path.name}")
    print("\nVideo controls:")
    print("  [Any key] - Move to the next frame")
    print("  [q]       - Exit")

    try:
        # Open the video reader and pose analyzer using context managers
        with VideoFrameReader(video_path) as reader, PoseAnalyzer() as analyzer:
            for frame in reader:
                # Copy the frame so the original image is not modified
                display_image = frame.bgr_image.copy()

                # Detect pose landmarks in the current frame
                keypoints = analyzer.get_points(frame)

                # Draw the skeleton over the frame
                draw_skeleton(display_image, keypoints)

                TARGET_WIDTH = 960
                TARGET_HEIGHT = 720
                resized_image = cv2.resize(
                    display_image, (TARGET_WIDTH, TARGET_HEIGHT), interpolation=cv2.INTER_LINEAR
                )

                cv2.imshow("FitVision - Pose Inspector", resized_image)

                # Wait for a key before moving to the next frame
                key = cv2.waitKey(0) & 0xFF
                if key == ord("q"):
                    print("Exiting pose inspector.")
                    break

            print("Video inspection finished.")

    except Exception as error:
        print(f"\n[Pose inspector error]: {error}")
    finally:
        cv2.destroyAllWindows()


if __name__ == "__main__":
    main()
