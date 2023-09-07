//Global variables
//Channel properties
var nchannels=4;
var slices=newArray("Phase", "Green", "DNA", "N/A");
var phaseslice=-1;
var dnaslice=-1;
var greenslice=-1;
var redslice=-1;
var channelsinitialised=false;
//Width and height of the cropped image
var w=323;
var h=162;
//Inset properties
var squareSampleWidth=20;
var squareZoomFactor=2;
var lineSampleWidth=15;
var lineZoomFactor=1.5;
//Montage settings
var montageTypes=newArray("Overlay All", "Green", "N/A", "N/A");
var dnaColour="Auto";
var nmontages=2;
var montagesinitialised=false;

//Get channel order settings
function getImageChannelSettings() {
	choices=newArray("Phase", "DNA", "Green", "Red", "N/A");
	Dialog.create("Image Channel Settings");
	for (i=0; i<4; i++) {
		Dialog.addChoice("Slice "+i+1+":", choices, slices[i]);
	}
	//Dialog.addMessage("This macro requires Phase and DNA channels, and up to 2 fluorescent channels.");
	//Dialog.addMessage("If your images are only 2 or 3 slices then select N/A as appropriate.");
	Dialog.show();
	for (i=0; i<4; i++) {
		slices[i]=Dialog.getChoice();
	}
	//Derive parameters, number of channels and their indices
	i=0;
	phaseslice=-1;
	dnaslice=-1;
	greenslice=-1;
	redslice=-1;
	nextslice=slices[i];
	while (nextslice!="N/A" && i<4) {
		if (slices[i]=="Phase") {
			phaseslice=i+1;
		} else if (slices[i]=="DNA") {
			dnaslice=i+1;
		} else if (slices[i]=="Green") {
			greenslice=i+1;
		} else if (slices[i]=="Red") {
			redslice=i+1;
		}
		i++;
		if (i<4) {
			nextslice=slices[i];
		}
	}
	nchannels=i;
	//Don't force Phase and DNA
	//if (phaseslice==-1 || dnaslice==-1) {
	//	exit("Error: A Phase and DNA channel must be selected and slices must be filled in order from first to fourth.");
	//}
	if (nchannels==0) {
		exit("Error: At least one channel must be selected and filled in order from first to fourth, with any 'N/A's at the end.");
	}
	channelsinitialised=true;
}

macro "Image Channel Settings" {
	getImageChannelSettings();
}

macro "---- [for getting cells from a field of view] ----" {
}

//Cell cropper macro
macro "Cell Cropper [c]" {
	//Check initialisation
	if (channelsinitialised==false) {
		getImageChannelSettings();
	}
	//Check that a line selection exists, and error if not
	if (selectionType()!=5) {
		exit("Error: Requires a line selection.\r\nUse the line selection tool to draw a line from the cell anterior to posterior.\r\nThis defines the centre and orientation of cropping.")
	}
	//Get selection coordinates and record image title
	getSelectionCoordinates(x, y);
	title=getTitle();
	//Tidy image title (only works for tiff files!)
	if (endsWith(title, ".tif")==true) {
		title=substring(title, 0, lengthOf(title)-lengthOf(".tif"));
	}
	//Make a copy of the input image to process
	run("Duplicate...", "duplicate");
	src=getImageID();
	//Calculate rotation angle and crop centre
	angle=180*atan2(y[1]-y[0], x[1]-x[0])/PI;
	angle=-angle;
	cx=(x[1]+x[0])/2;
	cy=(y[1]+y[0])/2;
	//Expand canvas size to add padding for cells near the image edge, then pre-crop, rotate and crop
	run("Canvas Size...", "width="+getWidth()+w*2+" height="+getHeight()+w*2+" position=Center");
	makeRectangle(cx-w+w, cy-w+w, w*2, w*2);
	run("Duplicate...", "duplicate");
	run("Rotate... ", "angle="+angle+" grid=1 interpolation=Bicubic stack");
	makeRectangle(w/2, w-h/2, w, h);
	run("Crop");
	//Record result ID
	res=getImageID();
	selectImage(src);
	makeRectangle(w, w, getWidth()-w*2, getHeight()-w*2);
	run("Crop");
	close();
	//Select the output and change name to have a nice centre and angle name
	selectImage(res);
	rename(""+title+"_x"+cx+"-y"+cy+"-a"+angle);
}

