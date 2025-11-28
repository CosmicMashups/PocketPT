#!/usr/bin/env python3
"""
Test Pain Recognition Model with OpenCV
========================================

This script tests the pain_recognition_model.ptl using OpenCV for:
- Webcam video capture
- Image file loading
- Real-time face detection and pain recognition
- Visualization of results

Model specifications:
- Architecture: ResNet18 (default)
- Input: 224x224 RGB images
- Classes: 3 (Low, Moderate, Severe)
- Normalization: ImageNet mean/std (mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225])
- Output: Logits for 3 classes (softmax applied post-inference)
"""

import os
import sys
import cv2
import numpy as np
import torch
import torch.nn.functional as F
from pathlib import Path

# Add parent directory to path for imports
sys.path.append(str(Path(__file__).parent))

try:
    from pain_train import build_model
except ImportError:
    print("Warning: Could not import build_model from pain_train.py")
    print("Model architecture will need to be specified manually")
    build_model = None

# Model configuration (aligned with training code)
INPUT_SIZE = 224
CLASS_NAMES = ['Low', 'Moderate', 'Severe']
NORMALIZE_MEAN = [0.485, 0.456, 0.406]
NORMALIZE_STD = [0.229, 0.224, 0.225]

# Face detection using OpenCV Haar Cascade
FACE_CASCADE = None

def load_face_cascade():
    """Load OpenCV face detection cascade"""
    global FACE_CASCADE
    if FACE_CASCADE is None:
        # Try to find the cascade file
        cascade_paths = [
            cv2.data.haarcascades + 'haarcascade_frontalface_default.xml',
            'haarcascade_frontalface_default.xml',
            '/usr/share/opencv4/haarcascades/haarcascade_frontalface_default.xml',
        ]
        
        for path in cascade_paths:
            if os.path.exists(path):
                FACE_CASCADE = cv2.CascadeClassifier(path)
                if not FACE_CASCADE.empty():
                    print(f"✓ Loaded face cascade from: {path}")
                    return True
        
        print("✗ Warning: Could not load face cascade. Face detection disabled.")
        return False
    return True

def detect_faces(image):
    """Detect faces in image using OpenCV"""
    if FACE_CASCADE is None:
        return []
    
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    faces = FACE_CASCADE.detectMultiScale(
        gray,
        scaleFactor=1.1,
        minNeighbors=5,
        minSize=(96, 96)  # Minimum face size (aligned with training)
    )
    return faces

def preprocess_image(image, face_rect=None):
    """
    Preprocess image for model inference
    
    Args:
        image: BGR image from OpenCV
        face_rect: Optional (x, y, w, h) face rectangle to crop
    
    Returns:
        Preprocessed tensor ready for model input
    """
    # Convert BGR to RGB
    rgb_image = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
    
    # Crop face if provided
    if face_rect is not None:
        x, y, w, h = face_rect
        # Add margin (15% as per training code)
        margin = 0.15
        margin_x = int(w * margin)
        margin_y = int(h * margin)
        x1 = max(0, x - margin_x)
        y1 = max(0, y - margin_y)
        x2 = min(image.shape[1], x + w + margin_x)
        y2 = min(image.shape[0], y + h + margin_y)
        rgb_image = rgb_image[y1:y2, x1:x2]
    
    # Resize to model input size
    rgb_image = cv2.resize(rgb_image, (INPUT_SIZE, INPUT_SIZE), interpolation=cv2.INTER_LINEAR)
    
    # Convert to float and normalize to [0, 1]
    rgb_image = rgb_image.astype(np.float32) / 255.0
    
    # Apply ImageNet normalization
    mean = np.array(NORMALIZE_MEAN, dtype=np.float32)
    std = np.array(NORMALIZE_STD, dtype=np.float32)
    rgb_image = (rgb_image - mean) / std
    
    # Convert to tensor: (H, W, C) -> (C, H, W)
    tensor = torch.from_numpy(rgb_image.transpose(2, 0, 1))
    
    # Add batch dimension: (C, H, W) -> (1, C, H, W)
    tensor = tensor.unsqueeze(0)
    
    return tensor

