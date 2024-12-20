#!/bin/bash

# Disable Git Bash path conversion
export MSYS_NO_PATHCONV=1

# Device settings
DeviceSize="1080x2340"
ON_DEVICE_OUTPUT_FILE="/sdcard/Download/test_video.mp4"  # Updated path
OUTPUT_VIDEO="./test_video.mp4"
DRIVER_PATH="test_driver/integration_test_driver.dart"
TEST_PATH="test/integration_test.dart"

# Define encoding profile or bitrate options (choose one or both)
ENCODING_PROFILE="high"        # Options: 'low', 'medium', 'high'
BITRATE="8000000"              # Bitrate in bits per second (e.g., 8Mbps)

# Get the device ID
DeviceId=$(adb devices | awk 'NR==2 {print $1}')
sleep 10

# Start recording screen in the background with encoding profile or bitrate
adb shell screenrecord --size $DeviceSize --encoding-profile $ENCODING_PROFILE $ON_DEVICE_OUTPUT_FILE &  # Use encoding-profile
# OR alternatively use the bitrate option:
# adb shell screenrecord --size $DeviceSize --bitrate $BITRATE $ON_DEVICE_OUTPUT_FILE &  # Use bitrate

RECORD_PID=$!
echo "Screen recording started with PID: $RECORD_PID"

# Run the Flutter test using the specified driver and target
flutter drive --device-id=$DeviceId --driver=$DRIVER_PATH --target=$TEST_PATH
echo "Flutter test completed."

# Optional: Sleep for a few seconds to ensure screen recording is finished before pulling the file
sleep 10

# Removed the move on device command and the pulling command:
# adb shell mv $ON_DEVICE_OUTPUT_FILE /sdcard/test_video.mp4  # Relocate file on device
# adb pull /sdcard/test_video.mp4 ./  # Pull from a consistent path


# Kill the screen recording process to stop the recording
kill $RECORD_PID

# Echo completion message
echo "Test completed and video saved on device at /sdcard/test_video.mp4"

# Optional: Keep the terminal open to observe output
read -p "Press any key to exit..."