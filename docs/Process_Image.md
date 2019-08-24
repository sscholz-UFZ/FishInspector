
# Process Image

Once the images have been loaded you can start the analysis. Click on one image from the list box on the left (the name of the image will appear highlighted in blue). Then the detection of the features will automatically start from left to right. Loading of the first image may takes a bit longer. The time required for loading an image depends on the resolution and the computer processing power.

> Click the ![orientation](https://github.com/sscholz-UFZ/FishInspector/blob/docs/docs/Images/orientation_icon.jpg) icon in the **Zoom** box to display the fish to its standard orientation (more convenient for the visual analysis).

Before starting manual correction of features check if the parameter file (see section [Set parameters](https://github.com/sscholz-UFZ/FishInspector/blob/docs/docs/Overview.md#set-parameters)) is the one you intend to use. Every time the FishInspector is started it loads the default parameter file. It is recommended that parameter files are optimised to reduce requirement for manual editing.

> The tick mark on the left of the image name on the list box indicates that the analysis of the image is enabled, unticked images will not be analysed. Images may be deselected e.g. in case of insufficient positioning. 

![](https://github.com/sscholz-UFZ/FishInspector/blob/docs/docs/Images/tick_image.jpg)

## Feature Correction
The software permits modification of the parameters used for the automatic feature detection or manual correction given that establishment of a 100% correct automated feature detection is very challenging.

Click on the ![](https://github.com/sscholz-UFZ/FishInspector/blob/docs/docs/Images/edit_feature.jpg) icon to access the editor window of a specific feature. The best way to check and correct features is from left to right due to the dependency on detection of some features (see section [Features editor box](https://github.com/sscholz-UFZ/FishInspector/blob/docs/docs/Overview.md#features-editor-box)).<br>
First try to correct the parameters of the feature to see if its detection can be improved, and save parameters if you want them to be used for subsequent image analysis (see [Modify and save parameters](https://github.com/sscholz-UFZ/FishInspector/blob/docs/docs/Overview.md#Modify-and-save-parameters). If no further improvement by changing parameters can be achieved, correct the feature manually (see section [Edit Feature](https://github.com/sscholz-UFZ/FishInspector/blob/docs/docs/Overview.md#Edit-feature)). Hold click and drag the mouse to correct the annotated lines or points.
Once the feature is corrected, click on **Save to SHAPE.json** to confirm and save changes. Any dependent features will be updated as well.
> To disable the update of dependent features click on **Run → Update depended features**.


---

# Feature Description
This section contains the description of each feature and the functionality of the parameters of a given feature. The description is very detailed. However, to use the FishInspector it may not require that you understand the underlying processes in detail.

<img src="https://github.com/sscholz-UFZ/FishInspector/blob/docs/docs/Images/Features.jpg" width="600">

In the example shown above, the following features were detected : a, lower jaw tip using the Manual feature tool (orange), b, eye contour (green), c, fish contour (red), d, pericard (blue), e, yolk sac (green), f, swim bladder (blue), g, otolith (green), h, notochord (green), i, pigmentation (yellow).

## Manual
The manual annotation allows to create a custom line or point to annotate feature for which not automatic detection tool is available.
Press the ![](https://github.com/sscholz-UFZ/FishInspector/blob/docs/docs/Images/edit_feature.jpg) icon of the **Manual** feature. Then use the context menu (by right click with the mouse on the image) to create a **new line** or **new point**.

>Hold click and drag the mouse to move a point to a different place or to modify the shape of a line. To enlarge or reduce the size of the point use the scroll wheel of the mouse.

To delete a point or line right click with the mouse on the line or point to erase and click **delete**.<br>
Principally it is possible to apply multiple labels using the **Manual** feature tool. These will be stored in the order how the labels were applied. Hence, if you apply more than one label you need to process them in the same sequence since otherwise they would be confused in subsequent processing of JSON files. However, the order changes in case subsequent editing of a label. Hence, annotation of multiple features should be conducted with care.<br>

Currently, jaw morphology analysis is at present only possible by using the manual selection tool and by labeling the lower jaw tip with a point mark. Jaw morphology analysis is usually conducted for embryos older than 72 hpf. When analysing jaw morphology, if you consider that an embryo has no jaw, insert a mark point below the eye on the fish contour. This is to prevent the failure of the subsequent analysis.<br>
<img src="https://github.com/sscholz-UFZ/FishInspector/blob/docs/docs/Images/jaw.jpg" width="200"> <img src="https://github.com/sscholz-UFZ/FishInspector/blob/docs/docs/Images/Jaw_2.png" width="200">

## Capillary
The detection of the capillary is done in two steps.
First, a binary image is generated, using a dynamic threshold based on Otsu's method [1], multiplied by the **threshMultiplier** variable.<br>
Second, based on the binary image, the position of the capillary wall is estimated. Regions at the border of the image with strong background variations and/or artefacts from stitching may affect detection of the capillary wall. Those regions can be excluded by adjusting the **vertCutoff** and **horizCutoff** variables, which represent fractions of the image-height and image-width respectively.

The image below indicates the detection of the capillary, green lines indicate the inner capillary wall and blue lines the outer capillary outline.<br>
<img src="https://github.com/sscholz-UFZ/FishInspector/blob/docs/docs/Images/capillary.jpg" width="600">
> [1] Otsu, N., "A Threshold Selection Method from Gray-Level Histograms," IEEE Transactions on Systems, Man, and Cybernetics, Vol. 9, No. 1, 1979, pp. 62-66.
 
### Parameters
<img src="https://github.com/sscholz-UFZ/FishInspector/blob/docs/docs/Images/Edid_capillary.jpg" width="400"><br>
**threshMultiplier** – modifies the threshold value obtained with the Otsu's method [1] using the graythresh function in MATLAB.<br>
**vertCutoff & horizCutoff** – allow to exclude regions at the border of the image which may have strong background or artefacts and can affect the detection of the capillary wall.<br>
**steps** – used to find the inner edges (lower and upper) of the capillary wall.

### Display options
**showBinary** – overlays the binary image in the display window.<br>
**plotCutoffs** – show or hide vertical and horizontal cut off.<br>
**plotCapillary** – show or hide capillary annotation.

## Fish Contour
The detection of the fish contour is based on a binary image generated using a dynamic threshold based on Otsu's method [1], multiplied by the **auto_thresh_multiplier** variable. The binary is generated from the inner image inside the capillary. Then the biggest region is selected (to discard artefacts) and holes are filled using the variable **imclose_dislike**. Boundary coordinates are obtained from this binary image and this is what is called binary contour. Finally, the binary contour is smoothed and an active contour is used to get the fine position and get the boundaries of a fine contour (in red on the image below).<br>
<img src="https://github.com/sscholz-UFZ/FishInspector/blob/docs/docs/Images/FishContour.jpg" width="600"><br>
All parameters used, except the auto_thresh_multiplier, are related to the average capillary width of each image. I.e. images with different resolutions do not require a different set of parameters since they are “normalised” by the capillary width.

### Parameters
<img src="https://github.com/sscholz-UFZ/FishInspector/blob/docs/docs/Images/Parameters_fishContour.jpg" width="400"><br>
**auto_thresh_multiplier** – modifies the threshold value obtained with the Otsu's method using the graythresh function in Matlab.<br>
**width_of_capillary_wall** – all white border pixels with less than width capillary wall pixels are removed.<br>
**imclose_disksize** – defines the radius of the disk-shaped structuring element used in the imclose function in Matlab to fill the holes of the binary image.<br>
**binary_contour_smoothing** – defines the degree of smoothness of the fine contour goes from 0 (highly smooth contour) to infinite.<br>
**min_peak_width** – is used in the active contour function to get the fine position of the fine contour. Takes values from 0 to 1, the greater the value the finest position takes.

>Active contour models are used to find the boundaries of shapes in an image.

### Display options

**plot_binary_shape** – overlays the binary shape in the display window.<br>
**plot_binary_contour** – show or hide binary contour.<br>
**plot_fine_contour** – show or hide fine contour.

## Fish Eye
The detection of the fish eye is based on the creation of a binary image only taking into account the region inside the contour of the fish. Moreover, the central part of the fish is excluded using the **relLengthOfHead** variable in order to find the darkest region in the two extreme parts of the fish (head or tail).
The image below displays the region excluded from the eye detection and the eye outlined in green.
<img src="https://github.com/sscholz-UFZ/FishInspector/blob/docs/docs/Images/Eye_detection.jpg" width="600">

### Parameters
<img src="https://github.com/sscholz-UFZ/FishInspector/blob/docs/docs/Images/Parameters_eye.jpg" width="400"><br>
**relLengthOfHead** – relative length of head to exclude central part of the fish.<br>
**autothresh_multiplier** – modifies the threshold for the detection of the eye. Reduce it to detect a less pigmented eye.
### Display options
**showBinary** – show or hide the region that is excluded from the eye detection.<br>
**showContour** – show or hide the contour of the fish eye detected.

## Fish Orientation
This feature is used to determine the orientation of the fish. The horizontal orientation is detected by finding where the eye is (maximum sum of pixel values). The vertical orientation is determined in 3 steps: a) around the eye region the algorithm looks for the darkest spot inside the fishContour in each column. b) these spots are fitted to a quadratic function ax^2. c) The sign of a determines the vertical orientation.<br>
The orientation is shown by an arrow, the standard orientation of the fish is with the head on the left and yolk sac on the bottom part as the picture shows. The arrow needs to point towards the ventral, rostral side of the fish embryo (as indicated in the image below).<br>
<img src="https://github.com/sscholz-UFZ/FishInspector/blob/docs/docs/Images/orientation.jpg" width="500"><br>
To correct the orientation, select manual selection in the editor window of the feature and hold click on the red circle and drag the arrow to the correct position.<br>
<img src="https://github.com/sscholz-UFZ/FishInspector/blob/docs/docs/Images/Edition_orientation.jpg" width="400">

### Display options
**showOrientation** – show or hide the green arrow (orientation).
### Output
The orientation of the fish embryos in the original image is described in the output JSON files by two variables: **horitzontally_flipped** and **vertically_flipped**.

>Remember that digital images are typically viewed with coordinates (indices) in which y increases downwards and x increases to the right (see section Output data). That should be taken into account when doing morphometric analysis.

|                                                                                                     |                  |
|   :-----:  |------------------|
|<img src="https://github.com/sscholz-UFZ/FishInspector/blob/docs/docs/Images/h0_v0.jpg" width="300">|`Standard orientation`<br>horitzontally_flipped:0<br>vertically_flipped: 0|
|<img src="https://github.com/sscholz-UFZ/FishInspector/blob/docs/docs/Images/h1_v0.jpg" width="300">|horitzontally_flipped: 1 <br>vertically_flipped: 0|
|<img src="https://github.com/sscholz-UFZ/FishInspector/blob/docs/docs/Images/h0_v1.jpg" width="300">|horitzontally_flipped: 0<br>vertically_flipped: 1|
|<img src="https://github.com/sscholz-UFZ/FishInspector/blob/docs/docs/Images/h1_v1.jpg" width="300">|horitzontally_flipped: 1<br>vertically_flipped: 1|

## Central Dark Line
This feature is used only as reference for the detection of the subsequent features like yolk sac or notochord.

### Parameters
<img src="https://github.com/sscholz-UFZ/FishInspector/blob/docs/docs/Images/Parameters_centralDL.jpg" width="400"><br>

**upper_border_mindist** – allows to discard the upper part of the fish, to avoid dark pixels (1).<br>
**thick_part_thresh** – modifies threshold of the lower excluded part (yolk sac) to expand or contract the area (2).<br>
**thick_part_cutoff** – allows to discard lower part of the fish that can influence on the detection of the central dark line (3).<br>
**low_thresh** – This value currently does nothing and could actually be removed (originally it was a lower threshold for finding the dark line).<br>
<img src="https://github.com/sscholz-UFZ/FishInspector/blob/docs/docs/Images/CentralDarkLine.png" width="600">
### Display options
**plot_CentralDarkLine** – show or hide the detected central dark line.<br>
**plotFishContour** – show or hide the detected fish contour.<br>
**showUpperExclusion** – show or hide upper part excluded.<br>
**showThickPartExclusion** – show or hide lower part excluded.

## Bladder
For the detection of the swim bladder a mask is generated to limit the principally possible location in the image. The mask is created along the central dark line taking into account the parameters that defines the region of interest (ROI, rectangle shown in the image below). After that a threshold is applied and the biggest dark blob is used to detect the swim bladder boundaries (in green).<br>
<img src="https://github.com/sscholz-UFZ/FishInspector/blob/docs/docs/Images/Bladder_detection.jpg" width="300">

### Parameters
<img src="https://github.com/sscholz-UFZ/FishInspector/blob/docs/docs/Images/Parameters_bladder.jpg" width="400"><br>

**ROI - Relative Offset** – change the position along the central dark line of the region of interest.<br>
**ROI - Relative Length** – increase or decrease the length of the region of interest from the right position.<br>
**ROI - Relative Vertical CutOff** – wide or narrow the region of interest.<br>
**autothresh_multiplier** – modifies the threshold for the detection of the swim bladder.<br>
**imclose_disksize** – defines the radius of the disk-shaped structuring element used in the imdilate function in Matlab of the binary image.<br>
**MinPeakWidth** – is used in the active contour function to get the fine position of the fine contour. Takes values from 0 to 1, the greater the value the finest position takes.<br>
**BinaryContourSmoothing** – Takes values from 0 (very smoothed) to 1 (no smoothing at all). Used to refine contour of the bladder.
### Display options
**plot threshold region** – show or hide the region after the threshold.<br>
**plot ellipse fit** – show or hide the ellipse fit of the threshold area.<br>
**plot fine contour** – show or hide the fine contour of the detected bladder boundaries.<br>
**show ROI**– show or hide the ROI for the bladder detection.

## Notochord
To detect the notochord only the upper part of the central dark line is used by generating a mask using the fish contour, fish eye and central dark line. The display option showLowerExclusion shows or hides this mask. Also an exclusion region on the upper part of the fish is created to improve detection of the notochord (showUpperExlcusion).
<img src="https://github.com/sscholz-UFZ/FishInspector/blob/docs/docs/Images/notochord.jpg" width="600">

### Parameters
<img src="https://github.com/sscholz-UFZ/FishInspector/blob/docs/docs/Images/Parameter_notochord.jpg" width="400"><br>
**upper_border_exlcude_factor** – wide or narrow the excluded border region on the upper part of the fish.
**low_thresh** – this value determines which pixels are considered as a maximum (for the upper border of the notochord) and the minimum (for the lower border of the notochord)
### Display options
**plot_Notochord** – show or hide the notochord coordinates.<br>
**showUpperExclusion** – show or hide upper exclusion region of the fish.<br>
**showLowerExclusion** – show or hide initial excluded region to detect the notochord.

## Otolith
The otoliths are biomineralized ear stones that contribute to both hearing and vestibular function in fish. Embryos have two otoliths, the utricular (anterior) and saccular (posterior). The figure below display the location of the two otoliths of a zebrafish embryo (red arrows). Usually the posterior otolith is bigger than the anterior.<br>
<img src="https://github.com/sscholz-UFZ/FishInspector/blob/docs/docs/Images/otholiths.jpg" width="300"><br>
This feature is detected by first generating a mask to narrow down the region where to look for the otolith(s). For the mask some limits (cutoffs) are defined as variables: **Eye Offset**, **Relative Length** and **Relative Vertical CutOff*. Then a threshold is applied to find the darker dots that are the otoliths and finally the centroid (x,y) and radius of the detected object is saved as output.<br>
The **manual selection** allows to erase or create new points and modify its size.<br>
- Create **new point**: Use the context menu (by right click with the mouse on the image) and click **new point**. Hold click and drag the mouse to move a point to a different place. To enlarge or reduce the size of the point use the scroll wheel of the mouse.
- Delete a point: right click with the mouse on the point and click **delete**.<br>
>The otolith position is used to calculate the distance between the eye centroid and posterior otolith in subsequent analysis of JSON files. The distance depends on the developmental stage of the embryo. At present, the subsequent workflow requires the position of the larger, the posterior otolith. It is sufficient to check that the posterior otolith has received the bigger label. In the subsequent workflow only the position of the bigger label will be used to estimate the otolith-eye distance.

### Parameters
<img src="https://github.com/sscholz-UFZ/FishInspector/blob/docs/docs/Images/Parameter_otolith.jpg" width="400"><br>

**Eye Offset** – moves the mask along the central dark line (close or far from the eye).<br>
**Relative Length** – Increases or decreases the width of the mask from the right part.<br>
**Relative Vertical CutOff** – increases (by decreasing the value of the parameter) or decreases (by increasing the value of the parameter) the height of the mask from the top.<br>
**Autothresh multiplier** – modifies the threshold value obtained with the Otsu's method used to detect the otoliths.
### Display options
**plot_binary_shape** – show or hide binary shape of the detected otolith.<br>
**plot_fine_contour** – show or hide otolith radius and position (ellipse).<br>
**showBinary** – show or hide mask created for the location of the otolith.

## Yolk Sac
The yolk sac is detected by excluding the upper part of the fish using the central dark line as reference and by using the inverted image. For the mask the bladder is excluded and also everything left to the right border of the eye. Some limits (cutoffs) are defined as variables: **Front CutOff** and **Rear CutOff**. The inverted image will be show during the edition of yolk sac boundaries.<br>
<img src="https://github.com/sscholz-UFZ/FishInspector/blob/docs/docs/Images/Yolk_detection.jpg" width="600">

### Parameters
<img src="https://github.com/sscholz-UFZ/FishInspector/blob/docs/docs/Images/Parameter_yolk.jpg" width="400"><br>

**Front Cutoff** – increases or reduces the width on the left. To enlarge decrease the value.<br>
**Rear Cutoff** – increases or reduces the width on the right.. To enlarge decrease the value.<br>
**MinPeakWidth** – is used in the active contour function to get the fine position of the fine contour. Takes values from 0 to 1, the greater the value the finest position takes.<br>
**BinaryContourSmoothing** – Takes values from 0 (very smoothed) to 1 (no smoothing at all). Used to refine contour of the yolk and create a fine contour.
### Display options
**plot_binary_shape** – show or hide binary shape of the detected yolk boundaries.<br>
**plot_fine_contour** – show or hide fine contour of the yolk after smoothing.

## Pericard
At present, pericard always required manual correction and it is sometimes difficult to locate the boundaries precisely. To narrow its location a mask is created between the eye and yolk. A limit is set using the variable **Eye Offset**. For the detection and during edition it uses the inverted image. The images below show an example of the pericard region corrected (in blue) in 48hpf (top picture) and 96 hpf old embryos (bottom picture).<br>
<img src="https://github.com/sscholz-UFZ/FishInspector/blob/docs/docs/Images/pericard_48h.jpg" width="200">     <img src="https://github.com/sscholz-UFZ/FishInspector/blob/docs/docs/Images/Pericard_96.jpg" width="200">

### Parameters
<img src="https://github.com/sscholz-UFZ/FishInspector/blob/docs/docs/Images/Parameter_pericard.png" width="400"><br>
**Eye Offset** – increases or reduces the width of the mask from the eye (larger values make the mask smaller).<br>
**Autothresh multiplier** – modifies the threshold value used to create the binary detected image of the pericard.

## Pigmentation
The detection of the pigmentation is based on the detection of pigment cells inside the area delimited by the notochord (outlined in red in the image below). The pigmentation analysis was restricted to the notochord region to reduce variability. Many pigment cells are located dorsally. However, slight differences in position of the embryo may impact on the number of pigment cells visible in the lateral image. Hence, we included only regions where we anticipated that the number of pigment cells may not be affected by differences in positioning. A mask is created that uses the variables, **ROI - Relative Offset** and **ROI - Relative Length**. Pigment cells are detected applying a threshold (**Autothresh multiplier**).<br>
<img src="https://github.com/sscholz-UFZ/FishInspector/blob/docs/docs/Images/Pigmentation.png" width="600">

### Parameters
<img src="https://github.com/sscholz-UFZ/FishInspector/blob/docs/docs/Images/Parameter_pigmentation.png" width="400">

**ROI - Relative Offset** –increases or reduces the width of the mask from the head region. Adjust this Offset to avoid the detection of otoliths.<br>
**ROI - Relative Length** – Increases or reduces the length of the mask from the tail position of the fish embryo.<br>
**Autothresh multiplier** – modifies the threshold value to identify the pigment cells. Increasing values, increases the threshold to detect darker pigmented cells.<br>

>It is important to use the same **Autothresh multiplier** in all images if your objective is to detect changes in pigmentation area (sum area of pigment cells detected). If the threshold would be changed image to image the area of pigment cells would be affected and compromise a comparative analysis!
### Display options
**plot_binary_shape** – show or hide boundaries of the pigment cells detected.<br>
**showBinary** – show or hide the mask of the area for the location of the pigment cells.
