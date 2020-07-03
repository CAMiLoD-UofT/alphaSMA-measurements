// Detect alphaSMA coherency raw integrated density and intensity levels based on cell shape as determined by the user
// By Joao Firmino, PhD
// v0.3

#@ File (label = "Input directory", style = "directory") input
#@ File (label = "Output directory", style = "directory") output
#@ String (label = "File suffix", value = ".tif") suffix

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
	
	run("Set Measurements...", " mean integrated display redirect=None decimal=3");
	
	// First step consist in opening an image
	// If file format is TIF, images are split into three 8-bit-channels; you MUST verify that channels only contain the expected signal (i.e. no channel merging)
	open(file);
	if(suffix==".tif") {
		run("Make Composite");
	}	
	
	// we then duplicate channels of interest required for future steps (Nuclei and Phalloidin)
	selectWindow(file);
	run("Duplicate...", "duplicate channels=3-3 title=Nuclei");	//Change channel here: nuclei
	
	selectWindow(file);
	run("Duplicate...", "duplicate channels=2-2 title=Phalloidin");	//Change channel here: phalloidin

	//we blur the Phalloidin image so we can get outlines of the cell
	selectWindow("Phalloidin");
	run("Gaussian Blur...", "sigma=2");

	//In order to obtain a preview image for the user to define ROIs 
	run("Merge Channels...", "c2=Phalloidin c4=Nuclei create keep");
	rename("Preview");
	run("RGB Color");

	roiManager("show all");

	waitForUser("Draw ROIs around single cells using the freehand selection tool; press the 't' key after every ROI and 'OK' once done with the image.");

	//save all ROIs defined by user
	roiManager("Save", output+File.separator+file+".zip");

	// we have the ROIs so all we have to do now is apply them to the channels of interest
	selectWindow(file);
	run("Duplicate...", "duplicate channels=1-1 title=alphaSMA");	//Change channel here: alphaSMA
	selectWindow("alphaSMA");
	rename(file+"-alphaSMA");

	//run OrientationJ and more specifically the coherency analysis
	run("OrientationJ Analysis", "tensor=1.0 gradient=0 hsb=on hue=Orientation sat=Coherency bri=Original-Image coherency=on radian=on ");
	selectWindow("OJ-Coherency-1");
	rename(file+"-Coherency");

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

	//we now count the number of nuclei in the image
	selectWindow("Nuclei");
	rename(file+"-Nuclei");
	run("Gaussian Blur...", "sigma=10");
	run("Find Maxima...", "prominence=20 output=Count");

	//save original file with ROIs 
	selectWindow(file);
	roiManager("Show All without labels");
	run("From ROI Manager");
	run("Overlay Options...", "stroke=yellow width=4 fill=none apply");
	run("Flatten");
	run("Save", "save=["+output+File.separator+file+"-ROIs.png]");

	// before we move on to the next image we should clear the ROI manager of all the previously identified ROIs and all open windows
	roiManager("Delete");
	run("Close All");

}
	saveAs("alphaSMAResults", output+File.separator+"alphaSMA-Results.csv");
	run("Clear Results");