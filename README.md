Autolink (Experimental Alpha)
=============================

An OS X Utility App to selectively mirror a file structure via symlinks and folders to another location - for example into your Dropbox. Selective syncing is controlled via hidden files.

![Screenshot](misc/screenshot.png)

## Usage

Select a source and a target folder. Than place hidden files named ".createlink" in any subdirectory of the source folder.
The app will scan for those files and accordingly creates a structure of folders and symlinks in the target folder.

## Example

Here is an example of a source directory that is mirrored into a dropbox excluding the folder "Internal".

Left: Source Folder, Right: Target Folder

![Help](misc/help.png)
