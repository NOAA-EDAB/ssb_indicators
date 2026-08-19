
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









quietly forvalues yr=$firstyr/$lastyr{ ;
    tempfile new12;
    local scalVESfiles `"`scalVESfiles'"`new12'" "'  ;
    clear;
    odbc load, exec("select t.permit, t.tripid, p.plan, p.cat from vtr.veslog`yr't t, vps_fishery_ner p
        where t.permit=p.vp_num and trunc(t.datelnd1) between trunc(p.start_date) and trunc(p.end_date) 
		and p.plan in ('SC','SCG','SG','LGC');") $oracle_cxn;  
    gen dbyear=`yr';
		quietly count;
	if r(N)==0{;
	set obs 1;
	};

    quietly save `new12';
};
dsconcat `scalVESfiles';
