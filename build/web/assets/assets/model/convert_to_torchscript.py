import torch
from torch.utils.mobile_optimizer import optimize_for_mobile
import os

def convert_model():
    # Define paths
    input_model_path = "pose_estimation_model.pt" # User has .pt file in directory
    output_model_path = "pose_model.ptl"
    
    print(f"Loading model from {input_model_path}...")
    
    try:
        # Load the PyTorch model
        # Note: If the model was saved as a full checkpoint (dictionary), we might need to instantiate the class first.
        # Assuming it's a full model save or the user has the class definition available in this context.
        # If it fails, we might need the model class definition.
        # However, usually for transfer learning/YOLO, people save the whole model.
        model = torch.load(input_model_path, map_location='cpu')
        
        # If model is a dict (checkpoint), extract state_dict (this part depends on how it was saved)
        if isinstance(model, dict) and 'model' in model:
            print("Detected checkpoint dictionary, loading 'model' key...")
            model = model['model']
            
        # Set to eval mode
        if hasattr(model, 'eval'):
            model.eval()
        else:
            print("Warning: Model does not have eval() method. It might be a script or dict.")

        # Create example input (1, 3, 320, 320) as per user spec
        example_input = torch.rand(1, 3, 320, 320)
        
        print("Tracing model...")
        # Trace the model
        traced_script_module = torch.jit.trace(model, example_input)
        
        print("Optimizing for mobile...")
        # Optimize for mobile
        traced_script_module_optimized = optimize_for_mobile(traced_script_module)
        
        # Save
        print(f"Saving to {output_model_path}...")
        traced_script_module_optimized._save_for_lite_interpreter(output_model_path)
        
        print("Conversion successful!")
        
    except Exception as e:
        print(f"Error during conversion: {e}")
        print("\nTroubleshooting tips:")
        print("1. Ensure you have the model class definition available if 'torch.load' requires it.")
        print("2. Check if the input shape (1, 3, 320, 320) matches your model's expectation.")
        print("3. If using Ultralytics YOLO, you might need to use their export script: 'yolo export model=path format=torchscript optimize=True'")

if __name__ == "__main__":
    convert_model()
