#delimit;
clear;
macro drop _all;
set more off;
pause on;
/* you use this code to spit out the corrected_ports files */
/*MIN-yang's bit to connect to oracle and set up home directory */  
cd "/home/mlee/Documents/projects/spacepanels/scallop/spatial_project_08052016";
quietly do "/home/mlee/Documents/Workspace/technical folder/do file scraps/odbc_connection_macros.do";
global oracle_cxn "conn("$mysole_conn") lower";
global firstyr=1996; 
global lastyr=2016; 




nois _dots 0, title(Extraction Loop running) reps(100);

forvalues yr=$firstyr/$lastyr{ ;
	tempfile new_portlnd;
	local port_files `"`port_files'"`new_portlnd'" "'  ;
	clear;
	odbc load,  exec("select g.filename, g.sideid, g.imgtype,to_char(t.tripid) as tripid, g.serial_num, t.permit, t.portlnd1, t.state1, t.port from vtr.veslog`yr't t, vtr.veslog`yr's s, vtr.veslog`yr'g g, port p
where t.port=p.port and t.tripid=s.tripid and t.tripid=g.tripid and 
s.dealnum not in ('99998', '1', '2', '5', '7', '8') and s.qtykept>=1 and s.qtykept is not null and 
t.state1 in('NH','MA','RI','CT','NJ','DE','MD','VA','PA','NY','DC','ME', 'NC') and 
(t.portlnd1 like '%OTHER%')
order by t.permit, g.serial_num, t.state1, t.port, t.portlnd1;") $oracle_cxn;
	quietly count;
	if r(N)==0{;
	set obs 1;
	};
	gen dbyear=`yr';
	quietly save `new_portlnd';

	nois _dots `yr' 0    ; 

	
};

dsconcat `port_files';
tempfile pp1;
destring tripid, replace;
save `pp1', replace;



#delimit;
use "veslog_species_huge.dta", clear;
drop if tripid==.;
merge m:1 portlnd1 state1 using "/home/mlee/Documents/projects/spacepanels/port data/Ports_background_Info/communities_cleaned3.dta", keep(1);

drop _merge;
rename portlnd1 portlnd1_raw;
rename state1 state1_raw;
keep tripid permit dbyear date ;
collapse (first) date, by(tripid permit dbyear);
save "work_portclean.dta", replace ;


merge 1:m tripid permit dbyear using `pp1', keep(1 3);

save work_portclean.dta, replace;


/*assemble the file names and directories */
gen extension=lower(sideid);
gen full_file= filename + "." + extension;



/* Clean up directory naming
1.  X01 through X05 map to img1 to img5
2.  img7-8
3.  img10-12
4.  don't know what happened to img9 or img6
*/
egen p=sieve(sideid), omit(X);
gen str8 directory= "img"+p;
replace directory="img1" if strmatch(directory, "img01");
replace directory="img2" if strmatch(directory, "img02");
replace directory="img3" if strmatch(directory, "img03");
replace directory="img4" if strmatch(directory, "img04");
replace directory="img5" if strmatch(directory, "img05");
replace directory="img7-8" if strmatch(directory, "img07");
replace directory="img7-8" if strmatch(directory, "img08");
replace directory="img10-12/img10" if strmatch(directory, "img10");
replace directory="img10-12/img11" if strmatch(directory, "img11");
replace directory="img10-12/img12" if strmatch(directory, "img12");

save work_portclean.dta, replace;


/********************************************************************/
/********************************************************************/
/*If we don't need to actually get the image files, we can comment this out. */
/********************************************************************/
/********************************************************************/


/*
/* loop over the "full_files".  Copy them from the network into our working directory.  give them the name PPPPPP_SSSSSSSS.tif*/

/* I've set the variable retrieved =1 when the file is retrieved.
I run "capture confirm" before copying. This checks to see if the file exists. If the file exists, it is copied and "retrieved" is set to zero.  Otherwise, nothing happens.
This prevents the loop from breaking.
*/
*/


#delimit;
gen retrieved=0;
quietly count;
local myobs =r(N);

local net_location "/run/user/1877/gvfs/smb-share:server=net,share=permit_img/";
local mylocation "/home/mlee/Documents/projects/spacepanels/scallop/image_checkers";

nois _dots 0, title(Loop running) reps(100);

quietly forvalues i=1/`myobs'{;
	local serverdir=directory[`i'];
	local serverfile=full_file[`i'];
	local myperm=permit[`i'];
	local mytripid=tripid[`i'];
	capture confirm file "`net_location'/`serverdir'/`serverfile'";
	if _rc==0{;
	copy "`net_location'/`serverdir'/`serverfile'" "`mylocation'/P`myperm'_T`mytripid'.tif", replace;
	replace retrieved=1 if _n==`i';
	};
	else{;
	display "the file `i' is missing";
	};
	else;
	nois _dots `i' 0     ;
};

save work_portclean.dta, replace;

#delimit;
use work_portclean.dta, replace;
dups tripid, drop terse;
drop _expand;
drop _merge;
keep if retrieved==0;

levelsof tripid if strmatch(filename,"FVTR")==0 , local(mytrips) separate(,);
preserve;

local ratsql1 "select i.docid, blob.imgid, blob.image_blob from avtr.image_scan_blob blob, images i  where i.docid in (`mytrips') and i.imgid=blob.imgid;" ;


odbc load,  exec("`ratsql1'") dsn("cuda") user(mlee) password($mynero_pwd) lower clear;
rename docid tripid;

tempfile t1;

save `t1';
restore;
merge m:1 tripid using `t1';


#delimit ;

quietly count;
local myobs =r(N);
local mylocation "/home/mlee/Documents/projects/spacepanels/scallop/image_checkers";

gen q=0;
quietly forvalues i=1/`myobs'{;
	local myperm=permit[`i'];
	local mytripid=tripid[`i'];

replace q=filewrite("`mylocation'/GARFO/P`myperm'_T`mytripid'.tif",image_blob[`i'],1);
};

save garfo_work_portclean.dta, replace;
