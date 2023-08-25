# Tryp Image Prep
ImageJ macros assisting trypanosomatid cell microscopy image prep.

**Quickstart**: Download [tryp_cell_image_prep.ijm](https://raw.githubusercontent.com/zephyris/trypimageprep/main/tryp_cell_image_prep.ijm) and install in ImageJ, then look for the new entries in the `Macros` menu.

## Overall workflow

Install the macros using `Plugins > Macros > Install...` and select `tryp_cell_image_prep.ijm` in the file selection dialog. Individual tools will then appear in the `Plugins > Macros` menu.

Open your microscope image. Use the `Cell Cropper` tool to crop cells from the image. Save all the cropped cell images you would like to keep as TIFF files in a directory, using `File > Save As > Tiff...`, or just use `Save and Close All`. You can make nice composites for all files in the directory using `Make Composites From Directory` – the output composites are saved as PNG files in the same directory.

The first time you run a macro it will ask for the order of channels in the image. Phase and DNA channels are strongly recommended, but not required. DNA is assumed to be blue fluorescence (DAPI or Hoechst 33342 fluorescence). Up to an additional two channels (assumed to be Green and Red) can be handled. You can also pre-emptively set this with `Image Channel Settings`.

## Image Channel Settings
This will open a dialog asking for which image slices of your input multi-channel images are Phase, DNA, Green or Red (or N/A). It is important that this is correct to get the correct lookup tables. For example:
 - Slice 1:	Phase
 - Slice 2:	Green
 - Slice 3:	DNA
 - Slice 4:	N/A

The `Image Channel Settings` must be run before other macros, so it knows where to find each channel. It will automatically be run if not run yet in that session, then you can manually run `Image Channel Settings` later if you switch to a set of images with a different order of channels.

## Cell Cropper
Keyboard shortcut: `C`

You first need to make a line selection, from near the cell anterior to the posterior. This will define the angle the cell gets rotated to (line becomes horizontal) and the centre of the cropping (around the centre of the line). Run `Cell Cropper` to make the cropped cell image.

## Cell Cropper Settings
This allows you to set the width and height of the cropped images generated by `Cell Cropper`.

## Flip Vertically
Keyboard shortcut: `V`

Vertically flip the current image. Also transforms a rectangle, polygon, line, polyline or point selection.

## Single Image Quick Contrast
Applies a simple autocontrast function to a single image.

## Quick contrast
Applies a simple autocontrast function to all open images.

Fluorescence channels are set to display image mean (ie. approximately background) to the 1st percentile of signal. Phase contrast is set to display the mean plus and minus three times the standard deviation.

## Save All To Directory and Close
Keyboard shortcut: `A`

This will open a dialog asking for a directory in which to save all open images, then runs through all the open images saving them in the directory then closing them. Images are saved as multi-channel TIFF files, with the same order of channels as the original image.

## Save All In-Place and Close
Keyboard shortcut: `S`

This will runs through all the open images saving them then closing them. Saving is done in-place (ie. in the directory where the image was already saved). If it wasn’t already saved, then a save dialog will be opened for that image. Images are saved as multi-channel TIFF files, with the same order of channels as the original image.

## Make Montages
Keyboard shortcut: `M`

This will open a dialog asking for a directory to process, then processes this directory and all sub-directories, making nice composite views of every TIFF file in these directories. Output composite images are saved as PNG files with the same file name as the TIFF file it was generated from.

## Make Montages Settings
This will open a dialog asking what should appear in each montage position, from left to right. The montage position can be Overlay All (all channels), Overlay Fluorescence (DNA, Green and/or Red, if used), Phase, DNA, Green or Red (or N/A). There can be up to 4 positions, for example:
 - Slice 1:	Overlay All
 - Slice 2:	Green
 - Slice 3:	N/A
 - Slice 4:	N/A

The `Make Montages Settings` must be run before the `Make Montages` macro, so it knows what to put in each position. It will automatically be run if not run yet in that session, then you can manually run `Make Montages Settings` later if you want a different order in the montage.

DNA can be pseudocoloured in a few ways. Automatic behaviour is that fluorescence channel overlays are pseudocoloured blue (DNA), green and red when all are present. If either green or red fluorescence channels are not present then DNA is pseudocoloured magenta for better visibility. Alternatively, you can force blue or magenta.

When shown individually, fluorescence channels are pseudocoloured grey for maximal visibility. To help colourblind readers it is strongly recommended to always show the key fluorescence channels individually, for example:
 - Slice 1:	Overlay All
 - Slice 2:	Green (which will be shown in grayscale)
 - Slice 3:	Red (which will be shown in grayscale)

## Make Detail Insets
Keyboard shortcut: `D`

This will open a dialog asking for a directory to process, then processes all TIFF files in this directory to add a detail inset if there is a selection of the correct type saved in the image. To use this tool you need to make sure that the images were saved with a selection already made.
 * For a single point selection, a square region around the point will be inset in the bottom right corner.
 * For a line selection, a rotated rectangle region around the line will be inset in the bottom right corner.

The images with the inset are saved as TIFF files in the same directory as the source image. You can make composite views

## Make Detail Insets Settings
This will open a dialog where you can set the width around point and line selections which will be used to make the detail inset. The zoom factor is the fold-change increase in size for the inset.
