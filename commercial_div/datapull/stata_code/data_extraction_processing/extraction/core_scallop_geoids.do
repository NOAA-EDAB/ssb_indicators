/* this do file finds the "core" scallop geoids */

#delimit;
clear;
cd "/home/mlee/Documents/projects/spacepanels/scallop/spatial_project_aug29";
use "portyr_gear_ner.dta", replace;

bysort geoid: gen marker=1 if _N==18 & qtykepts>0;
bysort geoid (year): egen marker2=total(marker);
gen core=0;
replace core=1 if marker2==18;
drop marker marker2;

preserve;
collapse (sum) qtykepts revenues, by(core year);
reshape wide qty rev, i(year) j(core);

gen core_qty=qtykepts1/(qtykepts1+qtykepts0);
gen core_rev=revenues1/(revenues0+revenues1);

keep year core_qty core_rev;
list ;

restore;

preserve;
collapse (sum) qtykepts revenues, by(core);
egen tq=total(qtykepts);
egen tr=total(revenues);
gen core_qty=qtykepts/tq;
gen core_rev=revenues/tr;
list core_qty core_rev if core==1;

restore;

keep if core==1;
save "portyr_gear_ner_core.dta", replace;
