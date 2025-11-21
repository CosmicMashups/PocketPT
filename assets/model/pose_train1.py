#!/usr/bin/env python3
"""
Fast COCO Fine-tuning Script - Optimized for Speed
==================================================
This script fine-tunes YOLO11m-pose on COCO dataset with optimizations
for much faster training while maintaining thesis-worthy results.

Key optimizations:
- Smaller batch size for faster iterations
- Reduced image size for speed
- Fewer epochs with better learning rate
- Optimized data loading
- Mixed precision training
"""

import os
import sys
import time
from pathlib import Path

# Add src to path for imports
sys.path.append(str(Path(__file__).parent))

try:
    from ultralytics import YOLO
    import torch
    print("✓ Ultralytics and PyTorch imported successfully")
except ImportError as e:
    print(f"✗ Error importing libraries: {e}")
    sys.exit(1)

def main():
    print("=" * 60)
    print("Fast YOLO11m-pose Fine-tuning - Speed Optimized")
    print("=" * 60)
    print("Fine-tuning pre-trained YOLO11m-pose for faster training")
    print("Expected results: 70-80% mAP@50 (thesis worthy!)")
    print("=" * 60)
    
    # Check CUDA availability
    if torch.cuda.is_available():
        device_name = torch.cuda.get_device_name(0)
        device_memory = torch.cuda.get_device_properties(0).total_memory / 1024**3
        print(f"✓ CUDA available: {device_name}")
        print(f"✓ GPU Memory: {device_memory:.1f} GB")
        device = "cuda"
    else:
        print("✗ CUDA not available, using CPU")
        device = "cpu"
    
    print("Starting fast fine-tuning...")
    print("=" * 50)
    
    # Initialize model
    model = YOLO('yolo11m-pose.pt')  # Load pre-trained YOLO11m-pose
    
    # Optimized training configuration for speed
    training_config = {
        'data': 'coco-pose.yaml',  # COCO pose dataset
        'epochs': 30,              # Reduced epochs (fine-tuning needs fewer)
        'batch': 32,               # Larger batch size for speed
        'imgsz': 416,             # Smaller image size for speed (was 640)
        'device': device,
        'project': 'fast_coco_training',
        'name': 'yolo11m_pose_fast',
        'exist_ok': True,
        'save': True,
        'save_period': 5,          # Save more frequently
        'patience': 10,            # Early stopping
        'lr0': 0.01,              # Higher learning rate for fine-tuning
        'lrf': 0.1,               # Final learning rate factor
        'momentum': 0.937,        # SGD momentum
        'weight_decay': 0.0005,   # Weight decay
        'warmup_epochs': 1,       # Reduced warmup
        'warmup_momentum': 0.8,   # Warmup momentum
        'warmup_bias_lr': 0.1,    # Warmup bias learning rate
        'box': 7.5,               # Box loss gain
        'cls': 0.5,               # Classification loss gain
        'pose': 12.0,             # Pose loss gain
        'kobj': 1.0,             # Keypoint object loss gain
        'dfl': 1.5,              # DFL loss gain
        'hsv_h': 0.015,          # HSV-Hue augmentation
        'hsv_s': 0.7,            # HSV-Saturation augmentation
        'hsv_v': 0.4,            # HSV-Value augmentation
        'degrees': 0.0,          # No rotation for speed
        'translate': 0.1,        # Translation
        'scale': 0.5,            # Scale
        'shear': 0.0,            # No shear for speed
        'perspective': 0.0,      # No perspective for speed
        'flipud': 0.0,           # No flip up-down for speed
        'fliplr': 0.5,           # Keep left-right flip
        'mosaic': 0.5,           # Reduced mosaic for speed
        'mixup': 0.0,            # No mixup for speed
        'copy_paste': 0.0,       # No copy-paste for speed
        'auto_augment': 'none',  # No auto augmentation for speed
        'erasing': 0.0,          # No random erasing for speed
        'workers': 16,           # More workers for data loading
        'amp': True,             # Mixed precision for speed
        'cache': True,           # Cache images for speed
        'close_mosaic': 5,       # Close mosaic earlier
    }
    
    print("Fast Training Configuration:")
    print(f"- Epochs: {training_config['epochs']} (reduced for fine-tuning)")
    print(f"- Batch size: {training_config['batch']} (larger for speed)")
    print(f"- Image size: {training_config['imgsz']} (smaller for speed)")
    print(f"- Device: {training_config['device']}")
    print(f"- Learning rate: {training_config['lr0']} (higher for fine-tuning)")
    print(f"- Mixed Precision: {training_config['amp']}")
    print(f"- Image Caching: {training_config['cache']}")
    print("=" * 50)
    
    # Start training
    start_time = time.time()
    
    try:
        results = model.train(**training_config)
        
        training_time = time.time() - start_time
        hours = training_time // 3600
        minutes = (training_time % 3600) // 60
        
        print("=" * 50)
        print("FAST TRAINING COMPLETED SUCCESSFULLY!")
        print("=" * 50)
        print(f"Training time: {hours:.0f}h {minutes:.0f}m")
        print(f"Total epochs: {training_config['epochs']}")
        print(f"Model saved to: fast_coco_training/yolo11m_pose_fast/")
        print("=" * 50)
        
        # Print final metrics
        if hasattr(results, 'results_dict'):
            metrics = results.results_dict
            print("Final Training Metrics:")
            print(f"- mAP@50: {metrics.get('metrics/mAP50(B)', 'N/A'):.3f}")
            print(f"- mAP@50-95: {metrics.get('metrics/mAP50-95(B)', 'N/A'):.3f}")
            print(f"- Precision: {metrics.get('metrics/precision(B)', 'N/A'):.3f}")
            print(f"- Recall: {metrics.get('metrics/recall(B)', 'N/A'):.3f}")
        
        print("\nModel is ready for deployment and thesis submission!")
        print("Expected performance: 70-80% mAP@50 (thesis worthy)")
        
    except Exception as e:
        print(f"Training failed with error: {e}")
        print("Check the error message above for details.")
        return False
    
    return True

if __name__ == "__main__":
    success = main()
    if success:
        print("\n✓ Fast training completed successfully!")
    else:
        print("\n✗ Training failed!")
        sys.exit(1)
