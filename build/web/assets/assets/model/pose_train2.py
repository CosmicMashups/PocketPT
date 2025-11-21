#!/usr/bin/env python3
"""
Ultra-Fast YOLO11s-pose Fine-tuning - Maximum Speed
===================================================
This script fine-tunes YOLO11s-pose (smaller model) for ultra-fast training
while still achieving thesis-worthy results.

Key optimizations:
- YOLO11s-pose (smaller, faster model)
- Minimal epochs for fine-tuning
- Optimized for speed over perfection
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
    print("Ultra-Fast YOLO11s-pose Fine-tuning - Maximum Speed")
    print("=" * 60)
    print("Fine-tuning YOLO11s-pose for ultra-fast training")
    print("Expected results: 65-75% mAP@50 (still thesis worthy!)")
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
    
    print("Starting ultra-fast fine-tuning...")
    print("=" * 50)
    
    # Initialize model (YOLO11s-pose is much smaller and faster)
    model = YOLO('yolo11s-pose.pt')  # Load pre-trained YOLO11s-pose
    
    # Ultra-fast training configuration
    training_config = {
        'data': 'coco-pose.yaml',  # COCO pose dataset
        'epochs': 20,              # Very few epochs for fine-tuning
        'batch': 64,               # Large batch size for speed
        'imgsz': 320,             # Small image size for maximum speed
        'device': device,
        'project': 'ultra_fast_training',
        'name': 'yolo11s_pose_ultra_fast',
        'exist_ok': True,
        'save': True,
        'save_period': 5,          # Save frequently
        'patience': 8,             # Early stopping
        'lr0': 0.01,              # Higher learning rate
        'lrf': 0.1,               # Final learning rate factor
        'momentum': 0.937,        # SGD momentum
        'weight_decay': 0.0005,   # Weight decay
        'warmup_epochs': 1,       # Minimal warmup
        'warmup_momentum': 0.8,   # Warmup momentum
        'warmup_bias_lr': 0.1,    # Warmup bias learning rate
        'box': 7.5,               # Box loss gain
        'cls': 0.5,               # Classification loss gain
        'pose': 12.0,             # Pose loss gain
        'kobj': 1.0,             # Keypoint object loss gain
        'dfl': 1.5,              # DFL loss gain
        'hsv_h': 0.0,            # No augmentation for speed
        'hsv_s': 0.0,            # No augmentation for speed
        'hsv_v': 0.0,            # No augmentation for speed
        'degrees': 0.0,          # No rotation
        'translate': 0.0,        # No translation
        'scale': 0.0,            # No scaling
        'shear': 0.0,            # No shear
        'perspective': 0.0,      # No perspective
        'flipud': 0.0,           # No flip up-down
        'fliplr': 0.0,           # No flip left-right
        'mosaic': 0.0,           # No mosaic
        'mixup': 0.0,            # No mixup
        'copy_paste': 0.0,       # No copy-paste
        'auto_augment': 'none',  # No auto augmentation
        'erasing': 0.0,          # No random erasing
        'workers': 16,           # More workers
        'amp': True,             # Mixed precision
        'cache': True,           # Cache images
        'close_mosaic': 0,       # No mosaic at all
    }
    
    print("Ultra-Fast Training Configuration:")
    print(f"- Model: YOLO11s-pose (smaller, faster)")
    print(f"- Epochs: {training_config['epochs']} (minimal for fine-tuning)")
    print(f"- Batch size: {training_config['batch']} (large for speed)")
    print(f"- Image size: {training_config['imgsz']} (small for speed)")
    print(f"- Device: {training_config['device']}")
    print(f"- Learning rate: {training_config['lr0']} (high for fine-tuning)")
    print(f"- Augmentations: NONE (for maximum speed)")
    print("=" * 50)
    
    # Start training
    start_time = time.time()
    
    try:
        results = model.train(**training_config)
        
        training_time = time.time() - start_time
        hours = training_time // 3600
        minutes = (training_time % 3600) // 60
        
        print("=" * 50)
        print("ULTRA-FAST TRAINING COMPLETED SUCCESSFULLY!")
        print("=" * 50)
        print(f"Training time: {hours:.0f}h {minutes:.0f}m")
        print(f"Total epochs: {training_config['epochs']}")
        print(f"Model saved to: ultra_fast_training/yolo11s_pose_ultra_fast/")
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
        print("Expected performance: 65-75% mAP@50 (thesis worthy)")
        
    except Exception as e:
        print(f"Training failed with error: {e}")
        print("Check the error message above for details.")
        return False
    
    return True

if __name__ == "__main__":
    success = main()
    if success:
        print("\n✓ Ultra-fast training completed successfully!")
    else:
        print("\n✗ Training failed!")
        sys.exit(1)
