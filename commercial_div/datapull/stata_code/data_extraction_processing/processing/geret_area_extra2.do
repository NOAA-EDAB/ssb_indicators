/***********************   
This is a bit of code that classifies each
"tripid-species" into 3 areas:
Mid-atlantic (MA), New England (NE) and Null (00) based on the carea reported in the corresponding "gearids"
    "MA" : carea >= 600 & carea < 700
    "NE" : carea >= 464 & carea <600
is can be joined to the "veslog_species_huge.dta" or "veslog_species.dta" datsets using

merge 1:m tripid myspp using "veslog_species_huge.dta"

you should expect some _merge=1 and no _merge=2.  This is because a larger set of data was extracted for the 

***************************/
#delimit;
clear;
pause off;



/* make a table of nespp3 and 4 */
#delimit;
tempfile nespp34;
odbc load, exec("select distinct nespp3, nespp4, sppcode from VTR.vlsppsyn;") $oracle_cxn;   
destring, replace ;
renvarlab, lower ;
duplicates drop (sppcode), force  ;
save `nespp34', replace ;
clear; 

use ${data_intermediate}\extra_${vintage_string}.dta, replace;











replace sppcode = "BAR" if sppcode == "HAGB" & tripid == 2787176;
replace sppcode = "SKATE" if sppcode == "SKLARGE" & inlist(permit, 150611,125520, 146679, 146669,125520);

replace sppcode="SCUP" if sppcode=="P" & permit==800129;
replace sppcode="FLSD" if sppcode=="FLSP";

replace sppcode="CRJ" if permit==250704 & sppcode=="SCC";
replace sppcode="SCAL" if sppcode=="SCC";

replace sppcode="ANVY" if sppcode=="ANCHOVIES";
replace sppcode="FLDAB" if sppcode=="FLDBS";
replace sppcode="EEL" if sppcode=="EELS";
replace sppcode="RED" if sppcode=="PERCH" & inlist(permit,800328);
replace sppcode="HGF" if sppcode=="HOG";
replace sppcode="BSB" if sppcode=="BSBL" | sppcode=="BSBM" | sppcode=="BSBS";
replace sppcode="WHK" if sppcode=="KING";
replace sppcode="LOG" if sppcode=="LB";
replace sppcode="SKATE" if sppcode=="STING RAYS";

replace sppcode="HAKNS" if sppcode=="HAKE";
replace sppcode="SHRP" if sppcode=="SCRIMP" | sppcode=="SCRIMPB" | sppcode=="BLK SCRIMP" | sppcode=="BLKSCRIMP" | sppcode=="BLU SCRIMP" | sppcode=="SHRNSB";
replace sppcode="SMLT" if sppcode=="SMELT";
replace sppcode="TAU" if sppcode=="BLACK" | sppcode=="BLACKS";
replace sppcode="SQNS" if sppcode=="SQ" | sppcode=="SQNSB" | (sppcode=="LOG" & permit==800129) | (sppcode=="CQNS") & permit==800129;
replace sppcode="WKSP" if sppcode=="WK" | sppcode=="WKSP"|sppcode=="WSKP" | sppcode=="SKSP";
replace sppcode="WKSQ" if sppcode=="WSKQ";
replace sppcode="EELC" if sppcode=="C-EELS";
replace sppcode="CRBB" if sppcode=="CRRB";
replace sppcode="CLNSB" if sppcode=="CLNSBSK";
replace sppcode="OFF" if sppcode=="?" | sppcode=="SPEANING"|(sppcode=="WGSM" & permit==800129);
replace sppcode="CRRD" if sppcode=="CRR";
replace sppcode="DGNS" if sppcode=="DGN"|sppcode=="DNGS";

replace sppcode="POLL" if sppcode=="[P;;";

replace sppcode="WHKNS" if permit==800129 & (sppcode=="UNK" | sppcode=="WHNSB");
replace sppcode="WHKNS" if permit==800334 & (sppcode=="UNK" | sppcode=="WHNSB");

replace sppcode="WHKNS" if sppcode=="CONCH" | sppcode=="CONKS" |sppcode=="CONCHB"| sppcode=="CONHS"| sppcode=="CON";
replace sppcode="MEN" if (sppcode=="MTN"| sppcode=="MRN") & permit==800318;
replace sppcode="SCUP" if sppcode=="SCIP";

replace sppcode="OFF" if sppcode=="JACK";
replace sppcode="STB" if permit==800307 & (sppcode=="ROCK" | sppcode=="ROWE?");
replace sppcode="STB" if permit==800328 & (sppcode=="SB") ;
replace qtykept=qtykept*50/8.33 if sppcode=="SCBB" & permit==109652 & tripid==479812;

replace sppcode="BAIT" if sppcode=="OFFB";
replace sppcode="BLU" if sppcode=="OFF" & permit==800307 & qtykept==7;
replace sppcode="SCAL" if sppcode=="SCBB" & permit==109652 & tripid==479812;
replace qtykept=qtykept*68.3 if sppcode=="WHKNS" & qtykept<=20 ;
replace qtykept=qtykept*200 if sppcode=="HAGB" & qtykept<=200 ;
replace sppcode="HAG" if sppcode=="HAGB";


drop if permit==410349 & tripid==3210591 & qtykept==11000 & sppcode=="SCAL";


drop if inlist(sppcode,"CLSU","CLSUB","CLQUB","CLQU") & state1~="ME";
replace qtykept=qtykept*17 if sppcode=="CLSUB" & qtykept<=10000 ;
replace qtykept=qtykept/5.24 if sppcode=="CLSU";
replace qtykept=qtykept*10 if sppcode=="CLQUB";
replace qtykept=qtykept*11 if sppcode=="CLQUB" & state1=="ME";
replace qtykept=qtykept/7.51 if sppcode=="CLQU";



replace sppcode="WHKC" if sppcode=="WHKNS";






/* do geret's EPU classification here */
gen str3 EPU="00";
replace EPU="gom" if inlist(carea, 500, 510, 512, 513, 514, 515);
replace EPU="gb" if inlist(carea,521, 522, 523, 524, 525, 526, 551,552,561,562);
replace EPU="mab" if inlist(carea,537,539,600,612, 613, 614, 615, 616,621,622,625,626,631,632);
replace EPU="ss" if inlist(carea,463, 464, 465, 466, 467,511);
 
bysort tripid (EPU): gen diff=EPU[1]!=EPU[_N];
tab diff;

bysort tripid sppcode (EPU): gen sdiff=EPU[1]!=EPU[_N];
tab sdiff;
pause;


preserve;
keep if diff==0;
keep tripid EPU;
duplicates drop ;
gen fracgom=1 if EPU=="gom";
gen fracgb=1 if EPU=="gb";
gen fracmab=1 if EPU=="mab";
gen fracss=1 if EPU=="ss";
gen frac00A=1 if EPU=="00";

foreach var of varlist frac*{;
replace `var'=0 if `var'==.;
};

