import cv2
from matplotlib import pyplot as plt
import numpy as np
#from skimage import io
from rembg import remove 
from PIL import Image 
import imutils

    

def void():
    pass


video= cv2.VideoCapture(0)

cv2.namedWindow("Trackbar")

cv2.createTrackbar("L-H", "Trackbar", 0, 179, void)
cv2.createTrackbar("L-S", "Trackbar", 0, 255, void)
cv2.createTrackbar("L-V", "Trackbar", 0, 255, void)
cv2.createTrackbar("U-H", "Trackbar", 179, 179, void)
cv2.createTrackbar("U-S", "Trackbar", 255, 255, void)
cv2.createTrackbar("U-V", "Trackbar", 255, 255, void)


while True:
    
    _,frame=video.read()
    
    hsv= cv2.cvtColor(frame, cv2.COLOR_BGR2HSV)
    
    l_h=cv2.getTrackbarPos("L-H", "Trackbar")
    l_s=cv2.getTrackbarPos("L-S", "Trackbar")
    l_v=cv2.getTrackbarPos("L-V", "Trackbar")
    u_h=cv2.getTrackbarPos("U-H", "Trackbar")
    u_s=cv2.getTrackbarPos("U-S", "Trackbar")
    u_v=cv2.getTrackbarPos("U-V", "Trackbar")
    
    lower_skin=np.array([l_h, l_s, l_v])
    upper_skin=np.array([u_h, u_s, u_v])
    
    mask=cv2.inRange(hsv,lower_skin, upper_skin)
    

    cv2.imshow("Webcam", frame)
    cv2.imshow("mask", mask)
    
    
    
    if cv2.waitKey(1000) & 0XFF ==ord("q"):
        break
    
    
video.release()
cv2.destroyAllWindows()




























