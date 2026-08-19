/* This do file takes the veslog_species dataset and put in into a format that is easy to compute 
the Thiel, Gini and other indices
This breaks the scallop down by plancat

It also gets the data ready for ESDA

THIS FILE ONLY CONSTRUCTS SCALLOP LANDINGS BY PERMIT CATEGORY. 
Therefore, it calls "setup_scallop_for indices" first



*/
#delimit;
clear;
cd "/home/mlee/Documents/projects/spacepanels/scallop/spatial_project_$my_version";

pause on;

global this_year=year(date("$S_DATE","DMY"));
global lastyr=$this_year+2;

do "setup_scallop_for_indices.do";
clear;

use "veslog_species.dta", clear;
keep if myspp==800 & geoid~=.;

gen FY_scal=year;
replace FY_scal=year-1 if month(date)<3;

notes FY_scal: FY_scal is the scallop fishing year (Mar 1- Feb28/29);

drop if year(date)>=$lastyr;
drop if FY_scal<=1995;
drop if FY_scal>=$this_year;

/* encode the types to a categorical variable*/
gen plancat=.;
replace plancat=1 if LADAS==1;
replace plancat=2 if GC==1;
replace plancat=3 if IFQ==1;
replace plancat=4 if NGOM==1;
replace plancat=5 if INC==1;
replace plancat=6 if Nopermit==1;
assert plancat~=.;
collapse (sum) qtykept raw_rev, by(geoid FY_scal plancat);

rename raw revenue;
sort geoid plancat FY;

fillin geoid plancat FY;
replace qtykept=0 if _fillin==1;
replace revenue=0 if _fillin==1;
drop _fillin;
reshape wide qty revenue, i(geoid FY ) j(plancat);


compress;
notes: the "suffix" definitions are 1 LADAS, 2=GC, 3=IFQ, 4=NGOM, 5=INC, 6=Nopermit;
compress;
drop if FY<=1995;
drop if FY>=$this_year;
rename FY year;
xtset geoid year;

/* This tempfile has decomposed scallop revenue by plancat, but HAS NOT yet joined it to the rest of the data */
tempfile scallop_plancat;
save `scallop_plancat', replace;

merge 1:1 geoid year using "portyr_gear_ner.dta";

foreach var of varlist qtykept* revenue*{;
replace `var'=0 if `var'==.;
};
gen check=qtykept1+qtykept2+qtykept3+qtykept4+qtykept5+qtykept6-qtykepts;
assert check>=-1 | year==$this_year;
assert check<=1;
drop check;

save "portyr_gear_ner_plancat.dta", replace;

use `scallop_plancat', clear;
merge 1:1 geoid year using "portyr_gear_ner_core";
keep if core==1;
foreach var of varlist qtykept* revenue*{;
replace `var'=0 if `var'==.;
};
gen check=qtykept1+qtykept2+qtykept3+qtykept4+qtykept5+qtykept6-qtykepts;
assert check>=-1 | year==$this_year;
assert check<=1 ;  /* FIx This */
drop check;

save "portyr_gear_ner_plancat_core.dta", replace;



/* make county_level dataset*/
use "portyr_gear_ner_plancat.dta", clear;
gen state_county=floor(geoid/100000);
drop if state_county==.;
format state_county %05.0f;
collapse (sum) qtykepts revenues qtykeptall revenueall qtykeptother revenueother qtykept1-revenue6, by(state_county year);
xtset state_county year;
gen mark=1 if revenues>=1;
bysort state_county: egen tm=total(mark);
summ tm;
gen core=0;
replace core=1 if tm==r(max);
drop mark tm;
gen check=qtykept1+qtykept2+qtykept3+qtykept4+qtykept5+qtykept6-qtykepts;
assert check>=-1 | year==$this_year;
assert check<=1;
drop check;
gen absolute_ref=1;

save "countyyr_gear_ner_plancat.dta", replace;
keep if core==1;
sort state_county year;
save "countyyr_gear_ner_plancat_core.dta", replace;

/*yearly plancat shares */
use "portyr_gear_ner_plancat.dta", replace;
collapse (sum) qtykept1-revenue6, by(year);
order qty* revenue*, after(year);

egen tq=rowtotal(qtykept*);
egen tr=rowtotal(revenue*);

forvalues i=1/6{;
gen rshare`i'=revenue`i'/tr;
gen qshare`i'=qtykept`i'/tq;
};
keep year rshare* qshare*;
gen absolute_ref=1;

save "plancat_shares_full.dta", replace;
 

/*yearly plancat-core shares */
use "portyr_gear_ner_plancat_core.dta", replace;
collapse (sum) qtykept1-revenue6, by(year);
order qty* revenue*, after(year);

egen tq=rowtotal(qtykept*);
egen tr=rowtotal(revenue*);

forvalues i=1/6{;
gen rshare`i'=revenue`i'/tr;
gen qshare`i'=qtykept`i'/tq;
};

keep year rshare* qshare*;
gen absolute_ref=1;

save "plancat_shares_core.dta", replace;

