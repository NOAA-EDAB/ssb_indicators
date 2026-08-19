#delimit ;
cd "/home/mlee/Documents/projects/spacepanels/scallop/spatial_project_03162016";
local date: display %td_CCYY_NN_DD date(c(current_date), "DMY");
global today_date_string = subinstr(trim("`date'"), " " , "_", .);

use "veslog_species.dta" ;

keep if myspp==800;
keep tripid portlnd1 state1 port dbyear geoid namelsad;
dups tripid portlnd1 state1 port dbyear geoid namelsad, drop terse;
compress;
drop _exp;
dups tripid;

saveold "tripids_ports_$today_date_string.dta", version(12) replace;
shell /home/mlee/Documents/StatTransfer12/st tripids_ports_$today_date_string.dta tripids_ports_$today_date_string.sas7bdat -y ;
