Code for reading tiny image data
Rob Fergus & Antonio Torralba, 19th Aug 2009
fergus@cs.nyu.edu, torralba@csail.mit.edu
--------------------------------------------

Overview
--------
The 79 million images are stored in one giant binary file, 227Gb in
size. The metadata accompanying each image is also in a single giant
file, 57Gb in size. To read images/metadata from these files, we have
provided some Matlab wrapper functions.

There are two versions of the functions for reading image data:

(i) loadTinyImages.m - plain Matlab function (no MEX), runs under
32/64bits. Loads images in by image number. Use this by default.

(ii) read_tiny_big_binary.m - Matlab wrapper for 64-bit MEX
function. A bit faster and more flexible than (i), but requires a 64-bit machine.

There are two types of annotation data:

(i) Manual annotation data, sorted in annotations.txt, that holds the
label of images manually inspected to see if image content agrees with
noun used to collect it. Some other information, such as search
engine, is also stored. This data is available for only a very small
portion of images.

(ii) Automatic annotation data, stored in tiny_metadata.bin,
consisting of information relating the gathering of the image,
e.g. search engine, which page, url to thumbnail etc. This data is
available for all 79 million images.

Requirements
------------

- Around 400Gb of disk space.

- If you want to use the MEX versions of the code for reading in the
  data, you will need a 64-bit machine. But for most purposes, the
  Matlab implementation (loadTinyImages.m) will work perfectly well. 
  To discover if you have a 32/64bit machine, type 'uname -a' in an xterm (if using linux). 


Files
-----

The .tgz file should contain 10 files

1. loadTinyImages.m -- read tiny image data, pure Matlab version.
2. loadGroundTruth.m -- read annotations.txt file holding manual annotations
3. read_tiny_big_binary.m -- read tiny image data, 64-bit Matlab/MEX version
4. read_tiny_big_metadata.m -- read tiny image metadata, 64-bit Matlab/MEX version
5. read_tiny_binary_big_core.c -- 64-bit MEX source code for image reading
6. read_tiny_metadata_big_core.c -- 64-bit MEX source code for metadata reading
7. compute_hash_function.m -- utility function to do fast string searching
                 as used by read_tiny_big_binary.m and read_tiny_big_metadata.m
8. fast_str2num.m -- utility function for read_tiny_big_metadata.m
9. annotations.txt -- text file holding list of annotated images
10. README.txt -- this file

Separately, you should have downloaded the following files

1. tiny_images.bin - 227Gb file holding 79,302,017 images
2. tiny_metadata.bin - 57Gb file holding metadata for all 79,302,017 images
3. tiny_index.mat - 7Mb file holding index info, including:
      word - cell array of all 75,846 nouns for which we have images in tiny_images.bin
      num_imgs - vector with #images per noun for all 75,846 nouns		  
 

Preliminaries
-------------
Before the functions can be used you must do two things:

1. Set the absolute paths to the binary files in the Matlab functions.
There are a total of 7 lines that must be set:

   (i) loadTinyImages.m, line 14 -- set path to tiny_images.bin file
  (ii) read_tiny_big_binary.m, line 40 -- set path to tiny_images.bin file  
 (iii) read_tiny_big_binary.m, line 42 -- set path to tiny_index.mat file   
  (iv) read_tiny_big_metadata.m, line 63 -- set path to tiny_metadata.bin file   
   (v) read_tiny_big_metadata.m, line 65 -- set path to tiny_index.mat file  
(vi) read_tiny_gist_binary.m, line 36 -- set path to tiny_index.mat file 
(vii) read_tiny_gist_binary.m, line 38 -- set path to tiny_metadata.bin file  

2. If using the MEX versions, they must be compiled with the commands:
   (i)	   mex read_tiny_binary_big_core.c
  (ii)     mex read_tiny_metadata_big_core.c
 (iii)     mex read_tiny_binary_gist_core.c



Usage
-----
-----

Here are some examples of the scripts in use. Please look at the
comments at the top of each file for more extensive explanations.

loadTinyImages.m 
---------------
% load in first 10 images from 79,302,017 images
img = loadTinyImages([1:10]);

% load in 10 images at random 
q = randperm(79302017);
img = loadTinyImages(q(1:10));
%% N.B. function does NOT sort indices, so sorting beforehand would
%% improve speed.


loadGroundTruth.m
-----------------
% read in contents of annotation.txt file
[imageFileName, keyword, correct, engine, ind_engine, image_ndx]=loadGroundTruth;
%%% the labeling convention in correct is:
% -1 = Incorrect, 0 = Skipped, 1 = Correct
% Note that this different to the 'label' field produced by 
% read_tiny_big_metadata below (meaning of -1 and 0 are swapped)
% but the annotation.txt file information should be used in preference to
% that from read_tiny_big_metadata.m


---------------------------------------------------------------------

64-bit MEX versions:

read_tiny_big_binary.m
----------------------

% load in first 10 images from 79,302,017 images
img = read_tiny_big_binary([1:10]);
% note output dimension is 3072x10, rather than 32x32x3x10 
% as for loadTinyImages.m

% load in first 10 images from noun 'dog';
q = randperm(79302017);
img = read_tiny_big_binary('dog',q(1:10));
% function sorts indices internally for speed

% load in images for different nouns
img = read_tiny_big_binary({'dog','cat','mouse','pig'},{[1:5],[1:2:10],[8 13],[4:-1:1]});

read_tiny_big_metadata.m
----------------------

% load in filenames of first 10 images
data = read_tiny_big_metadata([1:10],{'filename'});

% load in search engine used for
% first 10 images from noun 'aardvark';
data = read_tiny_big_metadata('aardvark',[1:10],{'engine'});


