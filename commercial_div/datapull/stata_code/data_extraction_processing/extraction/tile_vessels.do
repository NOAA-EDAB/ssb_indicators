#delimit;
clear;
cd "/home/mlee/Documents/projects/spacepanels/scallop/spatial_project_aug22";
quietly do "/home/mlee/Documents/Workspace/technical folder/do file scraps/odbc_connection_macros.do";
global oracle_cxn "conn("$mysole_conn") lower";

global firstyr=2001; 
global lastyr=2015; 

quietly forvalues yr=$firstyr/$lastyr{ ;
    tempfile new12;
    local tileves `"`tileves'"`new12'" "'  ;
    clear;
    odbc load, exec("select t.permit, t.tripid, p.plan, p.cat from vtr.veslog`yr't t, vps_fishery_ner p
        where t.permit=p.vp_num and trunc(t.datelnd1) between trunc(p.start_date) and trunc(p.end_date) 
		and p.plan in ('TLF');") $oracle_cxn;  
    gen dbyear=`yr';
		quietly count;
	if r(N)==0{;
	set obs 1;
	};

    quietly save `new12';
};
dsconcat `tileves';

