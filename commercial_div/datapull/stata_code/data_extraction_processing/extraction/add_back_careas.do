#delimit ;
cd "/home/mlee/Documents/projects/spacepanels/scallop/spatial_project_aug22";

use "veslog_species_huge.dta", clear;

merge m:1 tripid using "just_one_area.dta", keep(1 3);
rename _merge _merge1;


merge m:1 tripid myspp using "areas_tripids_species.dta", keep(1 3);
tab _merge _merge1;


replace frac00=frac00A if frac00==.;
replace fracMA=fracMAA if fracMA==.;
replace fracNE=fracNEA if fracNE==.;

drop frac00A fracMAA fracNEA;

