

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

use "veslog_species_huge.dta", clear;
drop if tripid==.;
duplicates drop permit tripid dbyear, force;
keep permit tripid dbyear portlnd1 state1 ;
merge m:1 portlnd1 state1 using "/home/mlee/Documents/projects/spacepanels/port data/Ports_background_Info/communities_cleaned3.dta", keep(1 3);
replace state1 = "MD" if strmatch(portlnd1,"SHARPTOWN") & permit==211840	& tripid>=1064348 &  tripid<=1088560;
replace lat=38.5406 if strmatch(portlnd1,"SHARPTOWN");
replace lon=-76.718887 if strmatch(portlnd1,"SHARPTOWN");
drop _merge;
rename portlnd1 new_portlnd1;
drop statefp countyfp cousubfp cousubns;
rename state1 new_state1;
save "ports_corrected.dta", replace ;


/*


quietly forvalues yr=$firstyr/$lastyr{ ;
	tempfile new;
	local NEWfiles `"`NEWfiles'"`new'" "'  ;
	clear;
	odbc load, exec("select distinct t.portlnd1, t.state1, t.permit, t.tripid from vtr.veslog`yr't t 
		where (t.tripcatg=1 or t.tripcatg=4);")  $oracle_cxn;                    
	gen dbyear= `yr';
	quietly save `new';
};
dsconcat `NEWfiles';
	renvarlab, lower;
	destring, replace;
	compress;
	
save vtr_raw.dta, replace;
merge 1:1 permit tripid dbyear using "ports_corrected.dta";
keep if _merge==3;
drop _merge;
gen keeper=0;
replace keeper=1 if portlnd1~=new_portlnd1;
replace keeper=1 if state1~=new_state1;

notes: ports_corrected now contains the "fixed" portlnd1 and state1 ;*/
saveold "ports_corrected.dta", replace version(13);

!st ports_corrected.dta ports_corrected.Rdata -y;

export delimited using "ports_corrected.csv", delimit(",") quote replace;

local net_location "/run/user/1877/gvfs/smb-share:server=net,share=home2/mlee/spatial data/port corrections";
!cp ports_corrected.Rdata "`net_location'/ports_corrected.Rdata";
!cp ports_corrected.csv "`net_location'/ports_corrected.csv";
!cp ports_corrected.dta "`net_location'/ports_corrected.dta";

