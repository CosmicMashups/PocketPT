import argparse
import time
from typing import Tuple, Optional, List

import torch
import torch.nn as nn
import torchvision.transforms as T
from torchvision.models import mobilenet_v3_small
try:
    from torchvision.models import MobileNet_V3_Small_Weights
    DEFAULT_WEIGHTS = MobileNet_V3_Small_Weights.DEFAULT
    USE_NEW_API = True
except Exception:
    DEFAULT_WEIGHTS = None
    USE_NEW_API = False

import cv2
import numpy as np


def make_model(num_classes: int = 3) -> nn.Module:
    # Initialize without pretrained to avoid online fetch; we will load trained weights
    model = mobilenet_v3_small(weights=None)
    in_features = model.classifier[-1].in_features
    model.classifier[-1] = nn.Linear(in_features, num_classes)
    return model


class FaceTracker:
    """Simple exponential smoothing tracker for bounding boxes.

    Maintains previous box for a short time when detections drop.
    Box format: (x, y, w, h)
    """
    def __init__(self, alpha: float = 0.4, hold_frames: int = 10):
        self.alpha = float(np.clip(alpha, 0.0, 1.0))
        self.hold_frames = int(max(0, hold_frames))
        self.prev_box: Optional[Tuple[int, int, int, int]] = None
        self.miss_count: int = 0

    def update(self, det_box: Optional[Tuple[int, int, int, int]]) -> Optional[Tuple[int, int, int, int]]:
        if det_box is not None:
            self.miss_count = 0
            if self.prev_box is None:
                self.prev_box = det_box
            else:
                px, py, pw, ph = self.prev_box
                dx, dy, dw, dh = det_box
                # exponential smoothing
                sx = int(px + self.alpha * (dx - px))
                sy = int(py + self.alpha * (dy - py))
                sw = int(pw + self.alpha * (dw - pw))
                sh = int(ph + self.alpha * (dh - ph))
                self.prev_box = (sx, sy, sw, sh)
        else:
            if self.prev_box is not None and self.miss_count < self.hold_frames:
                self.miss_count += 1
                # keep last box
            else:
                self.prev_box = None
        return self.prev_box


def detect_faces_haar(gray: np.ndarray, scale_factor: float = 1.3, min_neighbors: int = 5,
                       min_size: int = 80) -> List[Tuple[int, int, int, int]]:
    face_cascade = cv2.CascadeClassifier(cv2.data.haarcascades + 'haarcascade_frontalface_default.xml')
    faces = face_cascade.detectMultiScale(
        gray,
        scaleFactor=scale_factor,
        minNeighbors=min_neighbors,
        minSize=(min_size, min_size)
    )
    return list(faces)


def largest_box(boxes: List[Tuple[int, int, int, int]]) -> Optional[Tuple[int, int, int, int]]:
    if not boxes:
        return None
    return max(boxes, key=lambda b: b[2] * b[3])

def best_centered_box(boxes: List[Tuple[int, int, int, int]], frame_shape: Tuple[int, int, int]) -> Optional[Tuple[int, int, int, int]]:
    if not boxes:
        return None
    h, w = frame_shape[:2]
    cx, cy = w * 0.5, h * 0.5
    def score(b):
        x, y, bw, bh = b
        bx, by = x + bw * 0.5, y + bh * 0.5
        dist = ((bx - cx) ** 2 + (by - cy) ** 2) ** 0.5
        return (bw * bh) - 0.25 * dist
    return max(boxes, key=score)

def detect_faces_multiscale(gray: np.ndarray, base_min_size: int, prev_box: Optional[Tuple[int, int, int, int]] = None) -> List[Tuple[int, int, int, int]]:
    face_cascade = cv2.CascadeClassifier(cv2.data.haarcascades + 'haarcascade_frontalface_default.xml')
    settings = [
        (1.05, 3, max(24, int(base_min_size))),
        (1.03, 3, max(24, int(base_min_size * 0.7))),
        (1.01, 2, max(16, int(base_min_size * 0.5))),
    ]
    # If previous box indicates a far/small face, bias towards finer scales
    if prev_box is not None and prev_box[2] < 80:
        settings = [
            (1.02, 2, max(16, int(base_min_size * 0.5))),
            (1.01, 2, max(12, int(base_min_size * 0.4))),
            (1.05, 3, max(24, int(base_min_size))),
        ]
    all_boxes: List[Tuple[int, int, int, int]] = []
    for sf, mn, ms in settings:
        boxes = face_cascade.detectMultiScale(gray, scaleFactor=sf, minNeighbors=mn, minSize=(ms, ms))
        if len(boxes) > 0:
            all_boxes.extend(list(boxes))
            break  # early exit once we have detections
    return all_boxes


def crop_with_margin(rgb: np.ndarray, box: Tuple[int, int, int, int], margin: float = 0.15) -> np.ndarray:
    h, w, _ = rgb.shape
    x, y, bw, bh = box
    mx = int(bw * margin)
    my = int(bh * margin)
    x1 = max(0, x - mx)
    y1 = max(0, y - my)
    x2 = min(w, x + bw + mx)
    y2 = min(h, y + bh + my)
    return rgb[y1:y2, x1:x2]