//Set cell cropper settings
macro "Cell Cropper Settings" {
	Dialog.create("Cell Cropper Settings");
	Dialog.addNumber("Width (px):", w);
	Dialog.addNumber("Height (px):", h);
	Dialog.show();
	w=Dialog.getNumber();
	h=Dialog.getNumber();
}

macro "---- [does something to the current image] ----" {
}

//Flip Vertically
macro "Flip vertically [v]" {
	seltype="none";
	if (selectionType()==0) {
		seltype="rectangle";
		getSelectionBounds(x, y, w, h);
	} else if (selectionType()==2) {
		seltype="polygon";
		getSelectionCoordinates(x, y);
	} else if (selectionType()==5) {
		seltype="line";
		getSelectionCoordinates(x, y);
	} else if (selectionType()==6) {
		seltype="polyline";
		getSelectionCoordinates(x, y);
	} else if (selectionType()==10) {
		seltype="point";
		getSelectionCoordinates(x, y);
	}
	run("Select None");
	run("Flip Vertically");
	if (seltype=="rectangle") {
		makeRectangle(x, getHeight()-(y+h), w, h);
	} else if (seltype!="none") {
		nx=newArray(lengthOf(x));
		ny=newArray(lengthOf(y));
		for (i=0; i<lengthOf(x); i++) {
			ny[i]=getHeight()-y[i];
			nx[i]=x[i];
		}
		if (seltype=="polygon") {
			makeSelection("polygon", nx, ny);
		} else if (seltype=="line") {
			makeSelection("line", nx, ny);
		} else if (seltype=="polyline") {
			makeSelection("polyline", nx, ny);
		} else if (seltype=="point") {
			makeSelection("point", nx, ny);
		}
	}
}

//Single Image Quick Contrast
macro "Single image quick contrast" {
	singleQuickContrast();
}

macro "---- [does something to all open images] ----" {
}

//Quick contrast
function fluorescenceAutocontrast() {
	setLut();
	getRawStatistics(area, mean, min, max);
	run("Enhance Contrast", "saturated=0.01");
	getMinAndMax(cmin, cmax);
	setMinAndMax(mean, cmax);
}

function fluorescenceAutocontrastMode() {
	getRawStatistics(area, mean, min, max, stdev, histo);
	maxh=0;
	maxi=0;
	for (i=0; i<lengthOf(histo); i++) {
		if (histo[i]>maxh) {
			maxh=histo[i];
			maxi=i;
		}
}
	run("Enhance Contrast", "saturated=0.01");
	getMinAndMax(cmin, cmax);
	setMinAndMax(maxi, cmax);
}

