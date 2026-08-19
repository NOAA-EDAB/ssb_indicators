#delimit;
pause on;
cd "/home/mlee/Documents/projects/spacepanels/scallop/spatial_project_aug22";
quietly do "/home/mlee/Documents/Workspace/technical folder/do file scraps/odbc_connection_macros.do";
global oracle_cxn "conn("$mysole_conn") lower";


/* data for surfclam is in a bunch of places 

1995-1999 the data is in SFYYVR (and PR)
2000-2002 is stored in SFYYYYVR (and PR)
2003 to present is stored in SFOQPR and SFOQVR
*/


pause on;
/*sfYYvr has data for 1994-1999 */
clear;
tempfile portregular;
odbc load, exec("select port, portnm, stateabb from port;") $oracle_cxn;  
renvarlab, lower; 
destring, replace;
save `portregular';




local firstyr 96;
local lastyr 99;
tempfile sf9699;
forvalues yr=`firstyr'/`lastyr'{ ;
	tempfile new;
	local files `"`files'"`new'" "'  ;
	clear;
	odbc load,  exec("select dnum, num, to_char(st) as st, to_char(pc) as pc, to_char(cy) as cy, pd, bush, cat from sf`yr'pr;") $oracle_cxn;
	gen dbyear=`yr';
	quietly save `new';
};
clear;
dsconcat `files';
gen year=year(dofc((pd)));
gen month=month(dofc((pd)));
gen day=day(dofc((pd)));

compress;

save `sf9699', replace;


/*sfYYYYrv has data for 2000-2002*/

local firstyr 2000;
local lastyr 2002;

tempfile sf0002;

forvalues yr=`firstyr'/`lastyr'{ ;
	tempfile new2;
	local files2 `"`files2'"`new2'" "'  ;
	clear;
	odbc load,  exec("select dnum, num, to_char(st) as st, to_char(pc) as pc, to_char(cy) as cy, pd, bush, cat from sf`yr'pr;") $oracle_cxn;
	gen dbyear=`yr';
	quietly save `new2';
	destring, replace;
};
clear;
dsconcat `files2';
gen year=year(dofc((pd)));
gen month=month(dofc((pd)));
gen day=day(dofc((pd)));
save `sf0002', replace;
append using `sf9699';

save `sf0002', replace;



clear;
odbc load,  exec("select dnum, num, to_char(st) as st, to_char(pc) as pc, to_char(cy) as cy, pd, bush, cat from sfoqpr") $oracle_cxn;
gen year=year(dofc((pd)));
gen month=month(dofc((pd)));
gen day=day(dofc((pd)));

append using `sf0002' ;

gen nespp3=.;
replace nespp3=769 if cat==1;
replace nespp3=754 if cat==6;

replace pc=substr("00", 1, 2 - length(pc)) + pc;
replace st=substr("00", 1, 2 - length(st)) + st;
replace cy=substr("00", 1, 2 - length(cy)) + cy;



gen str6 port=st+pc+cy;
replace port= "330221" if port=="altcit";
replace port= "330201" if port=="atcity";
replace port= "330201" if port=="atlant";
replace port= "330201" if port=="atlcit";
replace port="310993" if port=="" & year==2011 &  dnum==1379 & num==320409;
destring port, replace;


gen quantity_meat=bush*10;
replace quantity_meat=bush*17 if nespp3==769;

replace quantity_meat=bush*11 if nespp3==754 & substr(string(port),1,2)=="22";


notes: quantity_meat is "meat weights, in pounts".  Surfclam has 17 lbs of meats per bushel, quahog has 10 lbs of meats per bushel. Maine quahog has 11 lbs of meats per bushel;
notes: quantity is in bushels;
notes: price is dollars per bushel;

gen date=mdy(month, day, year);
format date %td;
compress;
destring, replace ;

rename nespp3 myspp ;
rename dnum dealnum;
rename num permit;
merge m:1 port using `portregular', keep(1 3);
drop _merge;

rename portnm portlnd1;
rename stateabb state1;
/* a little bit of cleaning */
quietly do spelling_fixer1.do;
merge m:1 portlnd1 state1 using "communities_cleaned3.dta", keep(1 3);
drop pc cy st;
gen state=floor(port/10000);
gen county=mod(port,100);


/*
drop unknown port codes:
drop if port>=990000;
*/

drop areakey hcounty lat lon placenm placest countyfp statefp cousubfp;
compress;
save "sf_deal.dta", replace;
/*

 What do we need at this point to properly append to the rest of the data?
collapse (sum) qtykept revenue1, by(myspp state year) ; 
save "sfclam96_2013state.dta", replace;

*/





