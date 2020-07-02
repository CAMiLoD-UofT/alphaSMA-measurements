// Detect alphaSMA coherency raw integrated density and intensity levels based on cell shape as determined by the phalloidin staining
// By Joao Firmino, PhD
// v0.2

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
	
	run("Set Measurements...", " mean integrated limit display redirect=None decimal=3");
	
	//First step consist in opening an image
	open(file);

	// we then duplicate channels of interest required for future steps (Nuclei and Phalloidin)
	selectWindow(file);
	//Change channel here: nuclei
	run("Duplicate...", "duplicate channels=3-3 title=Nuclei");
	
	// we duplicate the Phalloidin channel; naming it Phalloidin and selecting the window
	selectWindow(file);
	//Change channel here: phalloidin
	run("Duplicate...", "duplicate channels=2-2 title=Phalloidin");

	//we blur the image so we can get outlines of the cell
	run("Gaussian Blur...", "sigma=2");

	// next step consists in applying a Triangle autothreshold to binarise the signal and obtain a mask representing the cell shape
	//run("Threshold...");
	setAutoThreshold("Triangle dark");
	run("Convert to Mask", "method=Triangle background=Dark calculate black");

	// we now proceed to identify all ROIs with an area between 40 and infinite micron2 - this is the only step where the user induces some bias!!
	run("Analyze Particles...", "size=40-Infinite add");
	roiManager("Save", output+File.separator+file+".zip");

	// we have the ROIs with the appropriate size so all we have to do now is apply them to the signal channel and measure signal intensities
	selectWindow(file);
	//Change channel here: alphaSMA
	run("Duplicate...", "duplicate channels=1-1 title=alphaSMA");
	rename(file+"-alphaSMA");

	//run OrientationJ and more specifically the coherency analysis
	run("OrientationJ Analysis", "tensor=2.0 gradient=1 hsb=on hue=Orientation sat=Coherency bri=Original-Image coherency=on radian=on ");
	selectWindow("OJ-Coherency-1");
	rename(file+"-Coherency");
	
	//restore selection and measure the average mean of coherency in the cell shape ROI
	roiManager("SelectAll");
	roiManager("Measure");

	//select the Coherency window and save the file
	selectWindow(file+"-Coherency");
	run("Save", "save=["+output+File.separator+file+"-Coherency.tif]");

	//we now measure alphaSMA intensity in the cell shape ROI
	selectWindow(file+"-alphaSMA");
	roiManager("SelectAll");
	roiManager("Measure");

	//we start by counting the number of nuclei in the image
	//Change channel here: nuclei
	selectWindow("Nuclei");
	rename(file+"-Nuclei");
	run("Gaussian Blur...", "sigma=5");
	run("Find Maxima...", "prominence=20 output=Count");

	//save original file with ROIs 
	selectWindow(file);
	roiManager("Show All without labels");
	run("From ROI Manager");
	run("Overlay Options...", "stroke=yellow width=4 fill=none apply");
	run("Flatten");
	run("Save", "save=["+output+File.separator+file+"-ROIs.tif]");
	
	// before we move on to the next image we should clear the ROI manager of all the previously identified ROIs and all open windows
	roiManager("Delete");
	run("Close All");
}

	saveAs("alphaSMAResults", output+File.separator+"alphaSMA-Results.csv");
	run("Clear Results");