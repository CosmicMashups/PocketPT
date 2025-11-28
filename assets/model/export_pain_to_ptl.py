"""
Export Pain Recognition Model to PyTorch Lite (.ptl) Format

This script converts the trained pain recognition model (pain_recognition_model.pth)
to PyTorch Lite format for mobile deployment using PyTorch Mobile.

Model specifications:
- Architecture: ResNet18 (default) or EfficientNet-B0 or custom CNN
- Input: 224x224 RGB images
- Classes: 3 (Low, Moderate, Severe)
- Normalization: ImageNet mean/std (mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225])
- Output: Logits for 3 classes (softmax applied post-inference)
"""

import torch
import os
from torch.utils.mobile_optimizer import optimize_for_mobile

# Import model architecture from training script
from pain_train import build_model

def export_pain_model_to_ptl():
    """Convert pain recognition model from .pth to .ptl format"""
    print("=" * 60)
    print("Exporting Pain Recognition Model to PyTorch Lite (.ptl)")
    print("=" * 60)
    
    # 1. Define paths
    repo_root = os.path.dirname(os.path.abspath(__file__))
    model_path = os.path.join(repo_root, "pain_recognition_model.pth")
    
    # Check for alternative locations
    if not os.path.exists(model_path):
        # Try models directory
        models_path = os.path.join(repo_root, "models", "pain_recognition_model.pth")
        if os.path.exists(models_path):
            model_path = models_path
        elif os.path.exists("pain_recognition_model.pth"):
            model_path = "pain_recognition_model.pth"
        else:
            print(f"Error: Could not find model file at {model_path}")
            print("Please ensure pain_recognition_model.pth exists in assets/model/ or models/ directory")
            return
    
    print(f"Loading model from: {model_path}")
    
    # 2. Load the saved model checkpoint
    try:
        checkpoint = torch.load(model_path, map_location='cpu')
        print("Model checkpoint loaded successfully")
    except Exception as e:
        print(f"Error loading model checkpoint: {e}")
        return
    
    # 3. Extract model architecture information
    # Default to ResNet18 (as per pain_train.py default)
    model_name = checkpoint.get('model_architecture', 'resnet18')
    num_classes = checkpoint.get('num_classes', 3)
    
    print(f"Model architecture: {model_name}")
    print(f"Number of classes: {num_classes}")
    
    # 4. Build the model architecture
    try:
        model = build_model(model_name=model_name, num_classes=num_classes, pretrained=False)
        print(f"Model architecture built: {model_name}")
    except Exception as e:
        print(f"Error building model architecture: {e}")
        print("Falling back to ResNet18...")
        model = build_model(model_name='resnet18', num_classes=3, pretrained=False)
    
    # 5. Load model weights
    try:
        if 'model_state_dict' in checkpoint:
            model.load_state_dict(checkpoint['model_state_dict'])
            print("Loaded model_state_dict from checkpoint")
        elif 'state_dict' in checkpoint:
            model.load_state_dict(checkpoint['state_dict'])
            print("Loaded state_dict from checkpoint")
        else:
            # If checkpoint is the model itself
            model.load_state_dict(checkpoint)
            print("Loaded model directly from checkpoint")
    except Exception as e:
        print(f"Error loading model weights: {e}")
        print("Attempting to load as direct model state...")
        try:
            model = checkpoint  # Some saves store the model directly
            if not hasattr(model, 'forward'):
                raise ValueError("Checkpoint does not contain a valid model")
        except:
            print("Failed to load model weights. Please check the checkpoint format.")
            return
    
    # 6. Set model to evaluation mode
    model.eval()
    print("Model set to evaluation mode")
    
    # 7. Create a dummy input for tracing (batch=1, channels=3, height=224, width=224)
    dummy_input = torch.randn(1, 3, 224, 224)
    print(f"Created dummy input tensor with shape: {dummy_input.shape}")
    
    # 8. Trace the model to TorchScript
    print("Tracing model to TorchScript...")
    try:
        with torch.no_grad():
            traced_model = torch.jit.trace(model, dummy_input)
        print("Model traced successfully")
    except Exception as e:
        print(f"Error during tracing: {e}")
        print("Attempting script mode instead...")
        try:
            traced_model = torch.jit.script(model)
            print("Model scripted successfully")
        except Exception as e2:
            print(f"Error during scripting: {e2}")
            return
    
    # Verify traced model works
    print("Verifying traced model...")
    try:
        with torch.no_grad():
            test_output = traced_model(dummy_input)
        print(f"Test inference successful. Output shape: {test_output.shape}")
        print(f"Output sample: {test_output[0, :3]}")
    except Exception as e:
        print(f"Error verifying traced model: {e}")
        return
    
    # 9. Optimize for mobile
    print("Optimizing model for mobile...")
    try:
        optimized_model = optimize_for_mobile(traced_model)
        print("Model optimized for mobile")
    except Exception as e:
        print(f"Error during mobile optimization: {e}")
        print("Continuing without optimization...")
        optimized_model = traced_model
    
    # 10. Save for Lite Interpreter
    output_path = os.path.join(repo_root, "pain_recognition_model.ptl")
    print(f"Saving for Lite Interpreter to: {output_path}")
    try:
        optimized_model._save_for_lite_interpreter(output_path)
        file_size = os.path.getsize(output_path) / (1024 * 1024)  # Size in MB
        print("=" * 60)
        print(f"SUCCESS! Model saved to: {os.path.abspath(output_path)}")
        print(f"File size: {file_size:.2f} MB")
        print("=" * 60)
        print("\nNext steps:")
        print("1. Verify the .ptl file exists in assets/model/ directory")
        print("2. Update pubspec.yaml to include the asset")
        print("3. Update FacialPainRecognitionService to use PyTorch Mobile")
        print("=" * 60)
    except Exception as e:
        print(f"Error saving for lite interpreter: {e}")
        print("\nTrying alternative save method...")
        try:
            # Alternative: Save as regular TorchScript and optimize later
            ts_path = output_path.replace('.ptl', '_temp.pt')
            torch.jit.save(optimized_model, ts_path)
            print(f"Saved as TorchScript to: {ts_path}")
            print("You may need to manually convert this to .ptl format")
        except Exception as e2:
            print(f"Alternative save also failed: {e2}")

if __name__ == "__main__":
    export_pain_model_to_ptl()




