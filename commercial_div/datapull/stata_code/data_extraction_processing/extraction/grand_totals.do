cd "/home/mlee/Documents/projects/spacepanels/scallop/spatial_project_03162016"
use "veslog_species.dta", clear
keep if myspp==800
gen FY=year
gen month=month(date)

replace FY=FY-1 if month<=2
keep if FY>=1996 & FY<=2014
collapse (sum) raw_rev, by(geoid namelsad)
rename raw_reve revenue
egen t=total(revenue)
gen share=revenue/t
drop t
gsort - share
replace revenue=revenue/1000000

saveold "total_revs_by_port.dta", replace version(12)
shell st total_revs_by_port.dta total_revs_by_port.csv -t
