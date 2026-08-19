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
cd "/home/mlee/Documents/projects/spacepanels/scallop/spatial_project_aug29";
use "veslog_species.dta", clear;

drop FY;
collapse (sum) qtykept raw_rev, by(geoid year myspp);
sort geoid;
rename raw revenue;

/* bring in coordinate data AND extra cousubs from GIS*/
merge m:1 geoid using "/home/mlee/Documents/projects/spacepanels/port data/universe_data.dta", keep (1 3);
keep geoid year myspp qtykept revenue my_id lon lat _merge;
notes: There are some geoid's that did not merge.  Some are "dummy" geoids to retain county level info from SCOQ.  Some are landings in the chesapeake. ;
notes: Some are landings in chester, PA that are not data errors, but are just random.  I'm eventually going to drop Chester.;
notes: year is just year of the date.;
drop _merge;
drop if geoid==.;

/*build a panel of geoid-year (with my_id, lon, lat) that has the revenue and quantity arrayed out */
reshape wide qtykept revenue, i(geoid year)  j(myspp);
tsset geoid year;
tsfill, full;



foreach var of varlist qtyk* revenue*{;
	replace `var'=0 if `var'==.;
};


egen qtykeptall=rowtotal(qtykept*);
egen revenueall=rowtotal(revenue*);
order year geoid lat lon qtykeptall revenueall;

foreach var of varlist my_id lon lat{;
	bysort geoid (my_id): replace `var'=`var'[1] if `var'==.;
};

save "spatial_dataset.dta", replace;

/*
/* have still have some "made up" geoids corresponding to either 
(a) inland landings or (b) unknown cousubs from the SCOQ fishery.  These have missing my_id, lon, lat. */



