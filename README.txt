
This document contains notes about BIGFUNC.m written by Selena Khoury in 2018

BIGFUNC is an image analysis code written to analyze 2D images from the OCT and calculate displacement when hydrostatic pressure is applied. The images from each trial should be in separate folders. The function takes as an input 'file_dir' which should be a string representing the path to the image directory.

Ex. BIGFUNC('/Users/Nina/Documents/Trial_102018') on Mac or Linux
    BIGFUNC('\Users\Nina\Documents\Trial_102018') on Windows 
    
It does not matter whether or not you include a file separator at the end of the string.

Ex. BIGFUNC('/Users/Nina/Documents/Trial_102018/')
    BIGFUNC('\Users\Nina\Documents\Trial_102018\')


It is assumed that all images in the same directory were taken with the same settings and have the same size and range.

The function also assumes the image order. The images are currently sorted based on the pressure cycle run using the syringe pump system I built over the summer.

If the pressure range is-       P_min: P_inc : P_max
Images are taken in the following order-        0:P_inc:P_max, P_min:P_inc:0
This  is how the current code sorts the images
If the stepper motor is running the opposite way, the order is swapped-  0:P_inc:P_min, P_max:P_inc:0
So be mindful of this

You will be asked to input the pressure min, max, and increment, then the image structure will be created and saved in the image directory as image_data.mat and you will not need to go through this process the next time the function is run using this image directory.

You will then need to choose points to use for analysis. The points can be taken from a previous result structure if it exists, allowing you to run the function several times with the same points, changing whatever other parameters you need to. Otherwise, you can manually select points from the scaled zero image (image.preview).

Lastly, you will be asked to input a save name and comments for the data. The image structure, results structure, and comments string will be saved as a .mat file in the image directory. 


image structure:

image.directory
	path to image file directory
image.pix [.x, .z]
	number of pixels (Size from header file)
image.pix_scaled [.x, .z]
	size of scaled image in pixels
image.range_um [.x, .z]
	range in um of image (Range from header file)
image.pix2um [.x, .z]
	size of each pixel in um (range_um/pix)     
image.preview
	scaled zero image for choosing points and plotting results
image.data {images} (z-data, x-data)
	intensity data, normalized, unscaled, sorted [0, minP:maxP]
image.pressures
	pressure of each image in order


results structure

results.pts [.x,.z]
	chosen points for unscaled image data matrix
results.pts_scaled [.x,.z]
	chosen points from scaled image
results.ref_size [frac,x,z]
	reference image crop size, frac is fraction of original image size (before interp)
results.temp_size [frac,x,z]
	template image crop size, frac is fraction of reference image size (before interp)
results.interp_step [.x,.z]
	interpolation step 
results.pix [.x,.z]
	new interpolated image size in pixels
results.pix_scaled [.x,.z]
	new interpolated image size in scaled pixels
results.pix2um [.x,.z]
	new interpolated pixel size in um
results.cc (pressure, point)
	max correlation coefficient for each image correlation
results.offset [.x,.z] (pressure, point)
	offset at each pressure for each point in um
