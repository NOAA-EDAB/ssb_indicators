/* This do file takes the veslog_species dataset and put in into a format that is easy to compute 
the Thiel, Gini and other indices

It also gets the data ready for ESDA*/

/*
Issues:
1. Year> "current year" caused by data entry errors in VESLOG2014.
2. Landings in dummy GEOIDS <- there are none for scallops
*/

#delimit;
clear;
cd "/home/mlee/Documents/projects/spacepanels/scallop/spatial_project_$my_version";
use "veslog_species.dta", clear;


gen FY_scal=year;
replace FY_scal=year-1 if month(date)<3;

notes FY_scal: FY_scal is the scallop fishing year (Mar 1- Feb28/29);
drop if year(date)>=$lastyr;
drop if FY_scal<=1995;
drop if FY_scal>=$this_year;



/* year, geoid, rev_scallop, qty_scallop, rev_all, qty_all */
gen scallop=0;
replace scallop=1 if myspp==800;
drop if myspp==446 | myspp==447; /* Drop out tilefish and any other species that were not fed. managed in 96*/

collapse (sum) qtykept raw_rev, by(geoid FY_scal scallop);
sort geoid;
rename raw revenue;

/* bring in coordinate data AND extra cousubs from GIS*/
merge m:1 geoid using "/home/mlee/Documents/projects/spacepanels/port data/universe_data.dta";

keep geoid FY scallop qtykept revenue my_id lon lat _merge sort_id;
foreach var of varlist qty revenue{;
	replace `var'=0 if `var'==. & _merge==2;
};

/* Construct a balanced panel with no missing data (zero filled)*/
replace FY=2013 if FY==. & _merge==2;
replace scallop=0 if scallop==. & _merge==2;


drop _merge;
reshape wide qty revenue, i(geoid FY) j(scallop);
foreach var of varlist qtykept* revenue*{;
	replace `var'=0 if `var'==.;
};

rename qtykept1 qtykepts;
rename revenue1 revenues;
gen qtykeptall=qtykepts+qtykept0;
gen revenueall=revenues+revenue0;

rename qtykept0 qtykeptother;
rename revenue0 revenueother;

compress;
drop if FY<=1995;
drop if FY>=$this_year;
rename FY year;
xtset geoid year;
tsfill, full;

foreach var of varlist qtykept* revenue*{;
	replace `var'=0 if `var'==.;
};

foreach var of varlist my_id lon lat sort_id{;
	bysort geoid (my_id): replace `var'=`var'[1] if `var'==.;
};

/* have still have some "made up" geoids corresponding to either (a) inland landings or (b) unknown cousubs from the SCOQ fishery.  These have missing my_id, lon, lat. */

/*make the core port dataset */
gen mark=1 if revenues>=1;
bysort geoid: egen tm=total(mark);
summ tm;
gen core=0;
replace core=1 if tm==r(max);
drop mark tm;
drop if geoid==.;
gen absolute_ref=1;
save "portyr_gear_ner.dta", replace;

keep if core==1;
sort geoid year;

save "portyr_gear_ner_core.dta", replace;



/* make county_level dataset*/
use "portyr_gear_ner.dta", clear;
gen state_county=floor(geoid/100000);
drop if state_county==.;
format state_county %05.0f;
collapse (sum) qtykepts revenues qtykeptall revenueall qtykeptother revenueother, by(state_county year);
xtset state_county year;
gen mark=1 if revenues>=1;
bysort state_county: egen tm=total(mark);
summ tm;
gen core=0;
replace core=1 if tm==r(max);
drop mark tm;
gen absolute_ref=1;

save "countyyr_gear_ner.dta", replace;



keep if core==1;
sort state_county year;
save "countyyr_gear_ner_core.dta", replace;