save "${data_main}\just_one_EPU_$vintage_string.dta", replace;
*export delimited "just_one_EPU_$vintage_string.csv", delimit(",") replace;
restore;

keep if diff==1;



/* there are 13,596 observations that reported catching a particular species in 2 (or more) areas */

/* generate a fraction variable correspongind to NE */

merge m:1 sppcode using `nespp34', keep(1 3);
assert _merge==3;
drop _merge nespp4;
rename nespp3 myspp;
replace myspp=509 if myspp==508 | myspp==507;





/*Changing VTR nespp3 numbers to be consisent with CFDBS numbers*/
replace myspp = 365 if inlist(myspp,373);
compress;
/*Cancer crab seems to be Atlantic Rock crab, so replacing cancer crab price, which doesn't exist in CFDBS, for Atlantic Rock crab*/
replace myspp = 712 if myspp == 714;

/*A small number of people seem to be reporting calico scallop instead of sea scallop*/
replace sppcode = "SCAL" if sppcode == "SCC" & dbyear>=2005;
replace myspp = 800 if myspp == 797 & dbyear>=2005;



#delimit;
collapse (sum) qtykept, by(tripid myspp EPU);
bysort  tripid myspp: egen tq=total(qtykept);

gen frac=qtykept/tq;
drop tq qtykept;
reshape wide frac, i( tripid myspp) j(EPU) string;


foreach var of varlist frac*{;
replace `var'=0 if `var'==.;
};

save "${data_main}\EPUs_tripids_species_$vintage_string.dta", replace;
export delimited "${data_main}\EPUs_tripids_species_$vintage_string.csv", delimit(",") replace;

