#!/usr/bin/env python3
"""
Simple Camera Test for Iriun Webcam
This script tests camera connection without requiring TensorFlow or the trained model.
"""

import cv2
import time
from datetime import datetime

def test_iriun_camera():
    """
    Test Iriun webcam connection and basic functionality
    """
    print("=== Iriun Webcam Connection Test ===")
    print("This will test your camera connection without requiring the trained model.")
    print("")
    
    # Try different camera indices
    camera_indices = [0, 1, 2, 3, 4, 5]  # Extended range for Iriun
    cap = None
    working_index = None
    
    print("Searching for available cameras...")
    for idx in camera_indices:
        print(f"  Trying camera index {idx}...", end=" ")
        test_cap = cv2.VideoCapture(idx)
        
        if test_cap.isOpened():
            # Try to read a frame
            ret, frame = test_cap.read()
            if ret and frame is not None:
                print("✅ SUCCESS")
                cap = test_cap
                working_index = idx
                break
            else:
                print("❌ Failed to read frame")
                test_cap.release()
        else:
            print("❌ Cannot open")
    
    if cap is None:
        print("\n❌ No working camera found!")
        print("\nTroubleshooting steps:")
        print("1. Make sure Iriun webcam app is running on your phone")
        print("2. Ensure Iriun webcam driver is installed on PC")
        print("3. Check that phone and PC are on the same WiFi network")
        print("4. Try restarting the Iriun app on your phone")
        print("5. Check Windows camera permissions")
        return False
    
    print(f"\n✅ Camera found at index {working_index}")
    
    # Get camera properties
    width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
    height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
    fps = cap.get(cv2.CAP_PROP_FPS)
    
    print(f"Camera resolution: {width}x{height}")
    print(f"Camera FPS: {fps}")
    print("")
    
    # Test face detection
    face_cascade = cv2.CascadeClassifier(cv2.data.haarcascades + 'haarcascade_frontalface_default.xml')
    
    print("Starting camera test...")
    print("Controls:")
    print("  - Press 'q' to quit")
    print("  - Press 's' to save screenshot")
    print("  - Press 'f' to toggle face detection")
    print("  - Press 'i' to show camera info")
    print("")
    
    # Test variables
    frame_count = 0
    start_time = time.time()
    face_detection_enabled = True
    faces_detected = 0
    
    while True:
        ret, frame = cap.read()
        if not ret:
            print("Failed to capture frame")
            break
        
        frame_count += 1
        current_time = time.time()
        elapsed_time = current_time - start_time
        current_fps = frame_count / elapsed_time if elapsed_time > 0 else 0
        
        # Face detection
        if face_detection_enabled:
            gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
            faces = face_cascade.detectMultiScale(gray, 1.1, 4)
            
            for (x, y, w, h) in faces:
                faces_detected += 1
                # Draw rectangle around face
                cv2.rectangle(frame, (x, y), (x+w, y+h), (0, 255, 0), 2)
                cv2.putText(frame, "Face Detected", (x, y-10), 
                           cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 0), 2)
        
        # Add overlay information
        info_text = [
            f"Camera Index: {working_index}",
            f"Resolution: {width}x{height}",
            f"FPS: {current_fps:.1f}",
            f"Frames: {frame_count}",
            f"Faces Detected: {faces_detected}",
            f"Face Detection: {'ON' if face_detection_enabled else 'OFF'}"
        ]
        
        # Draw info on frame
        for i, text in enumerate(info_text):
            cv2.putText(frame, text, (10, 30 + i*25), 
                       cv2.FONT_HERSHEY_SIMPLEX, 0.6, (255, 255, 255), 2)
        
        # Draw controls
        controls = "Controls: 'q'=quit, 's'=screenshot, 'f'=toggle face detection, 'i'=info"
        cv2.putText(frame, controls, (10, height - 20), 
                   cv2.FONT_HERSHEY_SIMPLEX, 0.4, (255, 255, 255), 1)
        
        # Status indicator
        status_color = (0, 255, 0) if len(faces) > 0 else (0, 0, 255)
        cv2.circle(frame, (width - 30, 30), 10, status_color, -1)
        
        # Display frame
        cv2.imshow('Iriun Camera Test', frame)
        
        # Handle key presses
        key = cv2.waitKey(1) & 0xFF
        if key == ord('q'):
            break
        elif key == ord('s'):
            # Save screenshot
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            filename = f"camera_test_{timestamp}.jpg"
            cv2.imwrite(filename, frame)
            print(f"Screenshot saved: {filename}")
        elif key == ord('f'):
            # Toggle face detection
            face_detection_enabled = not face_detection_enabled
            print(f"Face detection: {'ON' if face_detection_enabled else 'OFF'}")
        elif key == ord('i'):
            # Print camera info
            print(f"\nCamera Info:")
            print(f"  Index: {working_index}")
            print(f"  Resolution: {width}x{height}")
            print(f"  Current FPS: {current_fps:.1f}")
            print(f"  Frames processed: {frame_count}")
            print(f"  Faces detected: {faces_detected}")
            print(f"  Elapsed time: {elapsed_time:.1f}s")
    
    # Cleanup
    cap.release()
    cv2.destroyAllWindows()
    
    # Final report
    print("\n=== Camera Test Results ===")
    print(f"✅ Camera connection: SUCCESS (index {working_index})")
    print(f"✅ Frame capture: {frame_count} frames")
    print(f"✅ Average FPS: {current_fps:.1f}")
    print(f"✅ Face detection: {faces_detected} faces detected")
    print(f"✅ Test duration: {elapsed_time:.1f} seconds")
    
    if faces_detected > 0:
        print("\n🎉 Camera and face detection working perfectly!")
        print("Your system is ready for pain classification testing.")
    else:
        print("\n⚠️  Camera works but no faces detected.")
        print("Make sure you're visible in the camera frame.")
    
    return True

def main():
    """
    Main function
    """
    try:
        success = test_iriun_camera()
        if success:
            print("\n✅ Camera test completed successfully!")
            print("\nNext steps:")
            print("1. Wait for dependencies to finish installing")
            print("2. Train the model: python pain_classification_cnn.py")
            print("3. Test with real-time classification: python real_time_test.py")
        else:
            print("\n❌ Camera test failed. Please check your Iriun setup.")
    except KeyboardInterrupt:
        print("\nTest interrupted by user.")
    except Exception as e:
        print(f"\nError during camera test: {e}")
        print("Please check your OpenCV installation and camera setup.")

if __name__ == "__main__":
    main()