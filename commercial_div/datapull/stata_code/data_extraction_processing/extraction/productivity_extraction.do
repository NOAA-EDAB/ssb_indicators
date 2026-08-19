/* Productivity project */
#delimit;

clear;
macro drop _all;
set more off;
pause on;
global firstyr 1996;
global lastyr 2016;

pause on;
/*MIN-yang's bit to connect to oracle and set up home directory */  
global my_version "02232017";
cd "/home/mlee/Documents/projects/spacepanels/scallop/spatial_project_$my_version";
quietly do "/home/mlee/Documents/Workspace/technical folder/do file scraps/odbc_connection_macros.do";
global oracle_cxn "conn("$mysole_conn") lower";


/* get permit data*/
clear;
odbc load, exec("select vp_num as permit, ap_year as year, ves_name, len, crew as pcrew, gtons, vhp, blt, hold, ntons, top, toc
from vps_vessel where ap_num in (
select max(ap_num) as ap_num from vps_vessel where ap_year>=1995  group by vp_num, ap_year
);") conn("$mysole_conn") lower;
rename year fishing_year;
save "vps_vessel_$my_version.dta", replace;


/* use veslog_species_huge.dta as a base dataset. Unit of observation shoudl be the TRIP that retains scallops
	Quantity, Revenue




Add in vps_fishery_ner data on vhp and length (No data shoudl drop out)
	add in veslog_g data on gearcode, fishing hours, gearsize, mesh (ringsize) , qty, and depth
 
	Use lat-long

use veslog_g lat/lon to link to the SAMS subregion.  There are two steps 
add in veslog t data on crew numbers, operator number, and days absent.

*/



use veslog_species_huge.dta, clear;
/*800 scallop */
gen species=0;
replace species=800 if myspp==800;
replace species=12 if myspp==12;
replace species=81 if inlist(myspp, 81,147,153,155, 240, 250, 269);
replace species=120 if inlist(myspp, 120, 122, 123, 124, 125, 121, 159);


collapse (sum) qtykept raw_revenue (max) LADAS-Nopermit_scal (first) portlnd1 state1 geoid namelsad, by(permit dbyear tripid species);
drop if tripid==. & species==0;



/*deal with  encoding of the permit categories -- this was done for veslog species, but not veslog_species_huge (partiuclalry well) 
be careful when re-using this segment of code 
1.  check that each row is classifed as at most 1 "thing"
2.  Check that each tripid is classifed as 1 thing.

*/

replace INC=0 if inlist(tripid,3318649, 3318648);
replace GC=1 if inlist(tripid,3318649, 3318648);

gen pcheck=LADAS+GC+NGOM+IFQ+INC+Nopermit;
summ pcheck;

scalar rsd=r(sd);
assert rsd==0;
drop pcheck;
save productivity_vsh_$my_version.dta, replace;



use productivity_vsh_$my_version.dta, replace;

reshape wide qtykept raw_rev, i(permit tripid) j(species);
foreach var of varlist qtykept* raw_revenue*{;
replace `var'=0 if `var'==.;
};

rename qtykept0 kept_pounds_other;
rename raw_revenue0 revenue_other;
rename qtykept800 kept_pounds_scallop;
rename raw_revenue800 revenue_scallop;

rename qtykept12 kept_pounds_monk;
rename raw_revenue12 revenue_monk;

rename qtykept81 kept_pounds_round;
rename raw_revenue81 revenue_round;

rename qtykept120 kept_pounds_flat;
rename raw_revenue120 revenue_flat;
keep if revenue_scallop>0;

save productivity_vsh_$my_version.dta, replace;




use productivity_vsh_$my_version.dta, replace;

keep tripid ;
dups, drop terse;
drop _expand;

/* this is the list of tripids that have scallop landings */
tempfile scal_tripids;
save `scal_tripids', replace;




/* create the 3 tables of tripids */
clear;
forvalues yr=$firstyr/$lastyr{ ;
	tempfile new;
	local NEWfiles `"`NEWfiles'"`new'" "'  ;
	clear;
	odbc load, exec("select t.tripid, t.permit, t.datesail, t.datelnd1, t.opernum, t.crew
		from vtr.veslog`yr't t;") conn("$mysole_conn") lower;
	gen dbyear=`yr';
	quietly save `new';
};

