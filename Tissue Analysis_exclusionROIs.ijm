// Tissue Quantification of alphaSMA intensity levels by manually defining excluded areas of the image
// by Joao Firmino, PhD
// v0.2

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
	
	run("Set Measurements...", " area mean integrated limit display redirect=None decimal=3");
	open(input+File.separator+file);
		if(suffix==".tif") {
		run("Make Composite");
		run("Properties...");
		}	
	
	//In order to obtain a preview image for the user to define ROIs 
	run("RGB Color");
	rename("Preview");
	roiManager("show all without label");
	
	waitForUser("Draw ROIs around vessels and areas you would like to exclude; press the 't' key after every ROI and 'OK' once done with the image.");
	
	//save all ROIs defined by user
	roiManager("Save", output+File.separator+file+".zip");

	//if using threshold for tissue gaps, please remove "/*" and "*/" from the following lines

	/*
	//this threshold step is to detect all black areas within the image - proceed with caution
	selectWindow("Preview");
	run("Color Threshold...");
	waitForUser("Select the appropriate Threshold method - Triangle usually works best - and deselect the Dark Background checkbox. Once happy with the black selection, click on the Select button and afterwards press OK in this dialog box to proceed");
	roiManager("Add");
		
	selectWindow("Preview");
	roiManager("Select All");
	roiManager("Combine");
	run("Select All");
	roiManager("Add");

	nR = roiManager("count");
	
	roiManager("Select", newArray(nR-1,nR-2));
	roiManager("XOR");	
	roiManager("Add");
	*/
	
	//the last ROI to be added (nR-1) should be the one used in the measurements
	
	nR = roiManager("count");
	
	selectWindow(file);
	//Change channel here: alphaSMA
	run("Duplicate...", "title=alphaSMA duplicate channels=1-1");
	rename(file+"-alphaSMA");
	
	// measure signal intensity of the channel of interest
	roiManager("Select", nR-1);
	roiManager("Measure");

	//save original file with ROIs 
	selectWindow(file);
	roiManager("Show All without labels");
	roiManager("Select", nR-1);
	
	run("From ROI Manager");
	run("Overlay Options...", "width=4 fill=none apply");
	run("Flatten");
	
	run("Save", "save=["+output+File.separator+file+"-ROIs.png]");

	//close all Windows and clear ROIManager and Results table
	roiManager("Select All");
	roiManager("Delete");
	run("Close All");
}

	saveAs("Results", output+File.separator+"alphaSMA-Results.csv");
	run("Clear Results");
