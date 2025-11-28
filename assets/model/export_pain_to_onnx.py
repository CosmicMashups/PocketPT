"""
Export Pain Recognition Model to ONNX Format

This script exports the trained PyTorch pain recognition model to ONNX format
for mobile deployment via ONNX Runtime.

Based on pain_train.py:
- Model architecture: ResNet18 or EfficientNet-B0
- Input size: 224x224 RGB images
- Output: 3-class logits (Low, Moderate, Severe)
- Normalization: ImageNet mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225]
"""

import os
import torch
import torch.onnx
from pain_train import build_model, ResNetWrapper, EfficientNetWrapper

def export_pain_model_to_onnx(
    model_path='models/pain_classification_model.pth',
    output_path='pain_recognition_model.onnx',
    model_name='resnet18',
    input_size=(224, 224),
    num_classes=3
):
    """
    Export PyTorch pain recognition model to ONNX format.
    
    Args:
        model_path: Path to trained PyTorch model (.pth file)
        output_path: Output ONNX model path
        model_name: Model architecture ('resnet18', 'efficientnet_b0', or 'custom')
        input_size: Input image size (height, width)
        num_classes: Number of output classes
    """
    print("=" * 60)
    print("Pain Recognition Model ONNX Export")
    print("=" * 60)
    
    # Check if model file exists
    if not os.path.exists(model_path):
        print(f"Error: Model file not found: {model_path}")
        print("Please train the model first using pain_train.py")
        return False
    
    # Load model checkpoint
    print(f"\nLoading model from: {model_path}")
    try:
        checkpoint = torch.load(model_path, map_location='cpu')
        model_architecture = checkpoint.get('model_architecture', model_name)
        print(f"Model architecture from checkpoint: {model_architecture}")
    except Exception as e:
        print(f"Error loading checkpoint: {e}")
        return False
    
    # Build model matching training architecture
    print(f"\nBuilding model: {model_architecture}")
    try:
        model = build_model(model_architecture, num_classes=num_classes, pretrained=False)
        model.load_state_dict(checkpoint['model_state_dict'])
        model.eval()
        print("Model loaded successfully")
    except Exception as e:
        print(f"Error building/loading model: {e}")
        return False
    
    # Create dummy input for export (batch=1, channels=3, height=224, width=224)
    dummy_input = torch.randn(1, 3, input_size[0], input_size[1])
    print(f"\nDummy input shape: {dummy_input.shape}")
    
    # Verify model forward pass
    print("Verifying model forward pass...")
    try:
        with torch.no_grad():
            output = model(dummy_input)
            print(f"Model output shape: {output.shape}")
            print(f"Model output (logits): {output[0]}")
            
            # Verify output has correct number of classes
            if output.shape[1] != num_classes:
                print(f"Warning: Output shape {output.shape} doesn't match expected classes {num_classes}")
                return False
    except Exception as e:
        print(f"Error in model forward pass: {e}")
        return False
    
    # Export to ONNX
    print(f"\nExporting to ONNX: {output_path}")
    try:
        torch.onnx.export(
            model,
            dummy_input,
            output_path,
            export_params=True,
            opset_version=11,  # ONNX opset version (compatible with ONNX Runtime)
            do_constant_folding=True,
            input_names=['input'],  # Input name for ONNX Runtime
            output_names=['output'],  # Output name
            dynamic_axes={
                'input': {0: 'batch_size'},  # Allow variable batch size
                'output': {0: 'batch_size'}
            },
            verbose=False
        )
        print(f"✅ Model exported successfully to: {output_path}")
    except Exception as e:
        print(f"Error exporting to ONNX: {e}")
        return False
    
    # Verify exported ONNX model
    print("\nVerifying exported ONNX model...")
    try:
        import onnx
        onnx_model = onnx.load(output_path)
        onnx.checker.check_model(onnx_model)
        print("✅ ONNX model validation passed")
        
        # Print model info
        print("\nModel Information:")
        print(f"  Input shape: {[input.dim for input in onnx_model.graph.input]}")
        print(f"  Output shape: {[output.dim for output in onnx_model.graph.output]}")
        
        # Get input/output shapes
        input_shape = None
        output_shape = None
        for input_tensor in onnx_model.graph.input:
            if input_tensor.name == 'input':
                input_shape = [dim.dim_value for dim in input_tensor.type.tensor_type.shape.dim]
        for output_tensor in onnx_model.graph.output:
            if output_tensor.name == 'output':
                output_shape = [dim.dim_value for dim in output_tensor.type.tensor_type.shape.dim]
        
        print(f"  Input: {input_shape}")
        print(f"  Output: {output_shape}")
        
        # Verify shapes
        expected_input = [1, 3, input_size[0], input_size[1]]
        expected_output = [1, num_classes]
        
        if input_shape != expected_input:
            print(f"⚠️  Warning: Input shape {input_shape} doesn't match expected {expected_input}")
        else:
            print(f"✅ Input shape matches expected: {expected_input}")
        
        if output_shape != expected_output:
            print(f"⚠️  Warning: Output shape {output_shape} doesn't match expected {expected_output}")
        else:
            print(f"✅ Output shape matches expected: {expected_output}")
        
    except ImportError:
        print("⚠️  ONNX package not available - skipping verification")
        print("   Install with: pip install onnx")
    except Exception as e:
        print(f"⚠️  Error verifying ONNX model: {e}")
    
    print("\n" + "=" * 60)
    print("Export Complete!")
    print(f"Copy {output_path} to assets/model/ in your Flutter project")
    print("=" * 60)
    
    return True

if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description='Export pain recognition model to ONNX')
    parser.add_argument('--model', type=str, default='models/pain_classification_model.pth',
                        help='Path to trained PyTorch model')
    parser.add_argument('--output', type=str, default='pain_recognition_model.onnx',
                        help='Output ONNX model path')
    parser.add_argument('--model-name', type=str, default='resnet18',
                        choices=['resnet18', 'efficientnet_b0', 'custom'],
                        help='Model architecture name')
    parser.add_argument('--input-size', type=int, nargs=2, default=[224, 224],
                        metavar=('HEIGHT', 'WIDTH'),
                        help='Input image size (default: 224 224)')
    
    args = parser.parse_args()
    
    success = export_pain_model_to_onnx(
        model_path=args.model,
        output_path=args.output,
        model_name=args.model_name,
        input_size=tuple(args.input_size),
        num_classes=3
    )
    
    exit(0 if success else 1)





