#!/usr/bin/env python3
"""
Quick Model Test
================
Simple test to verify the trained model works correctly
"""

import sys
from pathlib import Path

# Add src to path for imports
sys.path.append(str(Path(__file__).parent))

try:
    from ultralytics import YOLO
    import torch
    print("✓ Libraries imported successfully")
except ImportError as e:
    print(f"✗ Error importing libraries: {e}")
    sys.exit(1)

def test_model():
    """Test the trained model"""
    print("=" * 50)
    print("Quick Model Test")
    print("=" * 50)
    
    # Check if model exists
    model_path = "ultra_fast_training/yolo11s_pose_ultra_fast/weights/best.pt"
    if not Path(model_path).exists():
        print(f"✗ Model not found at: {model_path}")
        return False
    
    try:
        # Load model
        print("Loading trained model...")
        model = YOLO(model_path)
        print("✓ Model loaded successfully")
        
        # Test with a simple image (you can replace with any image)
        print("Testing model inference...")
        
        # Create a simple test image (640x640, 3 channels)
        import numpy as np
        test_image = np.random.randint(0, 255, (640, 640, 3), dtype=np.uint8)
        
        # Run inference
        results = model(test_image, verbose=False)
        
        print("✓ Model inference successful")
        print(f"Number of detections: {len(results)}")
        
        if len(results) > 0:
            result = results[0]
            print(f"Keypoints shape: {result.keypoints.data.shape if result.keypoints is not None else 'None'}")
            print(f"Boxes shape: {result.boxes.data.shape if result.boxes is not None else 'None'}")
        
        print("\n✓ Model test completed successfully!")
        return True
        
    except Exception as e:
        print(f"✗ Model test failed: {e}")
        return False

if __name__ == "__main__":
    success = test_model()
    if not success:
        sys.exit(1)
