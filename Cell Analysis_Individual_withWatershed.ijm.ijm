// Detect alphaSMA coherency raw integrated density and intensity levels based on cell shape as determined by the phalloidin staining. A watershed is applied to refine the obtained ROIs.
// By Joao Firmino, PhD
// v0.4

#@ File (label = "Input directory", style = "directory") input
#@ File (label = "Output directory", style = "directory") output
#@ String (label = "File suffix", value = ".czi") suffix

processFolder(input);

// function to scan folders/subfolders/files to find files with correct suffix
function processFolder(input) {
	list = getFileList(input);
	list = Array.sort(list);
	for (i = 0; i < list.length; i++) {
		if(File.isDirectory(input + File.separator + list[i]))
			processFolder(input + File.separator + list[i]);
		if(endsWith(list[i], suffix))
			processFile(input, output, list[i]);
	}
}

function processFile(input, output, file) {
	
	run("Set Measurements...", " area mean integrated display redirect=None decimal=3");
	
	// First step consist in opening an image
	// If file format is TIF, images are split into three 8-bit-channels; you MUST verify that channels only contain the expected signal (i.e. no channel merging)
	open(input+File.separator+file);
		if(suffix==".tif") {
		run("Make Composite");
		run("Properties...");
		}	
	
	// we then duplicate channels of interest required for future steps (Nuclei and Phalloidin)
	selectWindow(file);
	run("Duplicate...", "duplicate channels=3-3 title=Nuclei");	//Change channel here: nuclei
	
	// we duplicate the Phalloidin channel; naming it Phalloidin and selecting the window
	selectWindow(file);
	run("Duplicate...", "duplicate channels=2-2 title=Phalloidin");	//Change channel here: phalloidin

	//we blur the image so we can get outlines of the cell
	run("Gaussian Blur...", "sigma=2");

	// next step consists in applying a Triangle autothreshold to binarise the signal and obtain a mask representing the cell shape
	setAutoThreshold("Triangle dark");
	run("Convert to Mask", "method=Triangle background=Dark calculate black");

	//We now run a watershed function to determine individual cells
	run("Distance Transform Watershed", "distances=[Quasi-Euclidean (1,1.41)] output=[32 bits] normalize dynamic=25.00 connectivity=8"); //change the dynamic value if you wish to readjust how the plugin identifies cells

	//we extract the ROIs from the created label image and save the ROis in a zip file
	run("Label image to ROIs");
	roiManager("Save", output+File.separator+file+".zip");

	// we have the ROIs so all we have to do now is apply them to the signal channel and measure signal intensities
	selectWindow(file);
	getPixelSize(unit, pixelWidth, pixelHeight);
	run("Duplicate...", "duplicate channels=1-1 title=alphaSMA"); //Change channel here: alphaSMA
	rename(file+"-alphaSMA");

	//run OrientationJ and more specifically the coherency analysis
	run("OrientationJ Analysis", "tensor=2.0 gradient=1 hsb=on hue=Orientation sat=Coherency bri=Original-Image coherency=on radian=on ");
	selectWindow("OJ-Coherency-1");
	rename(file+"-Coherency");
	run("Properties...", "unit=micron pixel_width=pixelWidth pixel_height=pixelHeight");
	
	//restore selection and measure the average mean of coherency in the cell shape ROI
	roiManager("SelectAll");
	roiManager("Measure");

	//select the Coherency window and save the file
	selectWindow(file+"-Coherency");
	run("Save", "save=["+output+File.separator+file+"-Coherency.png]");

	//we now measure alphaSMA intensity in the cell shape ROI
	selectWindow(file+"-alphaSMA");
	roiManager("SelectAll");
	roiManager("Measure");

	//we start by counting the number of nuclei in the image
	selectWindow("Nuclei");
	rename(file+"-Nuclei");
	run("Gaussian Blur...", "sigma=15");
	run("Save", "save=["+output+File.separator+file+"-NucleiDetection.png]");
	run("Find Maxima...", "prominence=20 output=Count");

	//save original file with ROIs 
	selectWindow(file);
	roiManager("Show All without labels");
	run("From ROI Manager");
	run("Overlay Options...", "stroke=yellow width=4 fill=none apply");
	run("Flatten");
	run("Save", "save=["+output+File.separator+file+"-ROIs.png]");
	
	// before we move on to the next image we clear the ROI manager of all the previously identified ROIs and all open windows
	roiManager("Delete");
	run("Close All");
	
}

	saveAs("alphaSMAResults", output+File.separator+"alphaSMA-Results.csv");
	run("Clear Results");
