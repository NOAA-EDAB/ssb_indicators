
#delimit;
clear;
macro drop _all;
set more off;
pause off;
/*MIN-yang's bit to connect to oracle and set up home directory */  
cd "/home/mlee/Documents/projects/spacepanels/scallop/spatial_project_aug22";
quietly do "/home/mlee/Documents/Workspace/technical folder/do file scraps/odbc_connection_macros.do";
global oracle_cxn "conn("$mysole_conn") lower";
/* GLOBALS to set up YEARS and OTHER STUFF  
These will get passed to the other do files.*/
global firstyr=1996; 
global lastyr=2015; 

global firstdets=$firstyr; 
global lastdets=2003; 



global firstders=2004; 
global lastders=$lastyr; 









    odbc load, exec("select * from sfclam.sfoqvr;") $oracle_cxn;  
