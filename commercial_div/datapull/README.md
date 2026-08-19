# spacepanels

This is code to extract and dataclean my spacepanels project.

# Quick start

1. Clone the repository
1. Navigate to the /stata_code/project_logistics folder
1. Modify the run_this_once_folder_setup.do to point to your directory.
1. Make sure ODBC is set up https://github.com/minyanglee/ssb-meta/blob/master/odbc/odbc_setup_macros.do
1. Modify the folder_setup_globals.do to point to your directory and your odbc connection do file.
1. Copy the external datasets described in https://github.com/minyanglee/spacepanels/blob/master/data_folder/external/readme.txt
1. Run the file called spatial_wrapper.do


# External Stata commands

1. dsconcat
1. renvarlab

# External Datasets 

The project is self-contained except for the datasets found in /home2/mlee/spacepanels/data_folder/external.

You should copy the contents of this folder to your project's "data_folder/external" folder

# Databases

You will need permissions for

1. CFDERS
1. VESLOG
1. SFCLAM

# Description

The dataset now includes landings from ME to NC.  Landings in other areas are excluded.


# Other things.
The dataset includes (substantially) all landings in VESLOG plus SFCLAM. Some strange/odd observations were excluded.
1.  Recall that VESLOG does not contain 100% coverage of all fish coming from the ocean. 
1.  Giant Bluefin Tuna should probably be dropped from this dataset.

# NOAA Requirements
“This repository is a scientific product and is not official communication of the National Oceanic and Atmospheric Administration, or the United States Department of Commerce. All NOAA GitHub project code is provided on an ‘as is’ basis and the user assumes responsibility for its use. Any claims against the Department of Commerce or Department of Commerce bureaus stemming from the use of this GitHub project will be governed by all applicable Federal law. Any reference to specific commercial products, processes, or services by service mark, trademark, manufacturer, or otherwise, does not constitute or imply their endorsement, recommendation or favoring by the Department of Commerce. The Department of Commerce seal and logo, or the seal and logo of a DOC bureau, shall not be used in any manner to imply endorsement of any commercial product or activity by DOC or the United States Government.”


1. who worked on this project:  Min-Yang
1. when this project was created: Jan, 2021 
1. what the project does: Spacepanels research 
1. why the project is useful:  Code to do research and build data used in other projects.
1. how users can get started with the project: Download and follow the readme
1. where users can get help with your project:  email me or open an issue
1. who maintains and contributes to the project. Min-Yang

# License file
See here for the [license file](License.txt)


