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


clear ;
	tempfile add;
	local CAREAS1`"`CAREAS1'"`add'" "'  ;
	clear;
	odbc load, exec("select t.VESSEL_PERMIT_NUM as permit, to_char(g.docid) as tripid, to_char(g.imgid) as gearid, t.state1,
	s.kept, s.SPECIES_ID as sppcode, g.carea, EXTRACT(YEAR from t.DATE_LAND) as dbyear 
	from NEFSC_GARFO.document t, NEFSC_GARFO.catch s, NEFSC_GARFO.images g 
		where g.imgid=s.imgid and t.docid=g.docid
		and s.dealer_num not in ('99998', '1', '2', '5', '7', '8') and s.kept>=1 and s.kept is not null;") $oracle_cxn;   
	drop if DBYEAR>$lastyr;
	quietly save `add';

	clear;
	append using `CAREAS1';
	renvarlab, lower;
	destring, replace;
	compress;

drop if inlist(sppcode, "WHAK","HAKNS","RHAK","WHAK","SHAK","HAKOS","WHB");
save ${data_intermediate}\extra_${vintage_string}.dta, replace;


/***********drop hake and add recalssified velsog query**************/
clear ;

	tempfile new6;
	local hake `"`hake'"`new6'" "'  ;
	clear;
	odbc load, exec("select  g.imgid as gearid, s.kept as qtykept, s.SPECIES_ID as sppcode, s.dealer_num as dealnum, t.state1, 	
	t.port1 as portlnd1, t.VESSEL_PERMIT_NUM as permit, t.PORT1_NUMBER as port, t.docid as tripid, 
	trunc(nvl(s.date_sold, t.DATE_LAND)) as datesell, g.mesh, g.gearqty, g.gearcode, g.carea, 
	EXTRACT(YEAR from t.DATE_LAND) as dbyear 
	from NEFSC_GARFO.catch s, NEFSC_GARFO.images g, NEFSC_GARFO.document t
	where t.docid=g.docid  and (t.tripcatg=1 or t.tripcatg=4) and g.imgid=s.imgid
	and s.dealer_num not in ('99998', '1', '2', '5', '7', '8')  and s.kept>=1 and s.kept is not null
	and s.SPECIES_ID in ('WHAK','HAKNS','RHAK','WHAK','SHAK','HAKOS','WHB');")  $oracle_cxn;   
	quietly count;
	scalar pp=r(N);
	drop if DBYEAR>$lastyr;
	quietly save `new6', emptyok;

	
	clear;
	append using `hake';
	renvarlab, lower;
	drop if qtykept==.;
	destring, replace;
	compress;

replace sppcode="SHAK" if sppcode=="WHAK" & mesh<=3.5 ;
replace sppcode="SHAK" if sppcode=="HAKOS" | sppcode=="WHB"  ;
drop mesh gearqty gearcode;
collapse (sum) qtykept, by(gearid tripid sppcode carea state1 dbyear);



append using "${data_intermediate}\extra_${vintage_string}.dta";
save ${data_intermediate}\extra_${vintage_string}.dta, replace;


/***********Deal with WOLFFISHES ('CAT') and ACADIAN REDFISH ('RED').  There is mis-reporting of some catfish as "WOLFFISH".  We will use the rule that only 'CAT' that is caught in a carea<=599 is actually WOLF.
EVERYTHING ELSE IS ASSUMED TO BE MISREPORTED. We need to handle YEARS where no 'CAT' are landed, since STATA really complains about stacking empty datasets.  I handled this with an if there are no obs, 
set the number of obs=1.  Then later we drop any observations that have missing sppcodes.

There is a little bit of this problem with White Perch being encoded as Ocean Perch (Redfish).  The same carea rule will be used.

  **************/
clear ;

	tempfile newWOLF;
	local WOLF `"`WOLF'"`newWOLF'" "'  ;
	clear;
	odbc load, exec("select  g.imgid as gearid, sum(s.kept) as qtykept, s.SPECIES_ID as sppcode, s.dealer_num as dealnum,
	t.state1, t.port1 as portlnd1, t.VESSEL_PERMIT_NUM as permit, t.PORT1_NUMBER as port, t.docid as tripid, 
	trunc(nvl(s.date_sold, t.date_land)) as datesell, g.carea, EXTRACT(YEAR from t.DATE_LAND) as dbyear 
	from NEFSC_GARFO.catch s, NEFSC_GARFO.document t, NEFSC_GARFO.images g 
		where t.docid= g.docid and g.imgid=s.imgid and (t.tripcatg=1 or t.tripcatg=4) and g.carea between 400 and 599
			and s.dealer_num not in ('99998', '1', '2', '5', '7', '8')  and s.kept>=1 and s.kept is not null
			and s.SPECIES_ID in ('CAT', 'RED')    
			group by s.SPECIES_ID,  g.imgid, t.state1, t.port1, s.dealer_num, t.VESSEL_PERMIT_NUM, 
			t.PORT1_NUMBER, t.docid, trunc(nvl(s.date_sold, t.date_land)), g.carea, EXTRACT(YEAR from t.DATE_LAND) ;")  $oracle_cxn;   
	quietly count;
	scalar pp=r(N);
	drop if DBYEAR>$lastyr;
	quietly save `newWOLF', emptyok;

	clear;
	append using `WOLF';
	renvarlab, lower;
	destring, replace;
	compress;
	drop if strmatch(sppcode,"")==1;
	
collapse (sum) qtykept, by(gearid tripid sppcode carea state1 dbyear );


append using "${data_intermediate}\extra_${vintage_string}.dta";
save ${data_intermediate}\extra_${vintage_string}.dta, replace;

/* append these together...... */

#delimit;
clear;

tempfile nespp34;
odbc load, exec("select distinct nespp3, nespp4, sppcode from VTR.vlsppsyn;") $oracle_cxn;   
destring, replace ;
renvarlab, lower ;
duplicates drop (sppcode), force  ;
save `nespp34', replace ;
clear; 

use ${data_intermediate}\extra_${vintage_string}.dta, replace;
gen str2 areafshd="00";
    replace areafshd = "MA" if carea >= 600 & carea < 700;
    replace areafshd = "NE" if carea >= 464 & carea <600;
/*this has extra trips in in.  When you eventually join back to the veslog_species.dta, you'll want to get rid of anything that is in this dataset and not in the other*/

/* are there any "tripids" that span areafshd? 
tag each tripid areafshed
tag each tripid
egen tag_trip_area=tag(tripid areafshd);
egen tag_trip=tag(tripid);

*/

#delimit;
replace sppcode = "BAR" if sppcode == "HAGB" & tripid == 2787176;
replace sppcode = "SKATE" if sppcode == "SKLARGE" & inlist(permit, 150611, 125520, 146679, 146669,125520);

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










bysort tripid (areafshd): gen diff=areafshd[1]!=areafshd[_N];
tab diff;

bysort tripid sppcode (areafshd): gen sdiff=areafshd[1]!=areafshd[_N];
tab sdiff;
pause;

#delimit ;




preserve;
keep if diff==0;
keep tripid areafshd;
duplicates drop;
gen fracMAA=1 if area=="MA";
gen fracNEA=1 if area=="NE";
gen frac00A=1 if area=="00";

foreach var of varlist frac*{;
replace `var'=0 if `var'==.;
};

save "${data_main}\just_one_area_$vintage_string.dta", replace;
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
collapse (sum) qtykept, by(tripid myspp areafshd);
bysort  tripid myspp: egen tq=total(qtykept);

gen frac=qtykept/tq;
drop tq qtykept;
reshape wide frac, i( tripid myspp) j(areafshd) string;


foreach var of varlist frac*{;
replace `var'=0 if `var'==.;
};

save "${data_main}\areas_tripids_species_$vintage_string.dta", replace;

