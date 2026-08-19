cd "/run/user/1877/gvfs/smb-share:server=net,share=home2/mlee/dropoff/john"
use "/run/user/1877/gvfs/smb-share:server=net,share=home2/mlee/spatial data/scallop project/scallop biomass data/SAMS_available_biomass_v2.dta", replace

/* type 2: rotational --> type 1
   type 0 closed --> type -1
   type 1:  --> type 0
   */
 
 gen spatial_flag=0 if type==1
 replace spatial_flag=1 if type==2
 replace spatial_flag=-1 if type==0
 
 
 keep subregion year spatial_flag
 
 replace subregion="CL-2(S)" if strmatch(subregion, "CA2_Acc")
 replace subregion="CL1ACC" if strmatch(subregion, "CA1_Acc")
 replace subregion="HCS" if strmatch(subregion, "HC")
 
 replace subregion="NLSACC" if strmatch(subregion, "NLS")
 replace subregion="SCH" if strmatch(subregion, "SC")
 replace subregion="Virginia" if strmatch(subregion, "Virg")

rename year fishing_year
 tempfile key1
 save `key1'
 clear
 
 import delimited /home/mlee/mounts/mlee/dropoff/john/productivity_02232017.csv
 gen order=_n
 merge m:1 subregion fishing_year using `key1', keep(1 3)
 drop _merge
 replace spatial_flag=0 if subregion=="GOM"
 
 
save productivity_02232017B.dta, replace
gen dropper=0
replace dropper=1 if inlist(subregion,"UNK", "CAN")
replace dropper=1 if spatial_flag==-1
replace dropper=1 if inc==1 | ifq==1 | gc==1 | ngom==1| nopermit_scal==1

sort order
drop order

preserve
keep if dropper==1
drop dropper
saveold productivity_02232017_dropped.dta, replace version(12)
restore

keep if dropper==0
drop dropper
saveold productivity_02232017B.dta, replace version(12)

!st productivity_02232017B.dta productivity_02232017B.csv -y
!st productivity_02232017_dropped.dta productivity_02232017_dropped.csv -y