function singleQuickContrast() {
	//Check initialisation
	if (channelsinitialised==false) {
		getImageChannelSettings();
	}
	//Record image selection to restore later
	if (is("composite")==false) {
		run("Stack to Hyperstack...", "order=xyczt(default) channels="+nSlices()+" slices=1 frames=1 display=Color");
	}
	seltype="none";
	if (selectionType()==0) {
		seltype="rectangle";
		getSelectionBounds(x, y, w, h);
	} else if (selectionType()==2) {
		seltype="polygon";
		getSelectionCoordinates(x, y);
	} else if (selectionType()==5) {
		seltype="line";
		getSelectionCoordinates(x, y);
	} else if (selectionType()==6) {
		seltype="polyline";
		getSelectionCoordinates(x, y);
	} else if (selectionType()==10) {
		seltype="point";
		getSelectionCoordinates(x, y);
	}
	//Do contrast on centre region of image
	makeRectangle(getWidth()/4, getHeight/4, getWidth()/2, getHeight()/2);
	Stack.setDisplayMode("composite");
	//Do phase autocontrast
	setSlice(phaseslice);
	run("Grays");
	getRawStatistics(area, mean, min, max, stdev);
	setMinAndMax(mean-stdev*3, mean+stdev*3);
	//Do fluorescent channel auto contrast
	setSlice(dnaslice);
	fluorescenceAutocontrastMode();
	if (greenslice!=-1) {
		setSlice(greenslice);
		fluorescenceAutocontrastMode();
	}
	if (redslice!=-1) {
		setSlice(redslice);
		fluorescenceAutocontrastMode();
	}
	//Restore original selection
	run("Select None");
	if (seltype=="rectangle") {
		makeRectangle(x, y, w, h);
	} else if (seltype=="polygon") {
		makeSelection(seltype, x, y);
	} else if (seltype=="line") {
		makeLine(x[0], y[0], x[1], y[1]);
	} else if (seltype=="polyline") {
		makeSelection(seltype, x, y);
	} else if (seltype=="point") {
		if (lengthOf(x)==1) {
			makePoint(x[0], y[0]);
		} else {
			makeSelection("points", x, y);
		}
	}
	setSlice(2);
}

function quickContrast() {
	for (i=0; i<nImages(); i++) {
		selectImage(i+1);
		singleQuickContrast();
	}
}

//Quickly set an auto-contrast for all open images
macro "Quick Contrast [q]" {
	quickContrast();
}

//Save and close all open images in a user-selected directory
macro "Save All To Directory and Close [a]" {
	//Get an output directory
	path=getDirectory("");
	//Record IDs of open images
	imgs=newArray(nImages());
	for (i=0; i<lengthOf(imgs); i++) {
		selectImage(i+1);
		imgs[i]=getImageID();
	}
	//For each ID, select window, save and close.
	for (i=0; i<lengthOf(imgs); i++) {
		selectImage(imgs[i]);
		saveAs("TIFF", path+getTitle());
		selectImage(imgs[i]);
		close();
	}
	//Report success
	Dialog.create(lengthOf(imgs)+" Images Saved");
	Dialog.addMessage(lengthOf(imgs)+" images saved as TIFF files in "+path);
	Dialog.show();
}

//Save all images in-place, ie. re-save images which have already been saved.
macro "Save All In-Place and Close [s]" {
	//Record IDs of open images
	imgs=newArray(nImages());
	for (i=0; i<lengthOf(imgs); i++) {
		selectImage(i+1);
		imgs[i]=getImageID();
	}
	//For each ID, select window, save and close.
	for (i=0; i<lengthOf(imgs); i++) {
		selectImage(imgs[i]);
		save("");
		selectImage(imgs[i]);
		close();
	}
	//Report success
	Dialog.create(lengthOf(imgs)+" Images Saved");
	Dialog.addMessage(lengthOf(imgs)+" images saved.");
	Dialog.show();
}

macro "---- [does something to a directory of images] ----" {
}

//Composite settings

//Set LUT function
function setLut() {
	if (phaseslice!=-1) {
		setSlice(phaseslice);
		run("Grays");
	}
	if (dnaslice!=-1) {
		setSlice(dnaslice);
		if (dnaColour=="Auto") {
			if (redslice==-1 || greenslice==-1) {
				run("Magenta");
			} else {
				run("Blue");
			}
		} else if (dnaColour=="Blue") {
			run("Blue");
		} else if (dnaColour=="Magenta") {
			run("Magenta");
		}
	}
	if (greenslice!=-1) {
		setSlice(greenslice);
		run("Green");
	}
	if (redslice!=-1) {
		setSlice(redslice);
		run("Red");
	}
}

