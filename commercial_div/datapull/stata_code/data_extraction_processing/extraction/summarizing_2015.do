use "/home/mlee/Documents/projects/spacepanels/scallop/spatial_project_08052016/veslog_species_huge.dta", clear


keep if year==2015
egen tagpermit=tag(permit geoid)
collapse (sum) qtykept raw_revenue tagpermit, by(geoid namelsad)
replace qty=qty/1000000
replace raw =raw/1000000
rename tagpermit unique_permits
gsort - raw_rev
export excel using "/home/mlee/Documents/projects/spacepanels/scallop/spatial_project_08052016/snap2015.xlsx", sheet("year2015") firstrow(variables) replace


use "/home/mlee/Documents/projects/spacepanels/scallop/spatial_project_08052016/veslog_species_huge.dta", clear


keep if year==2015
gen mymonth=month(date)
keep if mymonth<=3
egen tagpermit=tag(permit geoid)
collapse (sum) qtykept raw_revenue tagpermit, by(geoid namelsad)
replace qty=qty/1000000
replace raw =raw/1000000
rename tagpermit unique_permits
gsort - raw_rev

export excel using "/home/mlee/Documents/projects/spacepanels/scallop/spatial_project_08052016/snap2015.xlsx", sheet("JFM_2015") firstrow(variables) 
