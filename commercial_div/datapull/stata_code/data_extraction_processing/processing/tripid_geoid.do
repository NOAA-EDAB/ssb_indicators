#delimit ;

use "${data_main}/veslog_species_huge_${vintage_string}.dta", clear;
keep tripid dbyear year geoid;

tempfile geoids;
save `geoids', replace;

/*most of the geoids that are'missing' correspond to a "Other <state>" field. We're never going to get this filled in */
use "${data_external}/communities_cleaned3.dta", clear;
drop if geoid==.;
/* I expected each geoid to have a distinct lat-lon, because they should have been the centroid of the geoid polygon.  but that's not exactly the case */
collapse (mean) lat lon, by(geoid namelsad statefp countyfp cousubfp);
label var lat;
label var lon;
compress;
count;
tempfile latlon;
save `latlon';

use `geoids', replace;
merge m:1 geoid using `latlon';
drop if _merge==2;


rename lat port_lat;
rename lon port_lon;
format tripid %18.0g;

tostring tripid, gen(tripid_string) usedisplayformat;
sort dbyear geoid tripid;
save "${data_main}\tripd_geoid_${vintage_string}.dta", replace;

