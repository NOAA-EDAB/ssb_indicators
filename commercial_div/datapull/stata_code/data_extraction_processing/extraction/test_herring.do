

#delimit;
clear;
macro drop _all;
set more off;
pause off;
/*MIN-yang's bit to connect to oracle and set up home directory */  
cd "/home/mlee/Documents/projects/spacepanels/scallop/spatial_project_aug22";
quietly do "/home/mlee/Documents/Workspace/technical folder/do file scraps/odbc_connection_macros.do";
global oracle_cxn "conn("$mysole_conn") lower";


clear;
local prefix $allprefix;


global firstyr=1996; 
global lastyr=2015; 

global firstdets=$firstyr; 
global lastdets=2003; 
global firstyr=1996; 
global lastyr=2015; 

global firstdets=$firstyr; 
global lastdets=2003; 



global firstders=2004; 
global lastders=$lastyr; 







global scal_prefix SCALpricing;
global allprefix ALLpricing;
timer clear;


global firstders=2004; 
global lastders=$lastyr; 







global scal_prefix SCALpricing;
global allprefix ALLpricing;
timer clear;






quietly forvalues yr=$firstders/$lastders{;
	tempfile new5555;
	local dsp1 `"`dsp1'"`new5555'" "'  ;
	clear;
	odbc load,  exec("select spplndlb as landings, sppvalue as value, county, nespp3, state, port, month, day, year from cfders`yr' 
		where spplndlb is not null and nespp3=168
		and spplndlb>=1 and sppvalue/spplndlb<=40  
		;") $oracle_cxn;
	renvarlab, lower;
	destring, replace;
	compress;

	
	quietly save `new5555';
};

quietly forvalues yr=$firstdets/$lastdets{;
	tempfile nes321;
	local dsp2 `"`dsp2'"`nes321'" "'  ;
	clear;
	odbc load,  exec("select spplndlb as landings, sppvalue as value, county, nespp3, state, port, month, day, year from cfdets`yr' 
		where spplndlb is not null and nespp3=168
		and spplndlb>=1 and sppvalue/spplndlb<=40  
		;") $oracle_cxn;
	renvarlab, lower;
	destring, replace;
	compress;

	
	quietly save `nes321';
};




dsconcat `dsp1' `dsp2';

	renvarlab, lower;
	destring, replace	;
	compress;

gen date=mdy(month, day, year);
format date %td;
compress;
	


preserve;
collapse (sum) landings value, by(date);
gen price=v/l;
rename l agg_l ;
rename v agg_v;
tempfile t1;
save `t1';



restore;

merge m:1 date using `t1';



preserve;
gen monthly=tm(date);
collapse (sum) landings value, by(monthly);
gen price=v/l;
rename l agg_l ;
rename v agg_v;
tempfile t2;
save `t2';