//Make montages function
function montageOverlayAll(src) {
	selectImage(src);
	Stack.setDisplayMode("composite");
	chanstr="";
	for (i=0; i<nchannels; i++) {
		chanstr+="1";
	}
	Stack.setActiveChannels(chanstr);
	run("RGB Color");
	tgt=getImageID();
	return tgt;
}
function montageOverlayFluorescence(src) {
	selectImage(src);
	Stack.setDisplayMode("composite");
	chanstr="";
	for (i=0; i<nchannels; i++) {
		if (slices[i]!="Phase") {
			chanstr+="1";
		} else {
			chanstr+="0";
		}
	}
	Stack.setActiveChannels(chanstr);
	run("RGB Color");
	tgt=getImageID();
	return tgt;
}
function montageSingleChannel(src, slice) {
	selectImage(src);
	Stack.setDisplayMode("grayscale");
	setSlice(slice);
	run("RGB Color");
	tgt=getImageID();
	return(tgt);
}

function makeComposite() {
	//Ensure it's in composite mode with no selection
	Stack.setDisplayMode("composite");
	run("Select None");
	cw=getWidth();
	ch=getHeight();
	src=getImageID();
	//As a start, make an overlay of all channels, convert to RGB, and set to full montage canvas size
	tgt=montageOverlayAll(src);
	run("Canvas Size...", "width="+cw*nmontages+" height="+ch+" position=Center-Left");
	selectImage(src);
	//Loop through all montages adding in position
	for (x=0; x<nmontages; x++) {
		if (montageTypes[x]=="Overlay All") {
			tmp=montageOverlayAll(src);
		} else if (montageTypes[x]=="Overlay Fluorescence") {
			tmp=montageOverlayFluorescence(src);
		} else if (montageTypes[x]=="DNA") {
			tmp=montageSingleChannel(src, dnaslice);
		} else if (montageTypes[x]=="Green") {
			tmp=montageSingleChannel(src, greenslice);
		} else if (montageTypes[x]=="Red") {
			tmp=montageSingleChannel(src, redslice);
		} else if (montageTypes[x]=="Phase") {
			tmp=montageSingleChannel(src, phaseslice);
		}
		run("Copy");
		run("Close");
		selectImage(tgt);
		makeRectangle(cw*x, 0, cw, ch);
		run("Paste");
	}
	return tgt;
}

//Process all images saved in a directory and make composite views
macro "Make Montages [m]" {
	//Check initialisation
	if (channelsinitialised==false) {
		getImageChannelSettings();
	}
	if (montagesinitialised==false) {
		makeMontagesSettings();
	}
	//Recurse through directories to make composites
	recursive=true;
	path=getDirectory("");
	files=getFileList(path);
	for (i=0; i<lengthOf(files); i++) {
		if (File.isDirectory(path+files[i])==true && recursive==true) {
			processFolder(path+files[i], recursive);
		} else if (endsWith(files[i], ".tif")==true) {
			//Open, make composite and save
			open(path+files[i]);
			src=getImageID();
			setLut();
			tgt=makeComposite();
			saveAs("PNG", path+files[i]+".png");
			selectImage(tgt);
			close();
			selectImage(src);
			close();
		}
	}
}


//Set montage generation settings
function makeMontagesSettings() {
	choices=newArray("Overlay All", "Overlay Fluorescence", "Phase", "DNA", "Green", "Red", "N/A");
	dnaColours=newArray("Auto", "Blue", "Magenta");
	Dialog.create("Make Montages Settings");
	for (i=0; i<4; i++) {
		Dialog.addChoice("Position "+i+1+":", choices, montageTypes[i]);
	}
	Dialog.addChoice("DNA colour:", dnaColours, dnaColour);
	Dialog.show();
	for (i=0; i<4; i++) {
		montageTypes[i]=Dialog.getChoice();
	}
	dnaColour=Dialog.getChoice();
	i=0;
	nextmontage=montageTypes[i];
	while (nextmontage!="N/A" && i<4) {
		i++;
		if (i<4) {
			nextmontage=montageTypes[i];
		}
	}
	nmontages=i;
	if (nmontages==0) {
		exit("Error: At least one montage type must be selected and filled in order from first to fourth, with any 'N/A's at the end.");
	}
	montagesinitialised=true;
}

