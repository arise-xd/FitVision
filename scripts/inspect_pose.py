#запускается из корневой папки проекта через  uv run scripts/inspect_pose.py
import argparse
import sys
from pathlib import Path
import cv2
import mediapipe as mp

sys.path.append(str(Path(__file__).resolve().parent.parent))

from fitvision_ml.core.video_reader import VideoFrameReader
from fitvision_ml.core.pose_analyzer import PoseAnalyzer

POSE_CONNECTIONS = [
    (11, 12), (11, 13), (13, 15), (15, 17), (15, 19), (15, 21), (17, 19),
    (12, 14), (14, 16), (16, 18), (16, 20), (16, 22), (18, 20), (11, 23),
    (12, 24), (23, 24), (23, 25), (24, 26), (25, 27), (26, 28), (27, 29),
    (28, 30), (29, 31), (30, 32), (27, 31), (28, 32)
]



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
            start_idx = connection[0]
            end_idx = connection[1]

            from mediapipe.tasks.python.vision import PoseLandmark
            start_name = PoseLandmark(start_idx).name
            end_name = PoseLandmark(end_idx).name
            
            if start_name in coord_map and end_name in coord_map:
                cv2.line(image, coord_map[start_name], coord_map[end_name], (255, 0, 0), 2)
        except (ValueError, IndexError, AttributeError):
            continue

def main():

    project_root = Path(__file__).resolve().parents[1]
    default_video = project_root / "fitvision_ml" / "dataset" / "v_BodyWeightSquats_g15_c03.avi"

    parser = argparse.ArgumentParser(description="Покадровый просмотр видео из датасета с разметкой MediaPipe")
    parser.add_argument(
        "--video", 
        type=str, 
        default=str(default_video), 
        help="Путь к видеофайлу"
    )
    args = parser.parse_args()
    video_path = Path(args.video)
    
    print(f"Инициализация. Открываем файл: {video_path.name}")
    print("\nУправление в окне видео:")
    print("  [Любая клавиша] - Шагнуть на 1 кадр вперед")
    print("  [Клавиша 'q']   - Выйти из скрипта")

    try:
        # Запуск ридера и анализатора через контекстные менеджеры
        with VideoFrameReader(video_path) as reader, PoseAnalyzer() as analyzer:
            
            for frame in reader:
                # Делаем копию кадра для отрисовки графики
                display_image = frame.bgr_image.copy()
                
                # Получаем точки через PoseAnalyzer
                keypoints = analyzer.get_points(frame)
                
                # Рисуем скелет поверх кадра
                draw_skeleton(display_image, keypoints)
                
                TARGET_WIDTH = 960
                TARGET_HEIGHT = 720
                resized_image = cv2.resize(display_image, (TARGET_WIDTH, TARGET_HEIGHT), interpolation=cv2.INTER_LINEAR)
            
                cv2.imshow("FitVision - Pose Inspector", resized_image)

                # Замираем на кадре до нажатия любой клавиши
                key = cv2.waitKey(0) & 0xFF
                if key == ord('q'):
                    print("Выход по нажатию 'q'.")
                    break
                    
            print("Видео успешно считано до конца.")
            
    except Exception as e:
        print(f"\n[Ошибка работы скрипта]: {e}")
    finally:
        cv2.destroyAllWindows()

if __name__ == "__main__":
    main()
