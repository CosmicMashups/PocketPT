import os
import json
import math
import argparse
from typing import Tuple, List, Dict

import numpy as np
import torch
import torch.nn as nn
import torch.nn.functional as F
from torch.utils.data import DataLoader, WeightedRandomSampler

from torchvision.models import mobilenet_v3_small
try:
    from torchvision.models import MobileNet_V3_Small_Weights
    DEFAULT_WEIGHTS = MobileNet_V3_Small_Weights.DEFAULT
    USE_NEW_API = True
except Exception:
    DEFAULT_WEIGHTS = None
    USE_NEW_API = False

try:
    from scripts.dataset import (
        build_samples,
        build_transforms,
        PainDataset,
        compute_class_thresholds,
        map_value_to_class,
        stratified_split,
        CLASS_NAMES,
        filter_samples_with_face
    )
except ModuleNotFoundError:
    import sys, os
    sys.path.append(os.path.dirname(__file__))
    from dataset import (
        build_samples,
        build_transforms,
        PainDataset,
        compute_class_thresholds,
        map_value_to_class,
        stratified_split,
        CLASS_NAMES,
        filter_samples_with_face
    )


def set_seed(seed: int = 42):
    import random
    random.seed(seed)
    np.random.seed(seed)
    torch.manual_seed(seed)
    torch.cuda.manual_seed_all(seed)


def confusion_matrix(num_classes: int, y_true: List[int], y_pred: List[int]) -> np.ndarray:
    cm = np.zeros((num_classes, num_classes), dtype=np.int64)
    for t, p in zip(y_true, y_pred):
        cm[t, p] += 1
    return cm


def compute_metrics_from_cm(cm: np.ndarray) -> Dict[str, float]:
    # Overall accuracy
    total = cm.sum()
    correct = np.trace(cm)
    accuracy = float(correct) / float(total) if total > 0 else 0.0

    precision_list = []
    recall_list = []
    f1_list = []
    for c in range(cm.shape[0]):
        tp = cm[c, c]
        fp = cm[:, c].sum() - tp
        fn = cm[c, :].sum() - tp
        precision = float(tp) / float(tp + fp) if (tp + fp) > 0 else 0.0
        recall = float(tp) / float(tp + fn) if (tp + fn) > 0 else 0.0
        f1 = 2 * precision * recall / (precision + recall) if (precision + recall) > 0 else 0.0
        precision_list.append(precision)
        recall_list.append(recall)
        f1_list.append(f1)

    metrics = {
        "accuracy": accuracy,
        "precision_macro": float(np.mean(precision_list)) if precision_list else 0.0,
        "recall_macro": float(np.mean(recall_list)) if recall_list else 0.0,
        "f1_macro": float(np.mean(f1_list)) if f1_list else 0.0,
    }
    return metrics


def make_model(num_classes: int = 3, use_pretrained: bool = True) -> nn.Module:
    if use_pretrained:
        try:
            if USE_NEW_API and DEFAULT_WEIGHTS is not None:
                model = mobilenet_v3_small(weights=DEFAULT_WEIGHTS)
            else:
                model = mobilenet_v3_small(pretrained=True)
        except Exception:
            print("Warning: could not load pretrained weights; initializing randomly.")
            model = mobilenet_v3_small(weights=None)
    else:
        model = mobilenet_v3_small(weights=None)
    # Replace final classifier layer
    in_features = model.classifier[-1].in_features
    model.classifier[-1] = nn.Linear(in_features, num_classes)
    return model