macro "Make Montages Settings" {
	makeMontagesSettings();
	montagesinitialised=true;
}

//Generate inset images
function recursiveInset(path, suffix) {
	files=getFileList(path);
	for (i=0; i<lengthOf(files); i++) {
		if (File.isDirectory(path+files[i])==true) {
			recursiveInset(path+files[i], suffix);
		} else if (endsWith(files[i], ".tif")==true && endsWith(files[i], suffix+".tif")==false) {
			open(path+files[i]);
			if (selectionType()!=-1) {
				if (selectionType()==10) {
					doSquareInset(squareSampleWidth, squareZoomFactor);
				} else if (selectionType()==5) {
					doLineInset(lineSampleWidth, lineZoomFactor);
				}
				saveAs("TIFF", path+substring(files[i], 0, lengthOf(files[i])-lengthOf(".tif"))+"_"+suffix+".tif");
			}
			close();
		}
	}
}

function doSquareInset(r, m) {
	getSelectionCoordinates(x, y);
	setPasteMode("Copy");
	for (i=0; i<nSlices(); i++) {
		setSlice(i+1);
		makeRectangle(x[0]-r, y[0]-r, r*2, r*2);
		run("Duplicate...", " ");
		run("Size...", "width="+round(r*m*2)+" height="+round(r*m*2)+" constrain average interpolation=None");
		run("Copy");
		close();
		makeRectangle(getWidth()-round(r*m*2)-1, getHeight()-round(r*m*2)-1, round(r*m*2)+1, round(r*m*2)+1);
		setColor(pow(2, 16)-1);
		fill();
		makeRectangle(getWidth()-round(r*m*2), getHeight()-round(r*m*2), round(r*m*2), round(r*m*2));
		run("Paste");
	}
}

function doLineInset(r, m) {
	getSelectionCoordinates(x, y);
	setPasteMode("Copy");
	src=getImageID();
	Stack.setDisplayMode("grayscale");
	run("Straighten...", "title=tmp line=20 process");
	tw=getWidth();
	run("Size...", "width="+round(tw*m*2)+" height="+round(r*m*2)+" constrain average interpolation=None");
	tmp=getImageID();
	for (i=0; i<nSlices(); i++) {
		selectImage(tmp);
		setSlice(i+1);
		makeRectangle(0, 0, round(tw*m*2), round(r*m*2));
		run("Copy");
		selectImage(src);
		setSlice(i+1);
		makeRectangle(getWidth()-round(tw*m*2)-1, getHeight()-round(r*m*2)-1, round(tw*m*2)+1, round(r*m*2)+1);
		setColor(pow(2, 16)-1);
		fill();
		makeRectangle(getWidth()-round(tw*m*2), getHeight()-round(r*m*2), round(tw*m*2), round(r*m*2));
		run("Paste");
	}
	selectImage(tmp);
	close();		
}

macro "Generate Detail Insets [d]" {
	path=getDirectory("");
	suffix="inset";
	recursiveInset(path, suffix);
}

//Set inset image settings
macro "Generate Detail Insets Settings" {
	Dialog.create("Inset Images Settings");
	Dialog.addMessage("Square insets from point selections:");
	Dialog.getNumber("Sampled width (px):", squareSampleWidth);
	Dialog.getNumber("Zoom factor:", squareZoomFactor);
	Dialog.addMessage("Rectangle insets from line selections:");
	Dialog.getNumber("Sampled width (px):", lineSampleWidth);
	Dialog.getNumber("Zoom factor:", lineZoomFactor);
	Dialog.show();
	squareSampleWidth=Dialog.getNumber();
	squareZoomFactor=Dialog.getNumber();
	lineSampleWidth=Dialog.getNumber();
	lineZoomFactor=Dialog.getNumber();
}