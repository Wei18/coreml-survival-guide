### OBJECTIVE
Using the iOS sample application of Object Detection sample[1] and extend it with video recording that triggered by person detection functionality.

### REQUIREMENTS
1. Able to load a video file (.mp4 with person in content)
2. Extract the video frame (CVPixelBuffer) from video file and using it for object detection inference[2]
[v] 3. Once one or more persons are detected, the app should start record video and save it into another 10 seconds duration video file (.mp4)
[v] 4. Save the recorded video file into iOS’s Photos app[3]

### OPTIONAL
[v] 1. Draw bounding boxes at recorded video frame
[v] 2. Stop video recording automatically if no more person detected after the time of last detected video frame over than 5 seconds
