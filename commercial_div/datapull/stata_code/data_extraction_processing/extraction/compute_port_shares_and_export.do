cd "/home/mlee/Documents/projects/spacepanels/scallop/spatial_project_03162016"
use veslog_species, clear
keep if myspp==800
drop if geoid==.
collapse (sum) raw_rev, by(geoid)
egen tr=total(raw)
gen share=raw_rev/tr*100
drop tr
format geoid %010.0f


tostring geoid, gen(geoid_string) usedisplayformat 
order geoid geoid_string 


saveold "port_shares.dta", version(12) replace
shell st "port_shares.dta" "port_shares.dbf" -y
shell st "port_shares.dta" "port_shares.csv" -y