dsconcat `NEWfiles';
destring, replace;
sort tripid;
merge 1:1 tripid using `scal_tripids', keep(3);
rename _merge merge_trips; 
save "trips_scal_$my_version.dta", replace;

/* create the tables of gear characteristics*/
clear;
quietly forvalues yr=$firstyr/$lastyr{ ;
	tempfile gears;
	local gearfiles `"`gearfiles'"`gears'" "'  ;
	clear;
	odbc load, exec("select g.tripid,g.gearid, g.gearcode, g.mesh, g.gearqty, g.gearsize, g.nhaul, g.soakhrs, g.soakmin, g.depth, g.clatdeg, g.clatmin, g.clatsec, g.clondeg, g.clonmin, g.clonsec, g.carea 
		from vtr.veslog`yr'g g;") conn("$mysole_conn") lower;
	gen dbyear=`yr';
	quietly save `gears';
};
dsconcat `gearfiles';






destring, replace;
foreach var of varlist soakhrs soakmin clatdeg-clonsec{;
replace `var'=0 if `var'==.;
};
	sort tripid gearid;


merge m:1 tripid using `scal_tripids', keep(3) nogenerate;

gen latitude=clatdeg+clatmin/60+clatsec/3600;

gen longitude=clondeg+clonmin/60+clonsec/3600;
replace longitude=longitude*-1;

gen fishhours=nhaul*(soakhrs+soakmin/60);
drop soakhrs soakmin clatdeg-clonsec;

save "gears_scal_$my_version.dta", replace;

/* link the tripids that I care about to the gearids that I care about */




#delimit ;
clear;
quietly forvalues yr=$firstyr/$lastyr{ ;
	tempfile catches;
	local catchesfiles `"`catchesfiles'"`catches'" "'  ;
	clear;
	odbc load, exec("select s.tripid, s.gearid, sum(nvl(s.qtykept,0)) as qtykept
		from vtr.veslog`yr's s
		where sppcode in ('SCAL', 'SCALS', 'SCALB', 'SCALG')  and s.qtykept>=1 and s.qtykept is not null
		and s.dealnum not in ('99998', '1', '2', '5', '7', '8','0')
		group by s.tripid, s.gearid;") conn("$mysole_conn") lower;
	gen dbyear=`yr';
	quietly save `catches';
};
dsconcat `catchesfiles';

/* fix scalb, scalg, scals 
	No realy need to fix, since there are
	
	collapse (sum) qtykept, by(tripid gearid sppcode dbyear)
	bysort gearid: gen count=_N
	browse if count>=2
	egen t=tag(tripid gearid)
	*browse if t==0
	count if t==0 & gcount<2

*/
bysort tripid: egen tscal=total(qtykept);
bysort tripid (qtykept): keep if _n==_N;
save "catches_$my_version.dta", replace;

/* just need to put catch on a map.  
  What to do if there are multiple gearids that are in different areas. 
	A. They might be in the same SAMS area, so nothing to do.
	B. If they are in the different SAMS area, I should probably do something.  I'll assign based on largest qtykept reported.
		So I need to keep all the gearids

*/




use gears_scal_$my_version.dta, clear;

merge m:1 tripid gearid using catches_$my_version.dta, nogenerate;
/* There's a few mis-matches -- these two are the most notable  --- but I think that's some data cleaning.*/

/* tripid	gearid
1626181	1583827
3210591	2923467
*/

/* 
B. cast the lat-lons the proper format
C. Spatial join to the SAMS areas on your desktop
D. link to the biomass density.
these tripids have no gearids and are mostly from the 2016 FY. so we can get rid of them.
+proj=aea +lat_1=28 +lat_2=42 +lat_0=40 +lon_0=-96 +x_0=0 +y_0=0 +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs


drop if latitude==0 | latitude==.;

export delimited tripid gearid latitude longitude using "scal_gearids_locs.csv", delimit(",") replace;
*/

save gears_scal_$my_version.dta,replace;

/* you did a spatial join here . You first set the CRSs in R, since you're too dumb to properly figure it out in QGIS. Then you did "spatial join" and "hub distances" in QGIS */
#delimit;
clear;
import delimited using "/home/mlee/Documents/projects/spacepanels/scallop/coords_sam_not_joined.csv";
keep tripid gearid hubname hubdist;
tempfile samnotj;
save `samnotj';

clear;

import delimited using "/home/mlee/Documents/projects/spacepanels/scallop/coords_sam_joined.csv";
tempfile samj;
drop objectid-sams_area;

merge 1:1 tripid gearid using `samnotj';



rename hubname nearest;
gen distance=hubdist;
replace distance=0 if distance==.;
replace subregion=nearest if subregion=="";
 drop nearest hubdist _merge;
 
tempfile merge_sams;
drop x y;
save `merge_sams', replace;




use gears_scal_$my_version.dta;

merge 1:1 tripid gearid using `merge_sams';
drop _merge;
save gears_scal_$my_version.dta, replace;


#delimit;

sort tripid qtykept;



collapse (sum) nhaul fishhours, by(tripid);

tempfile tt;
save `tt';




use gears_scal_$my_version.dta, replace;
replace qtykept=0 if qtykept==.;
gsort tripid - qtykept;


bysort tripid: keep if _n==1;

drop nhaul fishhours;
merge 1:1 tripid using `tt';
drop _merge qtykept tscal depth;

#delimit;
tempfile gearchars tgcars;
save `gearchars', replace;

use "trips_scal_$my_version.dta", replace;

merge 1:1 tripid using `gearchars', nogenerate;
tempfile tgcars; 
save `tgcars', replace;

#delimit;
use productivity_vsh_$my_version.dta, replace;

merge 1:1 tripid using `tgcars', keep(2 3);
drop if _merge==1;
gen monthly=mofd(dofc(datelnd1));
replace monthly=monthly-2;
gen fishing_year=yofd(dofm(monthly));
drop monthly;
drop merge_trips _merge;

gen days_absent=hours(datelnd1-datesail)/24;
replace days_absent=ceil(days_absent);
replace days_absent=1 if days_absent==0;


/* deal with trips that are in subregions that are outside the strata, but near them */
gen str8 subregion_carea="";
replace subregion_carea="GOM" if inlist(carea,514,513, 512, 511,515);
replace subregion_carea="CAN" if carea<=499;

/* 521, 522, 561, 562, 526, 525, 541, 542, 537, 538 */

replace subregion_carea="SCH" if carea==521 & distance>0;

replace subregion_carea="NEP" if inlist(carea,522,561,562) & distance>0;
replace subregion_carea="SEP" if inlist(carea,525) & distance>0;
replace subregion_carea="SCH" if inlist(carea,526) & distance>0;
replace subregion_carea="LI" if inlist(carea,613,616,537, 539)& distance>0;
replace subregion_carea="NYB" if inlist(carea,615, 612, 614, 621, 622, 625, 626 ) & distance>0;


replace subregion_carea="UNK" if inlist(carea, 623, 624, 628, 629, 634, 639, 633, 543, 542, 541, 538, 500, 520,533,534, 534, 551, 552, 600, 610, 611);
replace subregion_carea="UNK" if carea>=640 | carea==620;

replace subregion_carea="Virginia" if inlist(carea, 627, 631, 632, 635, 636, 639, 638,637);

replace subregion_carea=subregion if distance==0;


rename subregion subregion_raw;
rename subregion_carea subregion;

merge m:1 fishing_year subregion using "/home/mlee/Documents/projects/spacepanels/scallop/spatial_project_02232017/sams_biomass_long.dta", keep(1 3);

keep if fishing_year>=1996 & fishing_year<=2015;
drop if _merge==2;
order subregion distance carea, after(ebmsgtow);
drop _merge dbyear;
save productivity_vsh2_$my_version.dta, replace;



#delimit;

merge m:1 permit fishing_year using vps_vessel_$my_version.dta, keep(1 3);
drop _merge;
rename pcrew berths;

foreach var of varlist len berths gtons ntons vhp blt hold top toc {;
bysort permit (fishing_year `var'): replace `var'=`var'[_n-1] if `var'==.;
};



log using descriptive_stats.log, replace;
count;
desc;
mdesc;
/* there are some obs with missing data -- some operator numbers, crew,  mesh, gearqty, gearsize were missing from VTR.  
some data points don't have a region and subregion. This is because the lat/lons were missing.  However, I've binned some of them according to the reported stat area.

There are 42,542 data points with no biomass estimates. Some of these are GOM trips, some are canadian trips, and some (1,415) are probably data errors.
*/

summ;





export delimited using "productivity_$my_version.csv", replace delimit(",");
log close;


 
 