def load_model(model_path):
    """
    Load pain recognition model from .ptl or .pth file
    
    Args:
        model_path: Path to model file
    
    Returns:
        Loaded model in evaluation mode
    """
    print(f"Loading model from: {model_path}")
    
    if not os.path.exists(model_path):
        raise FileNotFoundError(f"Model file not found: {model_path}")
    
    model = None
    
    # Try loading as .ptl (PyTorch Lite) first
    if model_path.endswith('.ptl'):
        try:
            print("Attempting to load as PyTorch Lite (.ptl)...")
            model = torch.jit.load(model_path, map_location='cpu')
            model.eval()
            print("✓ Model loaded successfully as PyTorch Lite")
            return model
        except Exception as e:
            print(f"✗ Failed to load as .ptl: {e}")
            print("Attempting to load as .pth checkpoint...")
    
    # Try loading as .pth checkpoint
    if model_path.endswith('.pth'):
        try:
            checkpoint = torch.load(model_path, map_location='cpu')
            
            # Extract model architecture info
            if isinstance(checkpoint, dict):
                model_name = checkpoint.get('model_architecture', 'resnet18')
                num_classes = checkpoint.get('num_classes', 3)
            else:
                # Fallback to defaults
                model_name = 'resnet18'
                num_classes = 3
            
            print(f"Model architecture: {model_name}, Classes: {num_classes}")
            
            # Build model architecture
            if build_model is not None:
                model = build_model(model_name=model_name, num_classes=num_classes, pretrained=False)
            else:
                # Fallback: try to load directly if it's a traced model
                if hasattr(checkpoint, 'forward'):
                    model = checkpoint
                else:
                    raise ValueError("Cannot build model without build_model function")
            
            # Load weights
            if 'model_state_dict' in checkpoint:
                model.load_state_dict(checkpoint['model_state_dict'])
            elif 'state_dict' in checkpoint:
                model.load_state_dict(checkpoint['state_dict'])
            elif isinstance(checkpoint, dict) and 'model_state_dict' not in checkpoint:
                # Try loading as direct state dict
                try:
                    model.load_state_dict(checkpoint)
                except:
                    pass
            
            model.eval()
            print("✓ Model loaded successfully from .pth checkpoint")
            return model
        except Exception as e:
            print(f"✗ Failed to load as .pth: {e}")
            raise
    
    raise ValueError(f"Unsupported model format: {model_path}")

def run_inference(model, image_tensor):
    """
    Run inference on preprocessed image tensor
    
    Args:
        model: Loaded model
        image_tensor: Preprocessed image tensor (1, 3, 224, 224)
    
    Returns:
        Dictionary with predictions and probabilities
    """
    with torch.no_grad():
        # Run inference
        output = model(image_tensor)
        
        # Apply softmax to get probabilities
        probabilities = F.softmax(output, dim=1)
        
        # Get predicted class
        predicted_class = torch.argmax(probabilities, dim=1).item()
        confidence = probabilities[0, predicted_class].item()
        
        # Get all class probabilities
        probs = probabilities[0].cpu().numpy()
        
        return {
            'predicted_class': predicted_class,
            'predicted_label': CLASS_NAMES[predicted_class],
            'confidence': confidence,
            'probabilities': {
                CLASS_NAMES[i]: probs[i] for i in range(len(CLASS_NAMES))
            },
            'raw_logits': output[0].cpu().numpy()
        }

def draw_results(image, result, face_rect=None):
    """
    Draw inference results on image
    
    Args:
        image: BGR image
        result: Inference result dictionary
        face_rect: Optional face rectangle to draw
    """
    # Draw face rectangle if provided
    if face_rect is not None:
        x, y, w, h = face_rect
        cv2.rectangle(image, (x, y), (x + w, y + h), (0, 255, 0), 2)
    
    # Draw prediction text
    label = result['predicted_label']
    confidence = result['confidence']
    text = f"{label}: {confidence:.2%}"
    
    # Choose color based on pain level
    if label == 'Low':
        color = (0, 255, 0)  # Green
    elif label == 'Moderate':
        color = (0, 165, 255)  # Orange
    else:  # Severe
        color = (0, 0, 255)  # Red
    
    # Draw text background
    font = cv2.FONT_HERSHEY_SIMPLEX
    font_scale = 0.7
    thickness = 2
    (text_width, text_height), baseline = cv2.getTextSize(text, font, font_scale, thickness)
    
    # Position text at top-left
    text_x = 10
    text_y = 30
    
    # Draw background rectangle
    cv2.rectangle(
        image,
        (text_x - 5, text_y - text_height - 5),
        (text_x + text_width + 5, text_y + baseline + 5),
        (0, 0, 0),
        -1
    )
    
    # Draw text
    cv2.putText(image, text, (text_x, text_y), font, font_scale, color, thickness)
    
    # Draw probability bars
    y_offset = 50
    for i, (class_name, prob) in enumerate(result['probabilities'].items()):
        bar_text = f"{class_name}: {prob:.2%}"
        bar_width = int(prob * 200)
        
        # Bar color
        if class_name == 'Low':
            bar_color = (0, 255, 0)
        elif class_name == 'Moderate':
            bar_color = (0, 165, 255)
        else:
            bar_color = (0, 0, 255)
        
        # Draw bar background
        cv2.rectangle(image, (text_x, y_offset + i * 25), (text_x + 200, y_offset + i * 25 + 20), (50, 50, 50), -1)
        # Draw bar
        cv2.rectangle(image, (text_x, y_offset + i * 25), (text_x + bar_width, y_offset + i * 25 + 20), bar_color, -1)
        # Draw text
        cv2.putText(image, bar_text, (text_x + 5, y_offset + i * 25 + 15), font, 0.5, (255, 255, 255), 1)

