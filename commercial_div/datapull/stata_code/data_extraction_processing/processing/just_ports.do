
#delimit ;


/* Get the date from veslog t */
clear ;


	tempfile add;
	local CAREAS1`"`CAREAS1'"`add'" "'  ;
	clear;
	odbc load, exec("select t.VESSEL_PERMIT_NUM as permit, to_char(t.docid) as tripid, t.date_land as datelnd1, 
	EXTRACT(YEAR from t.DATE_LAND) as dbyear from NEFSC_GARFO.document t") $oracle_cxn;   
	duplicates drop;
	drop if DBYEAR>$lastyr;
	quietly save `add';

	clear;
	append using `CAREAS1';
	renvarlab, lower;
	destring, replace;
	compress;
replace datelnd1=dofc(datelnd1);
format datelnd1 %td;

gen yr2=year(datelnd1);
browse if yr2~=dbyear;

bysort permit tripid: gen count=_N;
drop if count==2 & tripid==4864477 & yr2==2015;

drop if count==2 & tripid==4959274 & yr2==2018;
drop count;
bysort permit tripid: assert _N==1;

/* I looked at document, and I'm pretty sure 
4864477 belongs in 2016
less confident that 
4959274 also belongs in 2016 */
bysort permit tripid: assert _N==1;
save "${data_intermediate}/datelnd1_append_${vintage_string}.dta", replace;


#delimit ;

use "${data_main}/veslog_species_huge_${vintage_string}.dta", clear;


rename date datesell;
keep tripid year portlnd1 port state state1 geoid namelsad permit datesell;

duplicates drop;

merge m:1 permit tripid using "${data_intermediate}/datelnd1_append_${vintage_string}.dta";
drop if _merge==2;
drop _merge;
replace datelnd1=datesell if datelnd1==.;
drop dbyear ;
drop datesell;
drop yr2;


rename state state_fips;

/* construct the previous geoid, namelsad, statefips, by permit date tripid */
bysort permit (date tripid): gen previous_namelsad=namelsad[_n-1];
bysort permit (date tripid): gen previous_state_fips=state_fips[_n-1];

/* stata has a probelm with this:
bysort permit (date tripid): gen previous_geoid=geoid[_n-1];
I think it's a precision issue.
*/

tostring geoid, gen(geo_string) usedisplay;
bysort permit (date tripid): gen previous_geoid_str=geo_string[_n-1];
destring previous_geoid_str, gen(previous_geoid);
format previous_geoid %010.0f;
drop previous_geoid_str;

/*most of the geoids that are'missing' correspond to a "Other <state>" field. We're never going to get this filled in */
preserve;
use "${data_external}/communities_cleaned3.dta", clear;
drop if geoid==.;
/* I expected each geoid to have a distinct lat-lon, because they should have been the centroid of the geoid polygon.  but that's not exactly the case */
collapse (mean) lat lon, by(geoid);
label var lat;
label var lon;
compress;
count;
tempfile latlon;
save `latlon';

tempfile previous_latlon;
rename geoid previous_geoid;
rename lat previous_port_lat;
rename lon previous_port_lon;
save `previous_latlon';

restore;
merge m:1 geoid using `latlon';
drop if _merge==2;
drop _merge;
rename port vtr_portnum;
rename portlnd1 vtr_port;
rename state1 vtr_state;
rename lat port_lat;
rename lon port_lon;

merge m:1 previous_geoid using `previous_latlon';
drop if _merge==2;
drop _merge;
drop permit;
sort tripid date year;
save "${data_main}/just_ports_${vintage_string}.dta", replace;

/* you copy this up to dropoff/wind/just_ports */
#delimit;
keep geoid namelsad port_lat port_lon;
duplicates drop;
drop if geoid==.;
sort geoid;
save "${data_main}\port_key_${vintage_string}.dta", replace;


