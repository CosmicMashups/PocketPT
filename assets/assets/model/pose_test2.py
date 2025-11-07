#!/usr/bin/env python3
"""
Real-time Pose Evaluation with Camera
=====================================
This script evaluates the trained YOLO11s-pose model in real-time
using a camera feed to detect and visualize human poses.

Features:
- Real-time pose detection
- Keypoint visualization
- Performance metrics display
- Arm angle calculation for deltoid assessment
"""

import cv2
import numpy as np
import time
import sys
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

class RealTimePoseEvaluator:
    def __init__(self, model_path="ultra_fast_training/yolo11s_pose_ultra_fast/weights/best.pt"):
        """
        Initialize the real-time pose evaluator
        
        Args:
            model_path: Path to the trained model weights
        """
        self.model_path = model_path
        self.model = None
        self.cap = None
        self.fps_counter = 0
        self.fps_start_time = time.time()
        self.current_fps = 0
        
        # COCO pose keypoint names (17 keypoints)
        self.keypoint_names = [
            'nose', 'left_eye', 'right_eye', 'left_ear', 'right_ear',
            'left_shoulder', 'right_shoulder', 'left_elbow', 'right_elbow',
            'left_wrist', 'right_wrist', 'left_hip', 'right_hip',
            'left_knee', 'right_knee', 'left_ankle', 'right_ankle'
        ]
        
        # Keypoint connections for skeleton drawing
        self.skeleton = [
            [0, 1], [0, 2], [1, 3], [2, 4],  # head
            [5, 6], [5, 7], [7, 9], [6, 8], [8, 10],  # arms
            [5, 11], [6, 12], [11, 12],  # torso
            [11, 13], [13, 15], [12, 14], [14, 16]  # legs
        ]
        
        # Colors for different keypoints
        self.colors = [
            (255, 0, 0), (255, 85, 0), (255, 170, 0), (255, 255, 0),
            (170, 255, 0), (85, 255, 0), (0, 255, 0), (0, 255, 85),
            (0, 255, 170), (0, 255, 255), (0, 170, 255), (0, 85, 255),
            (0, 0, 255), (85, 0, 255), (170, 0, 255), (255, 0, 255),
            (255, 0, 170)
        ]
    
    def load_model(self):
        """Load the trained YOLO model"""
        try:
            print(f"Loading model from: {self.model_path}")
            self.model = YOLO(self.model_path)
            print("✓ Model loaded successfully")
            return True
        except Exception as e:
            print(f"✗ Error loading model: {e}")
            return False
    
    def initialize_camera(self, camera_id=0):
        """Initialize the camera"""
        try:
            self.cap = cv2.VideoCapture(camera_id)
            if not self.cap.isOpened():
                print(f"✗ Could not open camera {camera_id}")
                return False
            
            # Set camera properties
            self.cap.set(cv2.CAP_PROP_FRAME_WIDTH, 640)
            self.cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 480)
            self.cap.set(cv2.CAP_PROP_FPS, 30)
            
            print(f"✓ Camera {camera_id} initialized successfully")
            return True
        except Exception as e:
            print(f"✗ Error initializing camera: {e}")
            return False
    
    def calculate_arm_angle(self, keypoints, arm_side='left'):
        """
        Calculate arm angle for deltoid assessment
        
        Args:
            keypoints: Array of keypoints [x, y, visibility]
            arm_side: 'left' or 'right' arm
        
        Returns:
            angle in degrees, or None if keypoints not visible
        """
        if arm_side == 'left':
            shoulder_idx, elbow_idx, wrist_idx = 5, 7, 9
        else:
            shoulder_idx, elbow_idx, wrist_idx = 6, 8, 10
        
        # Check if all required keypoints are visible
        if (keypoints[shoulder_idx][2] < 0.5 or 
            keypoints[elbow_idx][2] < 0.5 or 
            keypoints[wrist_idx][2] < 0.5):
            return None
        
        # Get keypoint coordinates
        shoulder = keypoints[shoulder_idx][:2]
        elbow = keypoints[elbow_idx][:2]
        wrist = keypoints[wrist_idx][:2]
        
        # Calculate vectors
        vec1 = np.array(elbow) - np.array(shoulder)
        vec2 = np.array(wrist) - np.array(elbow)
        
        # Calculate angle between vectors
        cos_angle = np.dot(vec1, vec2) / (np.linalg.norm(vec1) * np.linalg.norm(vec2))
        cos_angle = np.clip(cos_angle, -1.0, 1.0)  # Clamp to avoid numerical errors
        angle = np.arccos(cos_angle)
        angle_degrees = np.degrees(angle)
        
        return angle_degrees
    
    def draw_pose(self, frame, keypoints):
        """
        Draw pose skeleton on the frame
        
        Args:
            frame: Input frame
            keypoints: Array of keypoints [x, y, visibility]
        
        Returns:
            Frame with pose drawn
        """
        # Draw keypoints
        for i, (x, y, v) in enumerate(keypoints):
            if v > 0.5:  # Only draw visible keypoints
                cv2.circle(frame, (int(x), int(y)), 5, self.colors[i], -1)
                cv2.circle(frame, (int(x), int(y)), 8, (255, 255, 255), 2)
        
        # Draw skeleton
        for connection in self.skeleton:
            pt1_idx, pt2_idx = connection
            if (keypoints[pt1_idx][2] > 0.5 and keypoints[pt2_idx][2] > 0.5):
                pt1 = (int(keypoints[pt1_idx][0]), int(keypoints[pt1_idx][1]))
                pt2 = (int(keypoints[pt2_idx][0]), int(keypoints[pt2_idx][1]))
                cv2.line(frame, pt1, pt2, (0, 255, 0), 2)
        
        return frame
    
    def update_fps(self):
        """Update FPS counter"""
        self.fps_counter += 1
        current_time = time.time()
        if current_time - self.fps_start_time >= 1.0:
            self.current_fps = self.fps_counter
            self.fps_counter = 0
            self.fps_start_time = current_time
    
    def run_evaluation(self):
        """Run real-time pose evaluation"""
        print("=" * 60)
        print("Real-time Pose Evaluation")
        print("=" * 60)
        print("Press 'q' to quit, 's' to save screenshot")
        print("=" * 60)
        
        if not self.load_model():
            return False
        
        if not self.initialize_camera():
            return False
        
        try:
            while True:
                ret, frame = self.cap.read()
                if not ret:
                    print("✗ Failed to read from camera")
                    break
                
                # Run pose detection
                results = self.model(frame, verbose=False)
                
                # Process results
                if results and len(results) > 0:
                    result = results[0]
                    
                    if result.keypoints is not None and len(result.keypoints) > 0:
                        # Get the first person's keypoints
                        keypoints = result.keypoints.data[0].cpu().numpy()
                        
                        # Draw pose
                        frame = self.draw_pose(frame, keypoints)
                        
                        # Calculate arm angles
                        left_angle = self.calculate_arm_angle(keypoints, 'left')
                        right_angle = self.calculate_arm_angle(keypoints, 'right')
                        
                        # Display angles
                        y_offset = 30
                        if left_angle is not None:
                            cv2.putText(frame, f"Left Arm: {left_angle:.1f}°", 
                                      (10, y_offset), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 0), 2)
                            y_offset += 30
                        
                        if right_angle is not None:
                            cv2.putText(frame, f"Right Arm: {right_angle:.1f}°", 
                                      (10, y_offset), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 0), 2)
                            y_offset += 30
                        
                        # Deltoid assessment
                        if left_angle is not None and right_angle is not None:
                            if left_angle < 90 or right_angle < 90:
                                assessment = "Potential Deltoid Issue"
                                color = (0, 0, 255)  # Red
                            else:
                                assessment = "Normal Range"
                                color = (0, 255, 0)  # Green
                            
                            cv2.putText(frame, f"Assessment: {assessment}", 
                                      (10, y_offset), cv2.FONT_HERSHEY_SIMPLEX, 0.7, color, 2)
                
                # Update and display FPS
                self.update_fps()
                cv2.putText(frame, f"FPS: {self.current_fps}", 
                          (frame.shape[1] - 100, 30), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (255, 255, 255), 2)
                
                # Display frame
                cv2.imshow('Real-time Pose Evaluation', frame)
                
                # Handle key presses
                key = cv2.waitKey(1) & 0xFF
                if key == ord('q'):
                    break
                elif key == ord('s'):
                    # Save screenshot
                    timestamp = time.strftime("%Y%m%d_%H%M%S")
                    filename = f"pose_evaluation_{timestamp}.jpg"
                    cv2.imwrite(filename, frame)
                    print(f"Screenshot saved: {filename}")
        
        except KeyboardInterrupt:
            print("\nEvaluation interrupted by user")
        
        finally:
            # Cleanup
            if self.cap:
                self.cap.release()
            cv2.destroyAllWindows()
            print("✓ Camera released and windows closed")
        
        return True

def main():
    """Main function"""
    print("Starting Real-time Pose Evaluation...")
    
    # Check if model exists
    model_path = "ultra_fast_training/yolo11s_pose_ultra_fast/weights/best.pt"
    if not Path(model_path).exists():
        print(f"✗ Model not found at: {model_path}")
        print("Please ensure the model has been trained first.")
        return False
    
    # Create evaluator and run
    evaluator = RealTimePoseEvaluator(model_path)
    success = evaluator.run_evaluation()
    
    if success:
        print("\n✓ Real-time evaluation completed successfully!")
    else:
        print("\n✗ Real-time evaluation failed!")
    
    return success

if __name__ == "__main__":
    success = main()
    if not success:
        sys.exit(1)
