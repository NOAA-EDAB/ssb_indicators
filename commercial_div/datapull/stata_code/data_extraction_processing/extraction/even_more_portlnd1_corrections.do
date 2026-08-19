#delimit;
clear;
macro drop _all;
set more off;
pause on;
/*MIN-yang's bit to connect to oracle and set up home directory */  


global my_version 03162016;
cd "/home/mlee/Documents/projects/spacepanels/scallop/spatial_project_$my_version";

quietly do "/home/mlee/Documents/Workspace/technical folder/do file scraps/odbc_connection_macros.do";
global oracle_cxn "conn("$mysole_conn") lower";

#delimit cr
/* Pretend I have a dataset with "filename" and _n is relatively small (4M characters allowed in a macro)*/
clear
use "fixme2.dta", replace
levelsof tripid, local(mytrips) separate(,)
preserve


clear
#delimit ;
odbc load,  exec( "select i.docid, a.* from images i, avtr.image_scan_blob a
	where  i.docid in (`mytrips') and i.imgid=a.imgid;")  dsn("cuda") user(mlee) password($mynero_pwd) lower clear;
tempfile t1;
rename docid tripid;
save `t1';
restore;
merge 1:m tripid using `t1';







/*THIS IS HOW TO WRITE THE FILES*/
cd "./images"

 #delimit;
quietly count;
local myobs =r(N);

gen p=0;
quietly forvalues i=1/`myobs'{;
local p=permit[`i'];
local t=tripid[`i'];
replace p=filewrite("P`p'_T`t'_`i'.pdf",image_blob[`i']);
};


save "fixme2.dta", replace;