def train_one_epoch(model, loader, optimizer, scaler, device):
    model.train()
    loss_sum = 0.0
    correct = 0
    total = 0
    for images, labels in loader:
        images = images.to(device, non_blocking=True)
        labels = labels.to(device, non_blocking=True)

        optimizer.zero_grad(set_to_none=True)
        with torch.cuda.amp.autocast(enabled=(device.type == 'cuda')):
            logits = model(images)
            loss = F.cross_entropy(logits, labels)
        scaler.scale(loss).backward()
        scaler.step(optimizer)
        scaler.update()

        loss_sum += float(loss.item()) * images.size(0)
        preds = torch.argmax(logits, dim=1)
        correct += int((preds == labels).sum().item())
        total += int(images.size(0))
    return loss_sum / max(total, 1), correct / max(total, 1)


@torch.no_grad()
def evaluate(model, loader, device):
    model.eval()
    y_true = []
    y_pred = []
    for images, labels in loader:
        images = images.to(device, non_blocking=True)
        labels = labels.to(device, non_blocking=True)
        with torch.cuda.amp.autocast(enabled=(device.type == 'cuda')):
            logits = model(images)
        preds = torch.argmax(logits, dim=1)
        y_true.extend(labels.cpu().numpy().tolist())
        y_pred.extend(preds.cpu().numpy().tolist())
    cm = confusion_matrix(3, y_true, y_pred)
    metrics = compute_metrics_from_cm(cm)
    return metrics, cm


