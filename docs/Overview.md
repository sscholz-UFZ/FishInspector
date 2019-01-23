# FishInspector software overview

## Main window
Once the FishInspector starts up, the main window appears:
![Main window](https://github.com/sscholz-UFZ/FishInspector/blob/docs/docs/Images/Main_window.jpg)
>1. Main menu bar
>2. Set input (scan from folder or list images from file)
>3. Filter images
>4. Zoom and orientation tool
>5. List of loaded images
>6. Parameter file selection
>7. Open/save shape data
>8. Image box display 
>9. Features editor box

---
## Main menu bar commands
This section describes all menu commands in the **File**, **Run**, **Export**, **Settings** and **Help** menus. 
### File menu commands
**Open directory** – browse the file system to retrieve images from a directory.<br>
**Open image list** – browse the file system to retrieve a text file (.txt) containing the full path to the image per line.<br>
**Quit** – Close the FishInspector software.<br>
### Run menu commands
**Process all images** – automatically process all images for feature extraction.<br>
**Update feature in all images** – update a specific feature for all loaded images.<br>
**Update depended feature** – if ticked updates dependent features when images are analysed or a feature is updated.<br> 
**Preserve manual selection** – preserve a manual selection when images are analysed or a feature is updated.<br>
### Export menu commands
**Export current image…** – export current displayed image in png format with the annotated features.<br>
**Export image list** – export the list of images loaded in .txt format.<br>
**Export all images with reduced background** – export all loaded images with reduced background (currently it only works with .tif images).<br>
### Settings menu commands
**Always start editor with “Manual Selection” enabled** – if ticked the image will be loaded with the “Manual Selection” mode enabled in the features editor box.<br>
### Help menu commands 
**Dos command** – List of possible Dos commands to process images in batch mode with FishInspector software started from the command line in windows.<br>
**Licenses** – display license information.<br>
**About…** – display FishInspector software version, release date and link to license information.<br>

---

## Features editor box
This box displays the current set of features available for annotation:<br>
* Manual selection
* Capillary
* Fish contour
* Fish eye
* Fish Orientation
* Central dark line
* Bladder
* Notochord
* Otolith
* Yolk sac
* Pericard
* Pigmentation

The detection of various features is organized hierarchically, that is, in order to locate a certain feature the locations of previously detected features are included. For example, detection of the contour of the embryo is guided by the capillary boundaries, since the software expects the embryo to be located inside the capillary (or least in a virtual capillary). Subsequently, other 
features are identified in a stepwise manner (See Figure 1). Hence, the detection of specific morphological features is dependent on the detection of other features and is facilitated by excluding regions that may interfere. The identification of the regions of interest is driven by visual observation and measurement of generic object properties. For example, once the contour of the fish is localized, the eye is detected by searching for a dark object either in the right or left half of the zebrafish.<br>

![Figure 1]()
>**Figure 1.** Stepwise feature recognition by the FishInspector software. The “central dark line”, represents a structure of high contrast between the upper and bottom part of the fish, starting from the fish eye. This feature is only used to support the identification of other features and does not refer to a morphologically relevant entity. *Images without capillary need to be modified (i.e. insertion of a virtual capillary)by an automated workflow to be compliant with the FishInspector software (KNIME workflow available [here]()).

|||
|---------|-----------| 
|![Green](https://github.com/sscholz-UFZ/FishInspector/blob/docs/docs/Images/detected_feature.jpg)| Green tick next to the feature indicates that the feature has been detected. | 
|![Red](https://github.com/sscholz-UFZ/FishInspector/blob/docs/docs/Images/error_detection.jpg)|Red cross next to the feature indicates that there was an error with the plugin and the feature can’t be detected. |


> Red cross: This may happen for example when the capillary was not detected correctly (but it has a green tick), then the fish contour and any other feature that depends on the capillary fail and is marked by a red crosses.

### Toggle visibility
Press the ![eye](https://github.com/sscholz-UFZ/FishInspector/blob/docs/FishInspector_resources/eye-Icon.gif) icon to show or hide
![dash](https://github.com/sscholz-UFZ/FishInspector/blob/docs/FishInspector_resources/eye-dash-Icon.gif) the feature in the image display.

---
## Edit feature 
Press the ![pen](https://github.com/sscholz-UFZ/FishInspector/blob/docs/docs/Images/edit_feature.jpg) icon to access the editor window of a specific feature.
The editor window allows to choose between **manual selection** or **automatic detection** of the feature. When using the automatic detection, in most of the cases you will find a box containing the parameter that can be modified (1)(see [modify and save parameters](#Modify-and-save-parameters)). The editor window also contains a display box (2) with the display options for that specific feature.

<img src="https://github.com/sscholz-UFZ/FishInspector/blob/docs/docs/Images/Editor_window.jpg" width="600">

> Not all features allow manual selection or have display options.

### Enable or disable a feature
To enable or disable a feature, right click with the mouse on the feature and press (untick) **Use feature**. The disable feature will have a specific orange symbol next to it. 

![disable](https://github.com/sscholz-UFZ/FishInspector/blob/docs/docs/Images/disable_feature.jpg)	 
---
## Set parameters
Given that establishment of a 100% correct automated feature detection would be very challenging and to allow improvement by the user, the software permits modification of the parameters used for the automated feature detection. This is very useful to adapt for specific image characteristics (contrast, intensity, RGB or grayscale, developmental stage). However, also for optimised parameters, the automated detection may not be successful. In this case it is possible to manually edit the annotation of the feature. 
The parameters of all features are stored using a json file. The FishInspector software comes with a set of default parameters automatically loaded from the parameter set box in the left bottom part of the main window. Modified parameters can be saved in a specific file that can then be loaded in subsequent analyses with similar images).  

This menu allows to:<br>
**Edit File** – (Not working for the moment)<br>
**Open Directory** – browse the file system to retrieve the folder where the parameters are saved.<br>
**Rescan Directory** – Refreshes the current directory that contains the parameters.<br>
**Create New Parameter File** – Allow to create a new file containing new set of parameters.<br>
>Create a new parameter file if you have different types of images (from a different source) or different embryo stages that could differ on detection of the features.

### Modify and save parameters
Features can have parameters to improve its automatic detection. These parameters can be modified in the editor window of each feature (see section [Edit Feature](#Edit-Feature)). To modify a parameter either introduce directly a number value in the box next to the parameter (1) or click on the icon with a plus or minus sign (2). To save the parameters click on the **save** icon (3). 

<img src="https://github.com/sscholz-UFZ/FishInspector/blob/docs/docs/Images/Parameters.jpg" width="400">

To apply a change on a parameter/feature for all analysed images follow these steps: 
* [Disable](#Enable-or-disable-a-feature) the feature on the first image.
* **Run** → **Update feature in all images** and select the specific feature to be updated.
* Once the analysis is finished, enable the feature on the first image.
* Correct the parameters and save the shape data by click on the **save SHAPE.json** button on the editor window of the feature.
* **Run** → **Update feature in all images** and select the specific feature to update.
---			
## Output data
The resulting output of the FishInspector is a set of xy coordinates of the morphological feature detected. 
FishInspector has been programmed in MATLAB®, which stores most images as two-dimensional arrays (i.e., matrices).Each element of the matrix corresponds to a single pixel in the displayed image. To access locations in images, the MATLAB Image Processing Toolbox™ uses seBy default, the toolbox uses a spatial coordinate system for an image that corresponds to the image’s pixel indices. It is called the intrinsic coordinate system and is illustrated in [here](https://ch.mathworks.com/help/images/image-coordinate-systems.html). The image is treated as a grid, ordered from top to bottom, and left to right. Y increases downward, while x increases to the right.veral different image coordinate systems as conventions for representing images as arrays.

>Coordinates are dependent on image resolution. Hence, for a comparative analysis it is recommended to use images with the same resolution. Otherwise coordinates may be normalised by the specific resolution.

For each image analyzed, data are exported to a single JSON file, which is a language independent open-standard file format typically used for transmitting data between applications. The boundary coordinates of multiple features can then be stored in a structured text file. This allows the seamless integration of the FishInspector output into custom post-processing algorithms, which can be implemented in any programming language. 

The output data file is generated in the same folder from which images have been loaded  and takes the same name as the image file plus a suffix ending by __SHAPES. The output is generated by clicking either the **Save SHAPE** button situated on the left bottom part of the main window in the Shape Data box.
 
![output](https://github.com/sscholz-UFZ/FishInspector/blob/docs/docs/Images/Shape_data.jpg)

or by click on the **Save SHAPE.json** button on each feature editor window (see section [Edit Feature](#Edit-Feature)). 

**Open JSON File** – opens the directory that contains the output Json file.

---
## Loading images
Images can be loaded by open a directory or by reading image list from file.

### Load images from directory
There are two options to proceed:<br>
Select **File** → **Open directory** on the menu bar to open the file dialog, browse and select the folder where the images are stored. 

Or select the **Scan folder for images** tab under the main menu bar and click ![folder](https://github.com/sscholz-UFZ/FishInspector/blob/docs/docs/Images/scan_folder.jpg)
to open the file dialog, browse and select the folder where the images are stored.<br>
The names of the images loaded are displayed in the list box on the left of the main window.

### Load images from image list file
There are two options to proceed:<br> 
Select **File** → **Open image list** on the menu bar to open the file dialog, browse and select the text file (.txt) containing the full path to the images.

Or select the **Read image file from file** tab under the main menu bar and click ![folder](https://github.com/sscholz-UFZ/FishInspector/blob/docs/docs/Images/scan_folder.jpg)
to open the file dialog, browse and select the text file (.txt) containing the full path to the images.<br>
The names of the images loaded are displayed in the list box on the left of the main window.

> Most common image file formats are supported: .tif, .png, .bmp and .jpg. FishInspector supports RGB and grey images.

### Image filter
The image filter box allows you to refine the image list to just load and process selected images. Specific words can be used to selectively analyse images (e.g. “.bmp” will load only images with bmp format, or “_2” will load images which name contains these characters).

### Zoom tool
The **Zoom** box is situated on the right top of the main window and allows you to adjust the image zoom to:<br> 
**Fit fish** – it resizes the image based on the contour of the fish.<br>
**Fit image** – it resized the image to fit into the the size of the display window.<br>
**Fit image height** – it resizes the image to fit the height of the image into the display window.<br>
**Fit image width** – it resizes the image taking to fit the width of the image into the display window.<br>
**50%** – it resizes the images to the 50% of its original size.<br>
**100%** – it resizes the image to its original size.<br>
**200%** – it resizes the images to 200% of its original size.<br>
**Custom** – introduce a specific percentage to zoom out or zoom in.<br>
To gradually enlarge or reduce the image click the icon with the plus or minus signs.  

![zoom](https://github.com/sscholz-UFZ/FishInspector/blob/docs/docs/Images/Zoom_tool.jpg)
 

Click the ![orientation](https://github.com/sscholz-UFZ/FishInspector/blob/docs/docs/Images/orientation_icon.jpg) icon in the Zoom box to display the fish to its standard orientation. In case the fish is not displayed in the standard orientation after activation of the  icon, the orientation of the fish has not been identified correctly. In this case the fish orientation feature has to be corrected manually (see ...). 

> Standard orientation is defined as the fish with the head on the left, tail on the right and yolk sac on the bottom part. 