def parse_color(name: str) -> Tuple[int, int, int]:
    name = (name or '').lower()
    if name == 'blue':
        return (255, 0, 0)  # BGR
    return (0, 255, 0)  # default green


def main():
    parser = argparse.ArgumentParser(description="Realtime pain recognition with face detection and overlay")
    parser.add_argument("--model", type=str, default="pain_detection_model.pth")
    parser.add_argument("--image_size", type=int, default=224)
    parser.add_argument("--camera", type=int, default=0)
    parser.add_argument("--fps_limit", type=float, default=30.0)
    parser.add_argument("--min_face_size", type=int, default=96)
    parser.add_argument("--smooth_alpha", type=float, default=0.4)
    parser.add_argument("--hold_frames", type=int, default=10)
    parser.add_argument("--border_color", type=str, default="green")
    parser.add_argument("--border_thickness", type=int, default=2)
    args = parser.parse_args()

    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    try:
        torch.set_float32_matmul_precision("medium")
    except Exception:
        pass
    torch.backends.cudnn.benchmark = True

    # Load model and metadata
    data = torch.load(args.model, map_location="cpu")
    class_names = data.get("class_names", ["Low", "Moderate", "Severe"]) 
    thresholds: Tuple[float, float] = tuple(data.get("thresholds", (1.0, 3.0)))
    normalize_mean = data.get("normalize_mean", [0.485, 0.456, 0.406])
    normalize_std = data.get("normalize_std", [0.229, 0.224, 0.225])
    image_size = int(data.get("image_size", args.image_size))
    # Optional detection/crop metadata to align with training
    det_min_face_size = int(data.get("min_face_size", args.min_face_size))
    crop_margin_meta = float(data.get("face_margin", 0.15))
    
    model = make_model(num_classes=len(class_names))
    model.load_state_dict(data["state_dict"]) 
    model.to(device)
    model.eval()
    
    # Detector and tracker
    tracker = FaceTracker(alpha=args.smooth_alpha, hold_frames=args.hold_frames)
    default_color = parse_color(args.border_color)
    color_map = {
        0: (0, 255, 0),      # Low -> green
        1: (0, 255, 255),    # Moderate -> yellow
        2: (0, 0, 255),      # Severe -> red
    }
    
    # Try default, then Windows backends if needed
    cap = cv2.VideoCapture(args.camera)
    if not cap.isOpened():
        cap = cv2.VideoCapture(args.camera, cv2.CAP_DSHOW)
    if not cap.isOpened():
        cap = cv2.VideoCapture(args.camera, cv2.CAP_MSMF)
    if not cap.isOpened():
        raise RuntimeError("Could not open camera")

    last_time = 0.0
    time_window = 1.0 / max(args.fps_limit, 1e-3)
    font = cv2.FONT_HERSHEY_SIMPLEX

    while True:
        ret, frame = cap.read()
        if not ret:
            break
        now = time.time()
        if now - last_time < time_window:
            # maintain FPS limit
            continue
        last_time = now

        # Detect face(s)
        gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
        faces = detect_faces_multiscale(gray, base_min_size=det_min_face_size, prev_box=tracker.prev_box)
        det = best_centered_box(faces, frame.shape) if faces else None
        box = tracker.update(det)

        label_text = "No face"
        if box is not None:
            x, y, w, h = box
            # Crop with margin and run inference
            rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            roi = crop_with_margin(rgb, box, margin=crop_margin_meta)
            if roi.size > 0:
                resized = cv2.resize(roi, (image_size, image_size), interpolation=cv2.INTER_LINEAR)
                img = torch.from_numpy(resized).permute(2, 0, 1).float() / 255.0
                img = T.Normalize(mean=normalize_mean, std=normalize_std)(img)
                img = img.unsqueeze(0).to(device, non_blocking=True)
                with torch.no_grad():
                    with torch.amp.autocast('cuda', enabled=(device.type == 'cuda')):
                        logits = model(img)
                        probs = torch.softmax(logits, dim=1)[0]
                        pred = int(torch.argmax(probs).item())
                # Far detection visualization if face is small
                is_far = (w < 80)
                pain_text = f"Pain: {class_names[pred]} ({probs[pred].item():.2f})"
                if is_far:
                    label_text = f"Far Detected | {pain_text}"
                    draw_color = (255, 0, 0)  # Blue border for distant detection
                else:
                    label_text = pain_text
                    draw_color = color_map.get(pred, default_color)
                cv2.rectangle(frame, (x, y), (x + w, y + h), draw_color, args.border_thickness)
                cv2.putText(frame, label_text, (x, max(0, y - 10)), font, 0.7, draw_color, 2, cv2.LINE_AA)
        else:
            # Indicate idle state
            cv2.putText(frame, label_text, (10, 30), font, 0.7, (0, 0, 255), 2, cv2.LINE_AA)

        cv2.imshow("PocketPT Pain Recognition (Face)", frame)
        if cv2.waitKey(1) & 0xFF == ord('q'):
            break

    cap.release()
    cv2.destroyAllWindows()


if __name__ == "__main__":
    main()