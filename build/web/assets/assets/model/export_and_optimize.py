import torch
from ultralytics import YOLO
import os
from torch.utils.mobile_optimizer import optimize_for_mobile

def export_and_optimize():
    print("=" * 50)
    print("Exporting and Optimizing Model for Android Lite")
    print("=" * 50)

    # 1. Define paths
    # Assuming the best model is in the standard location from previous training
    # Adjust this path if your best.pt is elsewhere
    model_path = "ultra_fast_training/yolo11s_pose_ultra_fast/weights/best.pt" 
    if not os.path.exists(model_path):
        # Fallback to looking in current dir or assets
        if os.path.exists("best.pt"):
            model_path = "best.pt"
        elif os.path.exists("pose_estimation_model.pt"):
            model_path = "pose_estimation_model.pt"
        else:
            print(f"Error: Could not find source model at {model_path}")
            return

    print(f"Loading model from: {model_path}")
    
    # 2. Load YOLO model
    try:
        model = YOLO(model_path)
    except Exception as e:
        print(f"Error loading YOLO model: {e}")
        return

    # 3. Export to TorchScript using Ultralytics
    # This handles the complex YOLO architecture and post-processing
    print("Exporting to TorchScript...")
    try:
        # Export to torchscript
        # imgsz=320 matches our Flutter implementation
        exported_path = model.export(format="torchscript", imgsz=320, optimize=True)
        print(f"Exported to: {exported_path}")
    except Exception as e:
        print(f"Error during export: {e}")
        return

    # 4. Load the TorchScript model
    print("Loading TorchScript model for optimization...")
    try:
        ts_model = torch.jit.load(exported_path)
        ts_model.eval()
    except Exception as e:
        print(f"Error loading TorchScript model: {e}")
        return

    # 5. Optimize for Mobile
    print("Running optimize_for_mobile...")
    try:
        optimized_model = optimize_for_mobile(ts_model)
    except Exception as e:
        print(f"Error during optimization: {e}")
        return

    # 6. Save for Lite Interpreter
    # CRITICAL STEP: This creates the .ptl file required by pytorch_android_lite
    output_path = "pose_model.ptl"
    print(f"Saving for Lite Interpreter to: {output_path}")
    try:
        optimized_model._save_for_lite_interpreter(output_path)
        print("=" * 50)
        print(f"SUCCESS! Model saved to: {os.path.abspath(output_path)}")
        print("Copy this file to your assets/model/ directory.")
        print("=" * 50)
    except Exception as e:
        print(f"Error saving for lite interpreter: {e}")

if __name__ == "__main__":
    export_and_optimize()
