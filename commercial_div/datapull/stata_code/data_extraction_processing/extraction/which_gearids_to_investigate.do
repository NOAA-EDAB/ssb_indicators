/* after doing some digging, there are just a few port-years that are probably causing my mis-matches */
use "/home/mlee/Documents/projects/spacepanels/scallop/overlaps/overlap_indices_problems.dta", replace
bysort first: gen count1=_N
bysort second: gen count2=_N
tab count1
gsort - count1
tab count2
sort first FY
browse FY first second if count1>=8 & count2>=9
browse if count1>=37
egen m=tag(first FY)
browse if count1>=37 & m>=1
sort first FY
egen n=tag(second FY)
browse if count2>=24 & n>=1
sort second FY
browse second FY if count2>=24 & n>=1
browse second FY count2 if count2>=24 & n>=1


/* I'll mark the worst port offenders in the database */

use scallop_gearids.dta,clear

gen mark=0

replace mark=1 if geoid==2300947630 & inlist(FY_scal,1998, 1999, 2005, 2012)
replace mark=1 if geoid==2301363590 & inlist(FY_scal,1998, 1999)
replace mark=1 if geoid==2502354310 & inlist(FY_scal,1998, 1999, 2005, 2012, 2010)
replace mark=1 if geoid==3610322194 & inlist(FY_scal,1998, 1999, 2005, 2009, 2010)
replace mark=1 if geoid==3713793412 & inlist(FY_scal,1998, 2005, 2006,2009, 2010)

replace mark=1 if geoid==4400951580 & inlist(FY_scal,2005, 2006,2009, 2010,2012)
keep if mark==1

drop if gearid>=4.10326121e+13 /* drop out the evtrs*/

save scallop_gearids_to_research.dta, replace
use scallop_gearids_to_research.dta, replace

tempfile t1
keep permit tripid gearid mark
rename mark missing_investigate
dups, drop terse
save `t1', replace

use scallop_gearids_hack.dta, clear

drop _merge 
merge m:1 permit tripid gearid using `t1'

keep if _merge==3
keep if vmiss==1
save "gearids_to_research.dta", replace
