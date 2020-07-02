// Tissue Quantification of Signal
// for Book Chapter
// by Joao Firmino, PhD
// v0.1

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
	
	open(file);
	run("Set Measurements...", " mean integrated limit display redirect=None decimal=3");
	
	//In order to obtain a preview image for the user to define ROIs 
	run("RGB Color");
	rename("Preview");

	waitForUser("Draw ROIs around single cells using the freehand selection tool; press the 't' key after every ROI and 'OK' once done with the image.");
	
	//save all ROIs defined by user
	roiManager("Save", output+File.separator+file+".zip");

	// measure signal intensity of the channel of interest
	selectWindow(file);
	run("Duplicate...", "title=Channel2 duplicate channels=2");
	roiManager("SelectAll");
	roiManager("Measure");
	saveAs("Results", output+File.separator+file+"-Results.csv");

	//close all Windows and clear ROIManager and Results table
	roiManager("Select All");
	roiManager("Delete");
	run("Close All");
	run("Clear Results");
	
}