import cv2
from matplotlib import pyplot as plt
import numpy as np
#from skimage import io
from rembg import remove 
from PIL import Image 
import imutils
from skimage import io



#count=0

label0=io.imread("label_00_final.png")
label1=io.imread("label_11_final.png")
label2=io.imread("label_22_final.png")
label3=io.imread("label_33_final.png")

label_images=[label0, label1, label2, label3]

predicted=[]


def void():
    pass


video= cv2.VideoCapture(0)



while True:
    
    _,frame=video.read()
    
    hsv= cv2.cvtColor(frame, cv2.COLOR_BGR2HSV)
    
    lower_skin=np.array([0, 60, 0])
    upper_skin=np.array([179, 255, 255])
    
    mask=cv2.inRange(hsv,lower_skin, upper_skin)
    
    
    height= mask.shape[0]
    width= mask.shape[1]

    width_cutoff = width // 2
    height_cutoff = (height // 2) // 2 # for increasing efficiency in template matching
    mask1 = mask[height_cutoff:, :width_cutoff]
    
    min_vals=[]
    min_locs=[]
    
    for x in label_images:
        res=cv2.matchTemplate(mask1, x, cv2.TM_SQDIFF)
        min_val,_,min_loc,_= cv2.minMaxLoc(res)
        
        min_vals += [int(min_val)]
        min_locs += [min_loc]
        
        
    ind=min_vals.index(min(min_vals))
    pred_label=label_images[ind]
    
    h, w=pred_label.shape[::]
    
    min_loc0=min_locs[ind]
    
    top_left=min_loc0
    
    hand_loc=(top_left[0], top_left[1]+ int(height_cutoff)), (top_left[0] + w, top_left[1] + h + int(height_cutoff))
    
    cv2.rectangle(frame, hand_loc[0], hand_loc[1],(255,0,0), 2)
    
    hand_loc1=(top_left[0], top_left[1]+ int(height_cutoff) - 100)
    
    frame_gray=cv2.cvtColor(frame, cv2.COLOR_RGB2GRAY)
    
    cv2.putText(frame_gray, f"LABEL_{ind}", hand_loc1, cv2.FONT_HERSHEY_COMPLEX, 3, (255, 255, 255), 1)

    predicted +=[ind]
    
    print(predicted)
    
    #if count==0:
        #print(mask1[0])
        #io.imshow(mask1)
        #count +=1
        

    #cv2.imshow("Webcam", frame)
    cv2.imshow("Webcam", frame_gray)
    cv2.imshow("mask", mask)
    
    
    
    if cv2.waitKey(4000) & 0XFF ==ord("q"):
        break
    
    
video.release()
cv2.destroyAllWindows()