def test_webcam(model_path):
    """Test model with webcam video feed"""
    print("=" * 60)
    print("Testing Pain Recognition Model with Webcam")
    print("=" * 60)
    print("Press 'q' to quit, 's' to save current frame")
    
    # Load model
    model = load_model(model_path)
    
    # Load face cascade
    load_face_cascade()
    
    # Open webcam
    cap = cv2.VideoCapture(0)
    if not cap.isOpened():
        print("✗ Error: Could not open webcam")
        return
    
    print("✓ Webcam opened successfully")
    print("Starting video feed...")
    
    frame_count = 0
    while True:
        ret, frame = cap.read()
        if not ret:
            print("✗ Failed to read frame")
            break
        
        frame_count += 1
        
        # Detect faces
        faces = detect_faces(frame)
        
        # Process first face if detected
        if len(faces) > 0:
            face_rect = faces[0]  # Use first detected face
            x, y, w, h = face_rect
            
            # Preprocess image
            image_tensor = preprocess_image(frame, face_rect)
            
            # Run inference
            result = run_inference(model, image_tensor)
            
            # Draw results
            draw_results(frame, result, face_rect)
            
            # Print result every 30 frames
            if frame_count % 30 == 0:
                print(f"Frame {frame_count}: {result['predicted_label']} (confidence: {result['confidence']:.2%})")
        else:
            # No face detected
            cv2.putText(frame, "No face detected", (10, 30), 
                       cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 0, 255), 2)
        
        # Display frame
        cv2.imshow('Pain Recognition Test', frame)
        
        # Handle key presses
        key = cv2.waitKey(1) & 0xFF
        if key == ord('q'):
            break
        elif key == ord('s'):
            # Save current frame
            filename = f"test_frame_{frame_count}.jpg"
            cv2.imwrite(filename, frame)
            print(f"Saved frame to: {filename}")
    
    cap.release()
    cv2.destroyAllWindows()
    print("Webcam test completed")

def test_image_file(model_path, image_path):
    """Test model with a single image file"""
    print("=" * 60)
    print(f"Testing Pain Recognition Model with Image: {image_path}")
    print("=" * 60)
    
    # Load model
    model = load_model(model_path)
    
    # Load face cascade
    load_face_cascade()
    
    # Load image
    if not os.path.exists(image_path):
        print(f"✗ Error: Image file not found: {image_path}")
        return
    
    image = cv2.imread(image_path)
    if image is None:
        print(f"✗ Error: Could not load image: {image_path}")
        return
    
    print(f"✓ Image loaded: {image.shape[1]}x{image.shape[0]}")
    
    # Detect faces
    faces = detect_faces(image)
    print(f"Detected {len(faces)} face(s)")
    
    if len(faces) == 0:
        print("No face detected. Processing full image...")
        # Process full image
        image_tensor = preprocess_image(image)
        result = run_inference(model, image_tensor)
        draw_results(image, result)
    else:
        # Process each detected face
        for i, face_rect in enumerate(faces):
            print(f"\nProcessing face {i+1}...")
            image_tensor = preprocess_image(image, face_rect)
            result = run_inference(model, image_tensor)
            draw_results(image, result, face_rect)
            
            # Print results
            print(f"Prediction: {result['predicted_label']}")
            print(f"Confidence: {result['confidence']:.2%}")
            print("Probabilities:")
            for class_name, prob in result['probabilities'].items():
                print(f"  {class_name}: {prob:.2%}")
    
    # Display result
    cv2.imshow('Pain Recognition Result', image)
    print("\nPress any key to close...")
    cv2.waitKey(0)
    cv2.destroyAllWindows()
    
    # Save result
    output_path = image_path.replace('.', '_result.')
    cv2.imwrite(output_path, image)
    print(f"Result saved to: {output_path}")

def main():
    """Main function"""
    # Get model path
    repo_root = Path(__file__).parent
    model_path = repo_root / "pain_recognition_model.ptl"
    
    # Try alternative paths
    if not model_path.exists():
        alt_paths = [
            repo_root / "pain_recognition_model.pth",
            repo_root / "models" / "pain_recognition_model.ptl",
            repo_root / "models" / "pain_recognition_model.pth",
        ]
        for alt_path in alt_paths:
            if alt_path.exists():
                model_path = alt_path
                break
    
    if not model_path.exists():
        print("✗ Error: Could not find pain recognition model")
        print("Please ensure pain_recognition_model.ptl or .pth exists in assets/model/")
        return
    
    print(f"Using model: {model_path}")
    
    # Check command line arguments
    if len(sys.argv) > 1:
        # Test with image file
        image_path = sys.argv[1]
        test_image_file(str(model_path), image_path)
    else:
        # Test with webcam
        test_webcam(str(model_path))

if __name__ == "__main__":
    main()