def main():
    parser = argparse.ArgumentParser(description="Train facial pain recognition (Low/Moderate/Severe) with MobileNetV3")
    parser.add_argument("--images_root", type=str, default=os.path.join("Images", "Images"))
    parser.add_argument("--labels_root_pspi", type=str, default=os.path.join("Frame_Labels", "Frame_Labels", "PSPI"))
    parser.add_argument("--batch_size", type=int, default=64)
    parser.add_argument("--epochs", type=int, default=15)
    parser.add_argument("--lr", type=float, default=1e-3)
    parser.add_argument("--weight_decay", type=float, default=1e-4)
    parser.add_argument("--image_size", type=int, default=224)
    parser.add_argument("--num_workers", type=int, default=0)
    parser.add_argument("--model_out", type=str, default="pain_detection_model.pth")
    parser.add_argument("--no_pretrained", action="store_true", help="Disable pretrained weights to allow offline training")
    parser.add_argument("--freeze_backbone_epochs", type=int, default=5)
    parser.add_argument('--use_face_crop', action='store_true', help='Crop face region before training/inference')
    parser.add_argument('--discard_nonface', action='store_true', help='Discard samples without detectable face')
    parser.add_argument('--min_face_size', type=int, default=96, help='Minimum face size (pixels) for Haar detection')
    parser.add_argument('--face_margin', type=float, default=0.15, help='Margin around detected face crop')
    parser.add_argument('--save_crops_dir', type=str, default=None, help='Directory to save preprocessed face crops (optional)')
    parser.add_argument('--low_res_aug_p', type=float, default=0.5, help='Probability of low-resolution augmentation in training')
    parser.add_argument('--blur_aug_p', type=float, default=0.3, help='Probability of Gaussian blur augmentation in training')
    parser.add_argument('--early_stop_patience', type=int, default=3, help='Epochs without val F1 improvement before early stop')
    args = parser.parse_args()

    set_seed(42)

    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    torch.backends.cudnn.benchmark = True
    try:
        torch.set_float32_matmul_precision("medium")
    except Exception:
        pass

    print(f"Using device: {device}")
    print(f"Images root: {args.images_root}")
    print(f"Labels root (PSPI): {args.labels_root_pspi}")

    # Build sample list and thresholds
    samples = build_samples(args.images_root, args.labels_root_pspi)
    if args.discard_nonface or args.use_face_crop:
        samples = filter_samples_with_face(samples, min_face_size=args.min_face_size)
    if len(samples) == 0:
        raise RuntimeError("No samples found. Please verify dataset paths.")
    pspi_values = [s.label_value for s in samples]
    t1, t2 = compute_class_thresholds(pspi_values)

    # Map to labels and check distribution; adjust thresholds if degenerate
    labels_all = [map_value_to_class(v, t1, t2) for v in pspi_values]
    counts = [labels_all.count(c) for c in range(3)]
    print(f"Initial class counts (Low/Moderate/Severe): {counts}")
    if any(c == 0 for c in counts):
        # Fallback thresholds typical for PSPI (0-16): Low<=1, Moderate<=3, Severe>3
        t1, t2 = 1.0, 3.0
        labels_all = [map_value_to_class(v, t1, t2) for v in pspi_values]
        counts = [labels_all.count(c) for c in range(3)]
        print(f"Adjusted thresholds to (t1={t1}, t2={t2}). New counts: {counts}")

    # Stratified split
    train_idx, val_idx, test_idx = stratified_split(labels_all, 0.7, 0.2, 0.1, seed=42)
    print(f"Split sizes: train={len(train_idx)}, val={len(val_idx)}, test={len(test_idx)}")

    tf = build_transforms(args.image_size, low_res_aug_p=args.low_res_aug_p, blur_aug_p=args.blur_aug_p)
    train_ds = PainDataset(
    [samples[i] for i in train_idx], thresholds=(t1, t2), transform=tf["train"],
    face_crop=args.use_face_crop, min_face_size=args.min_face_size, face_margin=args.face_margin,
    save_crops_dir=args.save_crops_dir
    ) 
    val_ds = PainDataset(
    [samples[i] for i in val_idx], thresholds=(t1, t2), transform=tf["eval"],
    face_crop=args.use_face_crop, min_face_size=args.min_face_size, face_margin=args.face_margin
    ) 
    test_ds = PainDataset(
    [samples[i] for i in test_idx], thresholds=(t1, t2), transform=tf["eval"],
    face_crop=args.use_face_crop, min_face_size=args.min_face_size, face_margin=args.face_margin
    ) 

    # Weighted sampler for class balance
    train_labels = [labels_all[i] for i in train_idx]
    class_sample_counts = np.array([train_labels.count(c) for c in range(3)], dtype=np.float32)
    class_weights = 1.0 / np.maximum(class_sample_counts, 1.0)
    sample_weights = np.array([class_weights[label] for label in train_labels], dtype=np.float32)
    sampler = WeightedRandomSampler(weights=sample_weights.tolist(), num_samples=len(sample_weights), replacement=True)

    train_loader = DataLoader(train_ds, batch_size=args.batch_size, sampler=sampler, num_workers=args.num_workers, pin_memory=True)
    val_loader = DataLoader(val_ds, batch_size=args.batch_size, shuffle=False, num_workers=args.num_workers, pin_memory=True)
    test_loader = DataLoader(test_ds, batch_size=args.batch_size, shuffle=False, num_workers=args.num_workers, pin_memory=True)
    # Distance-robust evaluation set (applies low-res + blur + low-light)
    distance_test_ds = PainDataset(
        [samples[i] for i in test_idx], thresholds=(t1, t2), transform=tf["eval_distance"],
        face_crop=args.use_face_crop, min_face_size=args.min_face_size, face_margin=args.face_margin
    )
    distance_test_loader = DataLoader(distance_test_ds, batch_size=args.batch_size, shuffle=False, num_workers=args.num_workers, pin_memory=True)

    model = make_model(num_classes=3, use_pretrained=(not args.no_pretrained))
    model.to(device)

    # Freeze backbone initially
    for p in model.features.parameters():
        p.requires_grad = False

    optimizer = torch.optim.AdamW(filter(lambda p: p.requires_grad, model.parameters()), lr=args.lr, weight_decay=args.weight_decay)
    scaler = torch.cuda.amp.GradScaler(enabled=(device.type == 'cuda'))

    best_val_f1 = -1.0
    best_state = None

    # Training with backbone frozen
    for epoch in range(args.freeze_backbone_epochs):
        train_loss, train_acc = train_one_epoch(model, train_loader, optimizer, scaler, device)
        metrics_val, cm_val = evaluate(model, val_loader, device)
        print(f"Epoch {epoch+1}/{args.freeze_backbone_epochs} [Frozen] - loss={train_loss:.4f} acc={train_acc:.4f} val_acc={metrics_val['accuracy']:.4f} val_f1={metrics_val['f1_macro']:.4f}")
        if metrics_val['f1_macro'] > best_val_f1:
            best_val_f1 = metrics_val['f1_macro']
            best_state = {k: v.cpu() if isinstance(v, torch.Tensor) else v for k, v in model.state_dict().items()}

    # Unfreeze backbone for fine-tuning
    for p in model.features.parameters():
        p.requires_grad = True
    optimizer = torch.optim.AdamW(model.parameters(), lr=args.lr * 0.5, weight_decay=args.weight_decay)

    remaining_epochs = args.epochs - args.freeze_backbone_epochs
    no_improve = 0
    for epoch in range(remaining_epochs):
        train_loss, train_acc = train_one_epoch(model, train_loader, optimizer, scaler, device)
        metrics_val, cm_val = evaluate(model, val_loader, device)
        print(f"Epoch {epoch+1}/{remaining_epochs} [Tune] - loss={train_loss:.4f} acc={train_acc:.4f} val_acc={metrics_val['accuracy']:.4f} val_f1={metrics_val['f1_macro']:.4f}")
        if metrics_val['f1_macro'] > best_val_f1:
            best_val_f1 = metrics_val['f1_macro']
            best_state = {k: v.cpu() if isinstance(v, torch.Tensor) else v for k, v in model.state_dict().items()}
            no_improve = 0
        else:
            no_improve += 1
            if no_improve >= args.early_stop_patience:
                print(f"Early stopping triggered (patience={args.early_stop_patience}).")
                break

    if best_state is not None:
        model.load_state_dict(best_state)

    # Final test evaluation
    metrics_test, cm_test = evaluate(model, test_loader, device)
    print("Test metrics:")
    print(json.dumps({
        "accuracy": metrics_test["accuracy"],
        "precision": metrics_test["precision_macro"],
        "recall": metrics_test["recall_macro"],
        "f1": metrics_test["f1_macro"],
    }, indent=2))
    print("Confusion Matrix (rows=true, cols=pred):")
    for row in cm_test:
        print(row.tolist())

    # Distance-robust test evaluation
    metrics_dist, cm_dist = evaluate(model, distance_test_loader, device)
    print("Distance-robust Test metrics:")
    print(json.dumps({
        "accuracy": metrics_dist["accuracy"],
        "precision": metrics_dist["precision_macro"],
        "recall": metrics_dist["recall_macro"],
        "f1": metrics_dist["f1_macro"],
    }, indent=2))
    print("Confusion Matrix (distance test; rows=true, cols=pred):")
    for row in cm_dist:
        print(row.tolist())

    # Save model with metadata
    save_dict = {

         "state_dict": {k: v.cpu() if isinstance(v, torch.Tensor) else v for k, v in model.state_dict().items()},
         "class_names": CLASS_NAMES,
         "thresholds": (t1, t2),
         "image_size": args.image_size,
         "normalize_mean": [0.485, 0.456, 0.406],
         "normalize_std": [0.229, 0.224, 0.225],
         "face_crop_enabled": args.use_face_crop,
         "min_face_size": int(args.min_face_size),
         "face_margin": float(args.face_margin),
        "low_res_aug_p": float(args.low_res_aug_p),
        "blur_aug_p": float(args.blur_aug_p),
        "images_root": args.images_root,
        "labels_root_pspi": args.labels_root_pspi,
        "use_face_crop": args.use_face_crop,
        "early_stop_patience": int(args.early_stop_patience),
     }
    torch.save(save_dict, args.model_out)
    print(f"Saved trained model to {args.model_out}")


if __name__ == "__main__":
    main()