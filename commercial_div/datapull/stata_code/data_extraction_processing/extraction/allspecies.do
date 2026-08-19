/***********************   
You need to do a "search" on Lou to find places that the code needs to be fixed.


***************************/
#delimit;
clear;
local prefix "${data_intermediate}/$allprefix";
local monk_prefix "${data_intermediate}/$monk_prefix";


/*************TO EXECUTE YOU WILL NEED TO RUN THE allspecies_prices.do, and can adjust pricing query from there*******************/

/**********************************************************************************************************************************/


/*************ALL OTHER SPECIES DATASET*********************/
		/*****extract from vtr the species we care about, besides scallops, hake, which we will append using our previous queries. For hake we 
		run the code we used before to classify the species accordingly***********/

/* make a table of nespp3 and 4 */
tempfile nespp34;
odbc load, exec("select distinct nespp3, nespp4, sppcode from VTR.vlsppsyn;") $oracle_cxn;   
destring, replace ;
renvarlab, lower ;
duplicates drop (sppcode), force  ;
save `nespp34', replace ;
clear; 



tempfile ports;
clear;



	tempfile new;
	local NEWfiles `"`NEWfiles'"`new'" "'  ;
	clear;
	odbc load, exec("select sum(s.kept) as qtykept, s.SPECIES_ID as sppcode, s.dealer_num as dealnum, t.state1, t.port1 as portlnd1, 
	t.VESSEL_PERMIT_NUM as permit, t.PORT1_NUMBER as port, t.docid as tripid, trunc(nvl(s.date_sold, t.date_land)) as datesell, 
	EXTRACT(YEAR from t.DATE_LAND) as dbyear
	from NEFSC_GARFO.catch s, NEFSC_GARFO.document t, NEFSC_GARFO.images g 
	where t.docid= g.docid and g.imgid=s.imgid and (t.tripcatg=1 or t.tripcatg=4)
			and s.dealer_num not in ('99998', '1', '2', '5', '7', '8')  and s.kept>=1 and s.kept is not null
			and s.SPECIES_ID not in ('WHAK','HAKNS','RHAK','WHAK','SHAK','HAKOS','WHB','CAT','RED')
			group by s.SPECIES_ID, t.state1, t.port1, s.dealer_num, t.VESSEL_PERMIT_NUM, t.PORT1_NUMBER, t.docid, trunc(nvl(s.date_sold, t.date_land)), EXTRACT(YEAR from t.DATE_LAND) ;")  $oracle_cxn;                    
	drop if DBYEAR>$lastyr;
	quietly save `new', emptyok;

	clear;
	append using `NEWfiles';
	renvarlab, lower;
	destring, replace;
	compress;
cap drop emptyds;
replace portlnd1="HAMPTON" if portlnd1=="HAMPTON/SEABROOK" & state1=="NH";

save "${data_main}\veslog_species_huge_${vintage_string}.dta", replace;

/***********drop hake and add recalssified velsog query**************/

clear ;

	tempfile new6;
	local hake `"`hake'"`new6'" "'  ;
	clear;
	odbc load, exec("select s.kept as qtykept, s.SPECIES_ID as sppcode, s.dealer_num as dealnum, t.state1, t.port1 as portlnd1, 
	t.VESSEL_PERMIT_NUM as permit, t.PORT1_NUMBER as port, t.docid as tripid, trunc(nvl(s.date_sold, t.date_land)) as datesell, 
		 g.mesh, g.gearqty, g.gearcode, EXTRACT(YEAR from t.DATE_LAND) as dbyear 
		 from NEFSC_GARFO.catch s, NEFSC_GARFO.images g, NEFSC_GARFO.document t
	where g.imgid=s.imgid  and g.docid=t.docid and (t.tripcatg=1 or t.tripcatg=4)
	and s.dealer_num not in ('99998', '1', '2', '5', '7', '8')  and s.kept>=1 and s.kept is not null
	and s.SPECIES_ID in ('WHAK','HAKNS','RHAK','WHAK','SHAK','HAKOS','WHB') ;")  $oracle_cxn;   
	drop if DBYEAR > $lastyr ;
	quietly save `new6', emptyok;


	clear;
	append using `hake';
	renvarlab, lower;
	cap drop emptyds;
	drop if qtykept==.;
	renvarlab, lower;
	destring, replace;
	compress;

replace sppcode="SHAK" if sppcode=="WHAK" & mesh<=3.5 ;
replace sppcode="SHAK" if sppcode=="HAKOS" | sppcode=="WHB"  ;
drop mesh gearqty gearcode;
replace portlnd1="HAMPTON" if portlnd1=="HAMPTON/SEABROOK" & state1=="NH";

collapse (sum) qtykept, by(dealnum sppcode state1 portlnd1 dbyear permit port tripid datesell);
append using "${data_main}\veslog_species_huge_${vintage_string}.dta";
save "${data_main}\veslog_species_huge_${vintage_string}.dta", replace;



/***********Deal with WOLFFISHES ('CAT') and ACADIAN REDFISH ('RED').  There is mis-reporting of some catfish as "WOLFFISH".  We will use the rule that only 'CAT' that is caught in a carea<=599 is actually WOLF.
EVERYTHING ELSE IS ASSUMED TO BE MISREPORTED. We need to handle YEARS where no 'CAT' are landed, since STATA really complains about stacking empty datasets.  I handled this with an if there are no obs, 
set the number of obs=1.  Then later we drop any observations that have missing sppcodes.

There is a little bit of this problem with White Perch being encoded as Ocean Perch (Redfish).  The same carea rule will be used.

  **************/
  #delimit ;
clear ;
	tempfile newWOLF;
	local WOLF `"`WOLF'"`newWOLF'" "'  ;
	clear;
	odbc load, exec("select sum(s.kept) as qtykept, s.SPECIES_ID as sppcode, s.dealer_num as dealnum, t.state1, t.port1 as portlnd1, 
	t.VESSEL_PERMIT_NUM as permit, t.PORT1_NUMBER as port, t.docid as tripid, trunc(nvl(s.date_sold, t.DATE_LAND)) as datesell, 
	EXTRACT(YEAR from t.DATE_LAND) as dbyear 
	from NEFSC_GARFO.catch s, NEFSC_GARFO.document t, NEFSC_GARFO.images g 
		where g.imgid= s.imgid and t.docid=g.docid and (t.tripcatg=1 or t.tripcatg=4) and g.carea between 400 and 599
			and s.dealer_num not in ('99998', '1', '2', '5', '7', '8')  and s.kept>=1 and s.kept is not null
			and s.SPECIES_ID in ('CAT', 'RED')    
			group by s.SPECIES_ID,  t.state1, t.port1, s.dealer_num, t.VESSEL_PERMIT_NUM, t.PORT1_NUMBER, t.docid, 
			trunc(nvl(s.date_sold, t.DATE_LAND)), EXTRACT(YEAR from t.DATE_LAND);")  $oracle_cxn;   
	drop if DBYEAR>$lastyr;
	
	quietly save `newWOLF', emptyok;

	clear;
	append using `WOLF';
	cap drop emptyds;
	renvarlab, lower;
	destring, replace;
	compress;
	drop if strmatch(sppcode,"")==1;
	
collapse (sum) qtykept, by(dealnum sppcode state1 portlnd1 dbyear permit port tripid datesell);
append using "${data_main}\veslog_species_huge_${vintage_string}.dta";
save "${data_main}\veslog_species_huge_DIRTY_${vintage_string}.dta", replace;

/*This is probably as good a place as any to "fix" the barnegat issue */

replace portlnd1="BARNEGAT LIGHT" if port==331527;
replace portlnd1="LONG BEACH TOWNSHIP" if port==331627;

replace portlnd1="HAMPTON" if portlnd1=="HAMPTON/SEABROOK" & state1=="NH";


/*Geret's edits in next two lines*/
replace sppcode = "BAR" if sppcode == "HAGB" & tripid == 2787176;
replace sppcode = "SKATE" if sppcode == "SKLARGE" & inlist(permit, 150611, 125520, 146679, 146669,125520);

/* Min-Yang's -- more data cleaning of "sppcodes" that do to match or are just wrong */
replace qtykept=qtykept*50/8.33 if sppcode=="SCBB" & permit==109652 & tripid==479812;
replace sppcode="SCAL" if sppcode=="SCBB" & permit==109652 & tripid==479812;
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

replace sppcode="BLU" if sppcode=="OFF" & permit==800307 & qtykept==7;

replace qtykept=qtykept*68.3 if sppcode=="WHKNS" & qtykept<=20 ;
replace qtykept=qtykept*200 if sppcode=="HAGB" & qtykept<=200 ;
replace sppcode="HAG" if sppcode=="HAGB";

replace sppcode="BAIT" if sppcode=="OFFB";
replace sppcode="CRO" if sppcode=="COD" & permit==223461 & tripid==1301644 & qtykept==1527;



replace sppcode="SKATE" if sppcode=="SKLARGE" & permit==150611 & tripid==15061116062308;

replace sppcode="CRJ" if sppcode=="CRH" & permit==149622 & tripid==4937981; 
replace sppcode="CRJ" if sppcode=="CRH" & permit==232092 & tripid==4939176;


replace sppcode="WHKC" if sppcode=="WHKNS";















drop if permit==410349 & tripid==3210591 & qtykept==11000 & sppcode=="SCAL";

/* Convert surfclam bushels to meat weights  17lbs of meats per bushel
  Convert surfclam (lbs) to mean weights (5.24 lb whole= 1 lb meat)

  Convert ocean quahog to meat weights (10 lbs of meats per bushel)
  convert oq to meat weights 11 lbs of meats/bushel if maine)

  convert oq to meat weights if reported in lbs (7.51 lb whole=1lb meat)
 */


replace qtykept=qtykept*17 if sppcode=="CLSUB" & qtykept<=10000 ;
replace qtykept=qtykept/5.24 if sppcode=="CLSU";

replace qtykept=qtykept*10 if sppcode=="CLQUB";
replace qtykept=qtykept*11 if sppcode=="CLQUB" & state1=="ME";

replace qtykept=qtykept/7.51 if sppcode=="CLQU";

drop if inlist(sppcode,"CLSU","CLSUB","CLQUB","CLQU") & state1~="ME";
save "${data_main}\veslog_species_huge_${vintage_string}.dta", replace;

/*************
THIS CODE SHOULD GET MOVED 
**************/













/* Extract the "plan" and "cat" corresponding to those tripids (based on datelnd1 and permit) 
  a.  1994-2013 
  b. Just the "scallop" plans
Stick it all into a large dataset */
#delimit;
clear; 


    tempfile new12;
    local scalVESfiles `"`scalVESfiles'"`new12'" "'  ;
    clear;
    odbc load, exec("select t.VESSEL_PERMIT_NUM as permit, t.docid as tripid, p.plan, p.cat, EXTRACT(YEAR from t.DATE_LAND) as dbyear
		from NEFSC_GARFO.document t, NEFSC_GARFO.permit_vps_fishery_ner p
        where t.VESSEL_PERMIT_NUM=p.vp_num and trunc(t.date_land) between trunc(p.start_date) and trunc(p.end_date) 
		and p.plan in ('SC','SCG','SG','LGC');") $oracle_cxn;  
    drop if DBYEAR>$lastyr;

    quietly save `new12', emptyok;

dsconcat `scalVESfiles';



    renvarlab, lower;
    destring, replace;
    compress;
    
    
    /* duplicates drop is needed here.  Because of the way VPS_FISHERY_NER is constructed, if a vessel "lands" fish on the date that the permit changes is effect, it will match to TWO
    records.  For an example of this, see tripid=981463, vp_num=114454, and ap_year=1999. */
	duplicates drop;
 label var dbyear "YEAR ACCORDING TO DB YEAR";
  save "${data_intermediate}\scal_tripid_permits.dta", replace;  

/*The plan and cat columns are concatenated into a single variable (plan_cat, where plan_cat can take on values LGCA, LGCB, SC2, etc).  
At this point, the data is "long". There may be tripids with more than 1 row (if  vessel held more than 1 plan_cat at the time).  
I need it in wide format, so I reshape.  */

    gen mark=1;
	gen plan_cat= plan+cat;
    drop plan;
	drop cat;
	drop if plan_cat==" "; 
	reshape wide mark, i(permit tripid dbyear) j(plan_cat) string; ; /* at this stage, there is 1 obs per permit-tripid-dbyear and variables markLGCA markLGCB markSC2, etc)*/
    compress;
	/*Requires the renvars package*/
    renvars mark*, predrop(4); ; /*this trims off the "mark" suffix, leaving behind LGCA LGCB SC2, etc. */

/*************************************************************/
/*************************************************************/

merge 1:m tripid permit dbyear using "${data_main}\veslog_species_huge_${vintage_string}.dta", keep(2 3);
save "${data_main}\veslog_species_huge_${vintage_string}.dta", replace;
foreach p of varlist LGCA-SG1B{ ;
	replace `p'=0 if `p'==.;
};
rename _merge permitmerge;
egen pp= rowtotal(LGCA-SG1B);
tab pp;
gsort -pp;

drop if qtykept==.;


gen state = substr(string(port, "%06.0f"), 1, 2)   ;
destring state, replace  ;
save "${data_main}\veslog_species_huge_${vintage_string}.dta", replace;

/*********************************************/
/******************FY dates*******************/
/*********************************************/

gen date2=dofc(datesell) ;
format date2 %td;
replace date2=date("01jan1996","DMY") if tripid==221133 & permit==330499 & dbyear==1996;
replace date2=date("24sep1999","DMY") if tripid==961512 & permit==800129 & dbyear==1999;
replace date2=date("03jan1996","DMY") if tripid==158034 & permit==410406 & dbyear==1996;
replace date2=date("07jan1996","DMY") if tripid==159356 & permit==410389 & dbyear==1996;
replace date2=date("02jan1996","DMY") if tripid==166980 & permit==320411 & dbyear==1996;



drop datesell;
rename date2 datesell;


gen FY_scal=1995;

local mylast $lastyr;
foreach year of numlist 1996/`mylast'{;
replace FY_scal=FY_scal+1 if datesell>=d(01mar`year');
};
notes FY_scal: FY_scal is the scallop fishing year (Mar 1- Feb28/29);




/* 
The scallop category (SCALG SCALS SCALB )cleaning code should probably go here.
*/


 /***********A FEW SCALG CORRECTIONS*******************************/
replace sppcode="SCALB" if permit==240954 & tripid==3296229 & sppcode=="SCALG";   /* This was SCALB incorrectly coded as SCALG, so renamed and then dealt with later.*/
replace sppcode="SCAL" if permit==221273 & tripid==2187129 & sppcode=="SCALG";
replace sppcode="SCAL" if permit==121685 & tripid==2045517 & sppcode=="SCALG";
replace sppcode="SCAL" if permit==221555 & tripid==610575 & sppcode=="SCALG";   /************this is the only vessel in our states that had a gallon of scallops********/
replace qtykept=qtykept*8.3 if permit==221555 & tripid==610575 & sppcode=="SCALG";
/***************end SCALG corrections**************/

 /***********A FEW SCALS CORRECTIONS*******************************/
/*************Deal with SCALS in the GC********** First I sorted by all the GC categories and qty kept (gsort -sppcode - LGCA - LGCB - LGCC - SCG1 - SG1A - SG1B - qtykept).  
I looked at the first few observations with the highest qty and spot checked them to make sure they were correctly entered 
from the trip report scan.  Next-- some people report the actual shell weight conversion and some people don't.  
To deal with this, any value above the cutoff values for GC posession limits (both pre and post aug 1, 2011) we divide by 8.33. 

Assume that those who reported over the quota reported in shell weight.  For the few DAS vessels that landed shelled, 
I guess we have to trust they reported correctly--we cant adjust them b/c they don't necessarily have a possession limit
We added a fudge factor over the possession limit to account for possiblity of having an observer on board.*/

replace qtykept=192 if (permit==150542 & tripid==3289572 & dbyear==2009) & sppcode=="SCALS";  /*********Only 1 sketchy SCALS report************/
replace sppcode="SCAL" if permit==150542 & tripid==3289572 & dbyear==2009 & sppcode=="SCALS"; ;
/*********/


/*********Adjusted the 'dates' below b/c they were not coded correctly*************/
replace qtykept=qtykept/8.33 if sppcode=="SCALS";
replace sppcode="SCAL" if sppcode=="SCALS";

/*************SCALLOP BUSHELS**********************/
/***********I went through the quantities of bushels >60 and spot checked for errors.  I corrected the following obs***/
replace sppcode="SCAL" if permit==250270 & tripid==1060572 & sppcode=="SCALB";
replace qtykept=50 if permit==231221 & tripid==1230404 & qtykept==9520 & sppcode=="SCALB";
replace qtykept=50 if permit==221273 & tripid==1236361 & qtykept==4000 & sppcode=="SCALB";
replace qtykept=50 if permit==221273 & tripid==1236362 & qtykept==4000 & sppcode=="SCALB";
replace qtykept=50 if permit==250542 & tripid==1236151 & qtykept==4000 & sppcode=="SCALB";
replace qtykept=50 if permit==221273 & tripid==1236350 & qtykept==4000 & sppcode=="SCALB";
replace qtykept=49 if permit==250542 & tripid==1236165 & qtykept==3920 & sppcode=="SCALB";
replace qtykept=45 if permit==250542 & tripid==1236161 & qtykept==3840 & sppcode=="SCALB";
replace qtykept=50 if permit==410540 & tripid==1709683 & qtykept==504 & sppcode=="SCALB";
replace qtykept=50 if permit==251138 & tripid==1423433 & qtykept==500 & sppcode=="SCALB";
replace qtykept=50 if permit==231221 & tripid==1418570 & qtykept==500 & sppcode=="SCALB";
replace qtykept=50 if permit==241038 & tripid==1354404 & qtykept==150 & sppcode=="SCALB";
replace qtykept=13 if permit==223518 & tripid==1186787 & qtykept==131 & sppcode=="SCALB";
replace qtykept=12 if permit==223518 & tripid==1186795 & qtykept==121 & sppcode=="SCALB";
replace qtykept=18.5 if permit==231221 & tripid==1490127 & qtykept==119 & sppcode=="SCALB";
replace qtykept=38 if permit==250175 & tripid==2178347 & qtykept==111 & sppcode=="SCALB";
replace qtykept=46 if permit==230748 & tripid==1744473 & qtykept==92 & sppcode=="SCALB";
replace qtykept=41.6 if permit==230748  & tripid==1744467 & qtykept==88 & sppcode=="SCALB";
replace qtykept=32 if permit==250542 & tripid==1313898 & qtykept==82 & sppcode=="SCALB";
replace qtykept=50 if permit==310951 & tripid==2303386 & qtykept==73 & sppcode=="SCALB";
replace qtykept=26 if permit==241038 & tripid==1278291 & qtykept==66 & sppcode=="SCALB";
replace qtykept=40 if permit==221273  & tripid==1236358 & qtykept==3600 & sppcode=="SCALB";
replace qtykept=42 if permit==250542 & tripid==1236154 & qtykept==3360 & sppcode=="SCALB";
replace qtykept=40 if permit==221273 & tripid==1236356 & qtykept==3200 & sppcode=="SCALB";
replace qtykept=50 if permit==231221 & tripid==1230402 & qtykept==2800 & sppcode=="SCALB";
replace qtykept=50 if permit==231221 & tripid==1230407 & qtykept==2400 & sppcode=="SCALB";
replace qtykept=50 if permit==231221 & tripid==1230407 & qtykept==1600 & sppcode=="SCALB";
replace qtykept=135 if permit==242848 & tripid==4145536 & qtykept==788 & sppcode=="SCALB";


replace qtykept=(50*qtykept)/8.33 if sppcode=="SCALB" ;
replace sppcode="SCAL" if sppcode=="SCALB";


replace sppcode="SQL" if permit==410349 & tripid==3210591 & qtykept==11000 & sppcode=="SCAL";













/* This is all based on permit-cats and quantities */

/***this guy is LADAS not GC***/
replace LGCC=0 if permit==330823 & tripid==3193117 & dbyear==2009 ;
replace SC2=1 if permit==330823 & tripid==3193117 & dbyear==2009;


/***********CLASSIFY AND CORRECT GC, as per Justin*******************/
/**********(this may need some adjustment).To correct for GC errors, we divide each GC observation (pre 2008 was SCG1, SG1A, and SG1B, post 2008 was LGCA
LGCB, and LGCC) by a factor of 10 if the qtykept was between 1000 and 9999.  If the qtykept was greater than 10000, we divide by a facotr of 100.  This corrects for the few
misreportings that occurred. The possession limit for GC iss 400lbs, and in august 2011, the LAGC IFQ limit possession limit 
changed to 600 lbs, (200 for NGOM and 40 for INC).********************************************/

replace qtykept=qtykept/10 if (sppcode=="SCAL" & pp==1 & SCG1==1 & qtykept>1000 & qtykept<=10000) | (sppcode=="SCAL" & pp==1 & SG1A==1 & qtykept>1000 & qtykept<=10000) | (sppcode=="SCAL" & pp==1 & SG1B==1 & qtykept>1000 & qtykept<=10000);
replace qtykept=qtykept/100 if (sppcode=="SCAL" & pp==1 & SCG1==1 & qtykept>10000) | (sppcode=="SCAL" & pp==1 & SG1A==1 & qtykept>10000) | (sppcode=="SCAL" & pp==1 & SG1B==1 & qtykept>10000) ;
replace qtykept=qtykept/10 if(sppcode=="SCAL" & pp==1 & LGCA==1 & qtykept>1000 & qtykept<=10000) | (sppcode=="SCAL" & pp==1 & LGCB==1 & qtykept>1000 & qtykept<=10000) | (sppcode=="SCAL" & pp==1 & LGCC==1 & qtykept>1000 & qtykept<=10000);
replace qtykept=qtykept/100 if(sppcode=="SCAL" & pp==1 & LGCA==1 & qtykept>10000) | (sppcode=="SCAL" & pp==1 & LGCB==1 &  qtykept>10000) | (sppcode=="SCAL" & pp==1 & LGCC==1 &  qtykept>10000);

/******CORRECT FOR (SOME) DATA ERRORS.  When I sorted on qtykept, I found a number of qtys that seemed unreasonable.  
ACH note1: I went through the first 30-35 observations, which had qtykepts ranging from around 60,000-almost 900,000 per tripid.  The observations
for years 1994 and 1995 did not have logbook entries that I could investigate (a reason to think twice about those years), but for the years after 95, I found 18 observations 
that were entered erroneaously in the database.  I stopped examining logbook entries right around qtykept= 60,000, as that seemed to be like a max
qty that were being broughrt in on a good day, and there was *more* consistency in the validity of the logbook entries.  Here are those corrections.  

ACH note2: I paused on line 264, drop all pp==2, and looked at the first 500 LGCA trips (those above 780 qtykept).  They are above the limit, and I spot checked many.  
They are all wrong  for different reasons.  Many have just added zeroes, like me and justin found, but some were reported in bushel pounds, 
some were reported as 400 and got encoded as 800, some were reported as 400 and got encoded as 1200, and some did not have and written quantities so someone encoded an arbitrary amount.  
Spot checking all of those trip tickets would take a while but I think the way we scaled them down is appropriate.  Previously, I didn't check all these 500 entries.  

*/


replace qtykept=33654 if permit==330340 & tripid==1338779 & sppcode=="SCAL"; /********this was the observation I sent you.  Looking at the vessel's landing trends, I believe the mystery # to be a 3******/
replace qtykept=17900 if permit==330908 & tripid==4279019 & sppcode=="SCAL";
replace qtykept=48000 if permit==330292 & tripid==3197199 & sppcode=="SCAL";
replace qtykept=16434.5 if permit==330570 & tripid==1280688 & sppcode=="SCAL";
replace qtykept=18120 if permit==410193 & tripid==1658001 & sppcode=="SCAL";
replace qtykept=8177.5 if permit==330664 & tripid==1284810 & sppcode=="SCAL";
replace qtykept=41000 if permit==410019 & tripid==3371216 & sppcode=="SCAL";
replace qtykept=15300 if permit==330903 & tripid==3407371 & sppcode=="SCAL";
replace qtykept=8000 if permit==310928 & tripid==3147948 & sppcode=="SCAL";
replace qtykept=23500 if permit==330353 & tripid==1609901 & sppcode=="SCAL";
replace qtykept=20331 if permit==410167 & tripid==1637399 & sppcode=="SCAL";
replace qtykept=6950 if permit==330832 & tripid==3710712 & sppcode=="SCAL";
replace qtykept=16962 if permit==420045 & tripid==1565296 & sppcode=="SCAL";
replace qtykept=27847 if permit==410341 & tripid==1298016 & sppcode=="SCAL";
replace qtykept=6353.5 if permit==320932 & tripid==1386972 & sppcode=="SCAL";
replace qtykept=31500 if permit==410444 & tripid==2231118 & sppcode=="SCAL";
replace qtykept=6601 if permit==330331 & tripid==1425632 & sppcode=="SCAL";
replace qtykept=24216 if permit==410175 & tripid==1839970 & sppcode=="SCAL";

replace qtykept=16497+2233 if permit==410239& tripid==4447955 & dbyear==2014  & sppcode=="SCAL";
replace qtykept=18000 if tripid==41037114072512 & dbyear==2014 & sppcode=="SCAL";
replace qtykept=15000 if tripid==33052114073011 & dbyear==2014 & sppcode=="SCAL";
replace qtykept=14700 if tripid==33033114032002 & dbyear==2014 & sppcode=="SCAL";
replace qtykept=30021 if permit==330346 & tripid==1661092 & sppcode=="SCAL";

replace qtykept=12000 if tripid==33016614061800 & dbyear==2014 & sppcode=="SCAL";
replace qtykept=11900 if tripid==41037114071110 & dbyear==2014 & sppcode=="SCAL";

replace qtykept=20758 if permit==410261 & tripid==4468907 & sppcode=="SCAL";
replace qtykept=28042 if permit==330476 & tripid==1871725 & sppcode=="SCAL";


/*the qty difference from the errors was 1078083.5 lbs. ;*/
gen tempq=qtykept;
replace tempq=0 if strmatch(sppcode,"SCAL")==0;

bysort permit tripid dbyear: egen triplandings=total(tempq); /*construct trip level SCALLOP  qty to check the possession limits */
drop tempq;

/* LADAS */
gen LADAS=0;
replace LADAS=1 if SC2==1 | SC3==1 | SC4==1 | SC5==1 | SC6==1 | SC7==1 | SC8==1 | SC9==1;

/*GC */
gen GC=0;
replace GC=1 if (LGCA==1 | LGCB==1 | LGCC==1)&  date< d(01mar2010);
replace GC=1 if (SCG1==1 | SG1A==1 | SG1B==1)&  date< d(01mar2010);
replace GC=0 if (LADAS==1 & SCG1==1) &  date< d(01mar2010); /*I'm not quite sure if this is a data error, but I'm going to call it LADAS */

/* There are 3492 observations that have GC==1 and LADAS==1 and are from 2008/2009 FY
I use 500lbs as the cutoff (400lbs, plus fudge)
EDIT -- I'm going to use 1200lbs for FY 2008/9 

*/
replace GC=0 if LADAS==1 & triplandings>1200 &  date< d(01mar2010);
replace LADAS=0 if GC==1 & LADAS==1 & triplandings<=1200 &  date< d(01mar2010);

gen NGOM=0;
gen IFQ=0;
gen INC=0;


/*while the permt data characterized NGOM, IFQ, and INC beginning with the 2008 FY, there were not active until the 2010 FY 
*/
replace IFQ=1 if LGCA==1 & date>= d(01mar2010);
replace NGOM=1 if LGCB==1 & date>=d(01mar2010);
replace INC=1 if LGCC==1 & date>=d(01mar2010);

/* Deal with IFQ and LADAS */
/* I BROKE THIS INTO MULTIPLE LINES  just to make the logic easier to follow
a. It has an IFQ permit and no other Scallop permit
b. It had an IFQ permit, another permit, less than 900 lbs of scallop meats after August 1, 2011
b. It had an IFQ permit, another permit, and sold between 200 and 700 lbs of scallop meats before August 1, 2011
*/
replace LADAS=0 if IFQ==1 & tripl<=900 & date>=d(01aug2011);
replace IFQ=0 if LADAS==1 & tripl>900 & date>=d(01aug2011);

replace LADAS=0 if IFQ==1 & tripl<=700 & date<d(01aug2011);
replace IFQ=0 if LADAS==1 & tripl>700 & date<d(01aug2011);


/* Deal with NGOM and LADAS */
replace LADAS=0 if NGOM==1 & tripl<=300;
replace NGOM=0 if LADAS==1 & tripl>300;

/* Deal with NGOM and LADAS */
replace LADAS=0 if INC==1 & tripl<=80;
replace INC=0 if LADAS==1 & tripl>80;


/* DEAL WITH IFQ, NGOM, INC, and Nopermit */

/*************The industry funded observer program started with amm 16 on Nov 16, 2004.  It was then 'reactivated' in 2008, but as of now, 
				I do not know when it was deactivated, I'll have to check this out
ML: Okay, good catch. we'll leave this code here but commented out so we can get it back in later.****************************/


/********Effective August 1, 2011, (http://www.nero.noaa.gov/nero/nr/nrdoc/11/11ScallA15-FW22%20PHL.pdfLAGCIFQ)
							vessels could land up to 600lbs.  We add +300 to the GC/IFQ "cutoff" to account for observer coverage/(research set-aside?).
							For NGOM, the possession limit is 200 lbs, we add 100 for the cutoff point
							For INC we add 40 lbs to the cutoff point*********************************************/
/*make sure nothing gets double-clasified**********/

foreach p of varlist LADAS IFQ NGOM INC GC{ ;
	replace `p'=0 if `p'==.;
};
egen ppp= rowtotal(IFQ LADAS NGOM INC GC);
gsort -ppp;
assert ppp<=1;
gen pcheck=0;
replace pcheck=1 if ppp==0;

/*********Make the "No-permit" category. ***********/
gen Nopermit_scal=1 if ppp==0;					
replace Nopermit_scal=0 if Nopermit_scal==.;
assert pcheck==Nopermit_scal;
drop pcheck ppp ;


egen pppp= rowtotal (IFQ NGOM INC GC LADAS Nopermit_scal);
assert pppp==1;
drop pppp;
gen fulltime=0;
replace fulltime=1 if SC2==1 | SC5==1 | SC7==1;
gen parttime=0;
replace parttime=1 if SC3==1 | SC6==1 | SC8==1;
gen occasional=0;
replace occasional=1 if SC4==1 | SC9==1;

save "${data_main}\veslog_species_huge_${vintage_string}.dta", replace;

replace sppcode="RED" if strmatch(sppcode, "REDG")==1;

merge m:1 sppcode using `nespp34', keep(1 3) ; 
/********get nespp3/4*********/   
replace nespp3=045 if sppcode=="BULL" & permit==250726 & tripid==4928206;
replace nespp4=0450 if sppcode=="BULL" & permit==250726 & tripid==4928206;

replace nespp3=365 if sppcode=="SKSMALL" & permit==146679 ;
replace nespp4=3650 if sppcode=="SKSMALL" & permit==146679 ;

replace _merge=3 if _merge==1 & sppcode=="SKSMALL" & permit==146679;

replace _merge=3 if _merge==1 & sppcode=="BULL" & permit==250726 & tripid==4928206;

assert _merge==3;


drop _merge;


rename nespp3 myspp;
replace myspp=509 if myspp==508 | myspp==507;

replace myspp=365 if myspp == 373;
replace myspp = 776 if inlist(myspp, 777, 778, 779) ;

/*THIS IS A GOOD PLACE TO DEAL WITH MONKFISH?


 */





/* There are few datesell's (14) that have obviously incorrect dates from before 1996.
list permit tripid datesell year if year(dofc(datesell))<=1995
 These look like data entry problems */
gen month= month(date);
gen year=year(date);
drop if year>$lastyr;

/* two entries with null permits */
replace permit=214885 if tripid==3680697 & permit==. & dbyear==2011;
replace permit=214885 if tripid==3681549 & permit==. & dbyear==2011;

/* Note that year is the year of veslog/cfdbs and NOT necessarily the year corresponding to the date that fish was landed or sold. */
save "${data_main}\veslog_species_huge_${vintage_string}.dta", replace;



/* CLEAN UP THE PORTLND1 FIELD 
We need to do a few bits of cleaning on the PORTLND1, STATE1, and PORT fields.
1.  We will fill in the missing PORT codes based on PORTLND1, STATE1 using "null_ports_trim"
2.  We will then use the PORTNM and STATEABB associated with those PORT codes as our "city" and "state."
3.  We will get the corrected PORTNM and STATEABB from the PORT codes 
4.  We will manually fix the entries that have a PORT code tha corresponds to "OTHER"
5.  Merge/append fishing communities from Julie Olson based on the PORT code. This will bring in "Lat-lon" and a PORT-GROUP name */

/**********************MERGING PORTS***************/
/* FILL IN NULL PORTS */


/****************merge to null_ports---we merge here using the current data's state1, renamed (statesyn) and portlnd1 (renamed) portsyn.  These two variables
						are the INCORRECT names in the null_ports_trimmed.dta.  If they match==3 with null_ports_trimmed, we replace the current port (number) 
						state1, and portlnd1 (name) with the CORRECT port, stateabb, and portnm respectively, from null_ports_trimmed*****************************/

/*1.  We will fill in the missing PORT codes based on PORTLND1, STATE1 using "null_ports_trim"
2.  We will then use the PORTNM and STATEABB associated with those PORT codes as our new portlnd1, state1
3.  We will get the corrected PORTNM and STATEABB from the PORT codes */

replace portlnd1= itrim(trim(portlnd1));

/*create portsyn and statesyn to merge to a table based on vlportsyn*/
gen portsyn= portlnd1;
gen statesyn=state1;

/*load in portnm, stateabb from the PORT table, join it to the null_ports_trim table */
 
preserve;
tempfile portfixer portregular;
clear;
odbc load, exec("select port, portnm, stateabb from port;") $oracle_cxn;  
renvarlab, lower; 
destring, replace;
save `portregular';

merge 1:m port using "${data_external}\null_ports_trim.dta", keep(3) nogenerate;
sort portsyn statesyn ;
order portsyn statesyn port;
rename port port_fixed ;
save `portfixer';
restore;

/* merge the data to the portfixer table, update the portlnd1, state1, port_fixed fields if port_fixed was missing and there was a match in the merge */
merge m:1 portsyn statesyn using `portfixer', keep(1 3);
replace portlnd1=portnm if port==. & _merge==3 ; 
replace state1=stateabb if port==. & _merge==3 ;
replace port=port_fixed if port==. & _merge==3 ;
replace port=490869 if permit==330340 & tripid==247199 & port==.;
replace state1="VA" if permit==330340 & tripid==247199 & state1=="";
replace stateabb="VA" if permit==330340 & tripid==247199 & stateabb=="";
replace portlnd1="SEAFORD" if permit==330340 & tripid==247199 & portlnd1=="";
replace portnm="SEAFORD" if permit==330340 & tripid==247199 & portnm=="";
replace portnm="HAMPTON" if portnm=="HAMPTON/SEABROOK" & stateabb=="NH";


drop _merge ;
collapse (sum)  qtykept, by( dealnum sppcode state1 portlnd1 permit port tripid year myspp date month dbyear IFQ NGOM INC GC LADAS Nopermit_scal) ;
save "${data_main}\veslog_species_huge_${vintage_string}.dta", replace;

merge m:1 tripid dbyear using "${data_intermediate}\final_all_port_corrections.dta", keep (1 3); 
replace portlnd1=corrected_port if _merge==3;
replace state1=corrected_state if _merge==3;
drop corrected_port corrected_state _merge;

/*******WE HAVE TO CORRECT THE SPELLINNG MISTAKES IN THIS DATASET SO THEY MERGE CORRECTLY TO JULIES TABLE.  THESE are obvious spelling mistakes.  
The spelling fixer correct a very large number of problematic PORTLND1&STATE1s that are causing mis-merges **************/
quietly do "${extraction_code}\spelling_fixer1.do";
drop if state1=="MS" ; 
drop if state1=="WA" ;
drop if state1=="FL" ;
drop if state1=="GA" ;
*drop if state1=="NC" ;
drop if state1=="CN" ;
drop if state1=="LA" ;
drop if state1=="SC" ;
drop if state1=="PR" ;


save "${data_main}\veslog_species_huge_${vintage_string}.dta", replace;



/*******There are still some mis-merges.  These require a bit of judgement, so I've separated them from the other "spelling_fixer1.do" file**************/

merge m:1 portlnd1 state1 using "${data_external}\communities_cleaned3.dta", keep(1 3);
keep if _merge==1 | strmatch(portlnd, "*OTHER*")==1;
keep permit tripid dbyear portlnd1 state1;
duplicates drop ;
notes: broken_tripids contains the data that did not successfully match to a the communities;

save "${data_intermediate}\broken_tripids.dta", replace;



/* NOTE TO MINYANG: IF YOU do the following:
This will save a copy of all the entries that have "broken" portlnd1 and state1.  Then you can run the next chuck of code (until the save statement)
to create a dataset of "fixed" tripid, permit, years and the "corrected portlnd1 state1".
*/

gen corrected_port="";
/*******These corrections are not necessarily spelling mistakes, but assigning PORTS to VTR records that are strange or incorrect**************/
replace corrected_port="EASTPORT" if (permit==146575 & portlnd1=="LONG ISLAND");
replace corrected_port="FREEPORT" if (permit==213539 & portlnd1=="LONG ISLAND");
replace corrected_port="FREEPORT" if (permit==330390 & portlnd1=="LONG ISLAND");
replace corrected_port="MORICHES" if (permit==800270 & portlnd1=="LONG ISLAND");

replace corrected_port="SANDWICH" if (portlnd1=="CAPE COD BAY" & state1=="MA" & permit==241110) ;

replace corrected_port="GREAT KILLS" if permit==116569 & portlnd1=="HOBOKEN" ;
replace state1="NY" if corrected_port=="GREAT KILLS" ;



replace corrected_port="FREEPORT" if permit==330388 & portlnd1=="JONES BEACH" ;
replace corrected_port="POINT LOOKOUT" if permit==330529 & portlnd1=="JONES BEACH" ;


replace corrected_port="SETAUKET" if permit==231494 & portlnd1=="LONG ISLAND";
replace state1="NY" if permit==231494 & corrected_port=="SETAUKET";
replace corrected_port="MENEMSHA" if permit==240535 & (portlnd1=="MARTHA'S VINEYARD" | portlnd1=="MARTHAS VINEYARD");
replace corrected_port="NANTUCKET" if permit==310274 & portlnd1=="MARTHAS VINEYARD";
replace corrected_port="CHATHAM" if permit==128321 & portlnd1=="MARTHAS VINEYARD";
replace corrected_port="WOODS HOLE" if permit==240095 & portlnd1=="MARTHAS VINEYARD";
replace corrected_port="NEW BEDFORD" if permit==220438 & portlnd1=="MARTHAS VINEYARD";
replace corrected_port="NEW BEDFORD" if permit==330198 & portlnd1=="MARTHAS VINEYARD";
replace corrected_port="MENEMSHA" if permit==250274 & portlnd1=="MARTHAS VINEYARD";

replace corrected_port="SOUTHAMPTON" if permit==800630 & portlnd1=="MECOX";
replace corrected_port="MONTAUK" if permit==800387 & portlnd1=="NEWPORT INLET";
replace corrected_port="QUEENS" if (permit==800427 & portlnd1=="ORLEANS");
replace corrected_port="NEW BEDFORD" if (permit==220438 & portlnd1=="MARTHAS VINEYARD") ;
replace corrected_port="SWAMPSCOTT" if  (portlnd1=="UNKNOWN" & permit==211573);

replace corrected_port="GREENPORT" if permit==800129 & tripid==894898 ;
replace state1="NY" if corrected_port=="GREENPORT" ;

replace corrected_port="LONG BEACH" if (portlnd1=="LONG ISLAND" & permit==149254 & tripid==2219299);
replace corrected_port="SHINNECOCK" if (portlnd1=="OTHER NY" & tripid==687440);
replace corrected_port="CAMBRIDGE" if (portlnd1=="OTHER CALVERT" & state1=="MD" & permit==233536);
replace corrected_port="CAMBRIDGE" if (portlnd1=="OTHER DORCHESTER" & state1=="MD"& permit==233536);
replace corrected_port="NANTICOKE" if (portlnd1=="OTHER DORCHESTER" & state1=="MD" & permit==211840 & tripid==1414673);
replace corrected_port="GREENPORT" if portlnd1=="NEW SUFFOLK" ;
replace corrected_port="MONMOUTH BEACH" if (portlnd1=="MONMOUTH" & permit==114599); 
replace state1="NJ" if corrected_port=="MONMOUTH BEACH"; 

replace corrected_port="BELFORD" if portlnd1=="MONMOUTH" & (permit==232036 | permit==240320 | permit==. | permit==220326) ;
replace state1="NJ" if corrected_port=="BELFORD"; 

replace corrected_port="HAMPTON BAYS" if tripid== 3357495 & dbyear==2010;
replace corrected_port="HAMPTON BAYS" if tripid== 3357517 & dbyear==2010;
replace corrected_port="HAMPTON BAYS" if tripid== 3357526 & dbyear==2010;
replace corrected_port="HAMPTON BAYS" if tripid== 3357527 & dbyear==2010;
replace corrected_port="HAMPTON BAYS" if tripid== 3357528 & dbyear==2010;
replace corrected_port="HAMPTON BAYS" if tripid== 3357529 & dbyear==2010;
replace corrected_port="HAMPTON BAYS" if tripid== 3357537 & dbyear==2010;
replace corrected_port="HAMPTON BAYS" if tripid== 3357539 & dbyear==2010;
replace corrected_port="HAMPTON BAYS" if tripid== 3357551 & dbyear==2010;
replace corrected_port="HAMPTON BAYS" if tripid== 3357552 & dbyear==2010;
replace corrected_port="HAMPTON BAYS" if tripid== 3557986 & dbyear==2010;
replace corrected_port="HAMPTON BAYS" if tripid== 3557987 & dbyear==2010;

replace corrected_port="CHINCOTEAGUE" if permit==330455 & (tripid== 167644 | tripid== 168612); 
replace corrected_port="NEW BEDFORD" if permit==330168 & tripid== 176507;
replace state1="MA" if permit==330168 & tripid== 176507;  
replace corrected_port="CHINCOTEAGUE" if permit==330220 & tripid== 168612; 
replace corrected_port="POINT LOOKOUT" if permit==330388  & tripid== 149799;

replace corrected_port="AMAGANSETT" if permit==800315 & tripid==687988; 
replace state1="NY" if corrected_port=="AMAGANSETT"; 
rename state1 corrected_state;
drop if portlnd1=="PRIVATE HARBOR" ;







/*Geret's edits next couple of lines*/
replace portlnd1 = "BATH" if inlist(tripid,2948790,3213806,3162434,3268396) & inlist(permit, 310938,321092);
replace portlnd1 = "BROAD CREEK" if inlist(tripid,3093489,3312213) & inlist(permit, 330336);



replace portlnd1 = "COINJOCK" if inlist(tripid,3554039, 3614749,3616066) & inlist(permit, 321096);
replace portlnd1 = "COINJOCK" if inlist(tripid,4529357) & inlist(permit, 242817);




/*******These require a bit of judgement, so I've separated them from the other "spelling_fixer1.do" file**************/
replace corrected_state="NC" if portlnd1=="BROAD CREEK" & corrected_state=="MD"; /* This is way inland.  We're not going to keep these two observations */


replace portlnd1="POINT PLEASANT" if (portlnd1=="JONES BEACH" & permit==330683 & tripid==1943643) ;
replace corrected_state="NJ" if permit==330683 & tripid==1943643 ;
replace portlnd1="SANDWICH" if portlnd1=="CAPE COD BAY" & corrected_state=="MA" & permit==241110 ;
replace portlnd1="HARWICH PORT" if portlnd1=="CAPE COD" & corrected_state=="MA" & permit==148245 ;
replace portlnd1="SAQUATUCKET HARBOR" if portlnd1=="CAPE COD" & corrected_state=="MA" & permit==146862 ;
replace portlnd1="ATLANTIC CITY" if portlnd1=="DOCKSIDE" ;
replace portlnd1="ATLANTIC CITY" if permit==330592 & tripid==2255429;

replace corrected_state="VA" if permit==320932 & tripid==1771428 & dbyear==2003;
replace portlnd1="HAMPTON BAYS" if permit==250175 & tripid==2248301 & dbyear==2005;
replace portlnd1="COINJOCK" if portlnd1=="COINJACK" | portlnd1=="LOINJOCK" ;












replace corrected_port=ltrim(rtrim(itrim(corrected_port)));

drop portlnd1;
sort permit tripid dbyear corrected_port corrected_state;
save "${data_intermediate}\broken_tripids.dta", replace;




/*merge broken tripids */
use "${data_main}\veslog_species_huge_${vintage_string}.dta", replace;

merge m:1 permit tripid dbyear using "${data_intermediate}\broken_tripids.dta";
replace portlnd1=corrected_port if _merge==3;
replace state1=corrected_state if _merge==3;
drop corrected_port corrected_state _merge;



/*Some of the trips from our VESLOG data are either not really commercial trips */
drop if dbyear==2004 & tripid==2004783;
drop if dbyear==2004 & tripid==2004785;
drop if dbyear==2004 & tripid==2004790;
drop if dbyear==2005 & tripid==2235280;
drop if dbyear==2007 & tripid==2749165;
drop if dbyear==2007 & tripid==2749170;
drop if dbyear==2007 & tripid==2753659;


/*Some of the trips from our VESLOG data are impossible to map or not in the Greatest Atlantic Region */

drop if portlnd1=="PRIVATE HARBOR" ;
drop if state1=="MS" ; 
drop if state1=="WA" ;
drop if state1=="FL" ;
drop if state1=="GA" ;
*drop if state1=="NC" ;
drop if state1=="CN" ;
drop if state1=="LA" ;
drop if state1=="SC" ;
drop if state1=="PR" ;
drop if state1=="AL" ;
drop if state1=="TX" ;
drop if state1=="NS" ;



replace port=350835 if strmatch(portlnd1,"AMAGANSETT")==1 & port==. & state1=="NY";
replace port=350535 if strmatch(portlnd1,"GREENPORT")==1 & port==. & state1=="NY";


replace portlnd1="MONMOUTH BEACH" if (portlnd1=="MONMOUTH" & permit==114599); 
replace state1="NJ" if portlnd1=="MONMOUTH BEACH"; 

replace portlnd1="BELFORD" if portlnd1=="MONMOUTH" & (permit==232036 | permit==240320 | permit==. | permit==220326) ;
replace state1="NJ" if portlnd1=="BELFORD"; 
replace port=331125 if strmatch(portlnd1,"BELFORD")==1 & state1=="NJ";

replace portlnd1="HAMPTON" if (permit==330452 & tripid==33045214121316); 
replace port=490118 if (permit==330452 & tripid==33045214121316);

replace state1="NC" if portlnd1=="BROAD CREEK" & state1=="MD"; 
replace portlnd1="POINT PLEASANT" if (portlnd1=="JONES BEACH" & permit==330683 & tripid==1943643) ;
replace state1="NJ" if permit==330683 & tripid==1943643 ;
replace portlnd1="SANDWICH" if portlnd1=="CAPE COD BAY" & state1=="MA" & permit==241110 ;
replace portlnd1="HARWICH PORT" if portlnd1=="CAPE COD" & state1=="MA" & permit==148245 ;
replace portlnd1="SAQUATUCKET HARBOR" if portlnd1=="CAPE COD" & state1=="MA" & permit==146862 ;
replace portlnd1="ATLANTIC CITY" if portlnd1=="DOCKSIDE" ;
replace portlnd1="ATLANTIC CITY" if permit==330592 & tripid==2255429;

replace state1="VA" if permit==320932 & tripid==1771428 & dbyear==2003;
replace portlnd1="HAMPTON BAYS" if permit==250175 & tripid==2248301 & dbyear==2005;
replace portlnd1="COINJOCK" if portlnd1=="COINJACK" | portlnd1=="LOINJOCK" ;




/* what is this?
drop if permit==241134 & tripid==1552054 & sppcode=="SCAL";

drop if permit==330336 & tripid==1626181 & sppcode=="SCAL";
*/

/*******************************************PHEW, OKAY LETS KEEP GOING************************************************/

replace portlnd1 = "CANADA" if portlnd1 == "" & inlist(port, 960999,960499,964099);
replace portlnd1 = "CAPE CANAVERAL" if portlnd1 == "" & port == 100101;
replace portlnd1 = "OTHER DUVAL" if portlnd1 == "" & port == 100908;
replace portlnd1 = "OTHER ST JOHNS" if portlnd1 == "" & port == 100927;
replace portlnd1 = "OTHER GULF" if portlnd1 == "" & port == 110915;
replace portlnd1 = "BRUNSWICK" if portlnd1 == "" & port == 130115;
replace portlnd1 = "OTHER MACINTOSH" if portlnd1 == "" & port == 130921;
replace portlnd1 = "OTHER YORK" if portlnd1 == "" & port == 220920;
replace portlnd1 = "MENEMSHA" if portlnd1 == "" & port == 240905 & inlist(tripid,2731507,2378454);
replace portlnd1 = "OCEANPORT" if portlnd1 == "" & port == 330925 & inlist(tripid,2681955);
replace portlnd1 = "OTHER NASSAU" if portlnd1 == "" & port == 350915 & inlist(tripid,2327735);
replace portlnd1 = "BAYPORT" if portlnd1 == "" & port == 350935 & inlist(tripid,2550302,2449963);
replace portlnd1 = "SAYVILLE" if portlnd1 == "" & port == 350935 & inlist(tripid,2449962);
replace portlnd1 = "HAMPTON BAYS" if portlnd1 == "" & inlist(port, 350935,350999) & inlist(tripid,2449963,3826214,3825883,3825884,3826216,3826217);
replace portlnd1 = "ENGELHARD" if portlnd1 == "" & port == 350999 & inlist(tripid,2775095);
	replace state1 = "NC" if port == 350999 & portlnd1 == "ENGELHARD" & state1 == "NY" & inlist(tripid,2775095);
replace portlnd1 = "COINJOCK" if inlist(port, 360917,360999) & inlist(tripid, 2179832,2185982,2197868,2198021);
replace portlnd1 = "ORIENTAL" if inlist(port, 360999) & inlist(tripid, 3370288);
replace portlnd1 = "OTHER BEAUFORT" if port == 430903;
replace portlnd1 = "OTHER CHARLESTON" if port == 430907;
replace portlnd1 = "GEORGETOWN" if port == 430913;
replace portlnd1 = "OTHER CHARLESTON" if port == 430907;
replace portlnd1 = "CAPE MAY" if portlnd1 == "" & port == . & tripid == 3420001;
replace state1 = "NJ" if portlnd1 == "CAPE MAY" & port == . & tripid == 3420001;

replace portlnd1 = "NEW BERN" if portlnd1 == "" & tripid == 4005107 & port == 360913;
replace portlnd1 = "SAN JUAN" if portlnd1 == "" & port == 550101;

replace portlnd1 = "COINJOCK" if inlist(tripid,3554039, 3614749,3616066) & inlist(permit, 321096);
replace portlnd1 = "COINJOCK" if inlist(tripid,4529357) & inlist(permit, 242817);
replace portlnd1 = "COINJOCK" if portlnd1=="COINJACK" | portlnd1=="LOINJOCK" ;
drop if permit==241134 & tripid==1552054;

drop if permit==330336 & tripid==1626181;

/* these two guys clearly wrote "PORT MONMOUTH" */
replace portlnd1="PORT MONMOUTH" if portlnd1=="MONMOUTH" & permit==250571 & (dbyear>=1996 & dbyear<=1999);
replace portlnd1="PORT MONMOUTH" if portlnd1=="MONMOUTH" & permit==220256 & dbyear==2001;

/* this guy may have landed in "port monmouth", "avon-by-the-sea", "belford", or "point pleasant" it's very hard to tell. I'm putting him into point pleasant, based on the corresponding dealer data*/
replace portlnd1="POINT PLEASANT" if portlnd1=="MONMOUTH" & permit==215166 & (dbyear>=2013 & dbyear<=2014);

replace portlnd1 = "BATH" if inlist(tripid,2948790,3213806,3162434,3268396) & inlist(permit, 310938,321092);
replace portlnd1 = "BROAD CREEK" if inlist(tripid,3093489,3312213) & inlist(permit, 330336);

/* Lou's corrections will go here. 
*/

replace portlnd1 = "SOUTHPORT" if inlist(tripid,2052109) & permit==148178 & dbyear==2004;
replace portlnd1 = "COINJOCK" if inlist(tripid,4449368,4667120,4685734) & permit==242817 & (dbyear==2014 | dbyear==2015);
replace portlnd1 = "SOUTHPORT" if inlist(tripid,1301481) & permit==250399 & dbyear==2001;
replace portlnd1 = "COINJOCK" if inlist(tripid,4657954) & permit==250726 & dbyear==2015;

/***This guy was writing "Core creek"-- Tthe lat/long of this area in google maps corresponds to
    the area "Beaufort, NC" in Julie's table ***/
replace portlnd1 = "BEAUFORT" if inlist(tripid, 1214242, 1227092, 1227864, 1229452, 1229559) & permit==251074 & dbyear==2001;

replace portlnd1 = "COINJOCK" if inlist(tripid,4424341) & permit==310915 & dbyear==2014;
replace portlnd1 = "BEAUFORT" if inlist(tripid,192978) & permit==320269 & dbyear==1996;
replace portlnd1 = "SOUTHPORT" if inlist(tripid,863052, 863053, 878182) & permit==320669 & dbyear==1999;

/***This guy was writing Merrimon, NC, which is NOT in Julies table. However, he provided a zipcode, 28516 that
    corresponds to Beaufort.***/
replace portlnd1 = "BEAUFORT" if inlist(tripid,1943025, 1943050, 1963540) & permit==320815 & dbyear==2004;

replace portlnd1 = "WRIGHTS CREEK" if inlist(tripid,4471447) & permit==321092 & dbyear==2014;
replace portlnd1 = "COINJOCK" if inlist(tripid,2424701, 3342183) & permit==321096 & (dbyear==2006 | dbyear==2010);
replace portlnd1 = "BROAD CREEK" if inlist(tripid, 216657, 453920, 453926, 454732, 1056934, 1065092, 1203494, 1210734, 1210735, 1251976, 1251977, 1424190, 1475917)
                    & permit==330288 & inlist(dbyear, 1996,1997,2000,2001,2002);                
replace portlnd1 = "NEWPORT" if inlist(tripid, 204676, 1486127) & permit==330336 & (dbyear==1996 | dbyear==2002);
replace portlnd1 = "COINJOCK" if inlist(tripid,2179439, 2217592) & permit==330390 & (dbyear==2005);
replace portlnd1 = "COINJOCK" if inlist(tripid,4469876) & permit==330742 & (dbyear==2014);
replace portlnd1 = "COINJOCK" if inlist(tripid,4415374) & permit==330827 & (dbyear==2014);
replace portlnd1 = "COINJOCK" if inlist(tripid,4424123) & permit==330829 & (dbyear==2014);
replace portlnd1 = "COINJOCK" if inlist(tripid,4418608) & permit==330879 & (dbyear==2014);
replace portlnd1 = "ENGELHARD" if inlist(tripid,154985) & permit==410275 & (dbyear==1996);
replace portlnd1 = "ENGELHARD" if inlist(tripid,153693) & permit==410291 & (dbyear==1996);




























/*There are still approximately 11,000 "other" or "empty" ports. Ideally this is fixed here. or a bit earlier. They are not matching to a GEOID 
LOU has corrected these by looking at VTRs.  The data and code can be found at 
/Documents/projects/spacepanels/port data/extra_port_corrections/images_corrected_Aug23.dta
/Documents/projects/spacepanels/port data/extra_port_corrections/newportcorrections1.do

*/

/* works to here */
save "${data_main}\veslog_species_huge_${vintage_string}.dta", replace;

#delimit;
merge m:1 permit tripid dbyear using "${data_external}/corrected_Aug23.dta";
replace portlnd1=corr_portlnd1 if corr_portlnd~="" & _merge==3;
replace state1=corr_state1 if corr_state1~="" & _merge==3;
drop _merge corr_state1 corr_portlnd1;

/* last strange fix  -- this electronic FVTR was put into "OTHER NEWPORT", but the vessel mostly lands in Pt. Judith. This might be cooperative/RSA fishing, but whatver.*/

replace portlnd1="POINT JUDITH" if tripid==25069311102511;


replace portlnd1 = "KILL DEVIL HILLS" if portlnd1=="" & (tripid==4847196) & permit==149962 ;
replace portlnd1 = "MATHEWS" if portlnd1=="" & (tripid>=4702095 & tripid<=4787994) & permit==151166 ;

replace portlnd1 = "MATHEWS" if (tripid>=4854323 & tripid<=4911295) & permit==151166 & portlnd1=="OTHER VA";
replace portlnd1 = "MATHEWS" if  portlnd1=="OTHER VA" & (tripid>=4862056 & tripid<=4899494) & permit==151170 ;


replace portlnd1 = "MATHEWS" if  portlnd1==""  & (tripid>=4695348 & tripid<=4788561) & permit==151170 ;
replace portlnd1 = "MATHEWS" if  portlnd1==""  & (tripid>=4690811 & tripid<=4773450) & permit==151171 ;
replace portlnd1 = "MATHEWS" if  portlnd1==""  & (tripid>=4838828 & tripid<=4845137) & permit==212429 ;
replace portlnd1 = "MATHEWS" if  (tripid==4838921) & permit==233760;
replace portlnd1 = "SOUTHPORT"  if portlnd1==""  & (tripid>=4814041 & tripid<=4825391) & permit==251705 ;

replace portlnd1 = "AVONDALE" if strmatch(portlnd1,"") & permit==117930	& tripid==	1378613;
replace portlnd1 = "SOUTHPORT" if strmatch(portlnd1,"") & permit==134101	& tripid>=1783073 &  tripid<=1804257;
replace portlnd1 = "SOUTHPORT" if strmatch(portlnd1,"") & permit==137794	& tripid>=1165655 &  tripid<=1320539;
replace portlnd1 = "SOUTHPORT" if strmatch(portlnd1,"") & permit==148178	& tripid>=1191601 &  tripid<=1919711;
replace portlnd1 = "NAGS HEAD" if strmatch(portlnd1,"") & permit==135638	& tripid>=1060211 &  tripid<=1060221;
replace portlnd1 = "REEDVILLE" if strmatch(portlnd1,"") & permit==147564	& tripid>=1719302 &  tripid<=1719410;
replace portlnd1 = "JONESBORO" if strmatch(portlnd1,"") & permit==148419	& tripid>=1453571 &  tripid<=2323047;
replace portlnd1 = "DOVER" if strmatch(portlnd1,"") & permit==210388	& tripid>=1019646 &  tripid<=1023097;
replace portlnd1 = "SHARPTOWN" if strmatch(portlnd1,"") & permit==213054	& tripid==1754714;
replace portlnd1 = "SHARPTOWN" if strmatch(portlnd1,"") & permit==211840	& tripid>=1064348 &  tripid<=1088560;
replace state1 = "MD" if strmatch(portlnd1,"SHARPTOWN") & permit==211840	& tripid>=1064348 &  tripid<=1088560;

replace portlnd1 = "REHOBOTH" if strmatch(portlnd1,"") & permit==220186	& tripid>=229871 &  tripid<=1632948;
replace portlnd1 = "WILMINGTON" if strmatch(portlnd1,"") & permit==223370	& tripid==	2719155;
replace portlnd1 = "MATHEWS" if portlnd1=="" & (tripid>=1087382 & tripid<=1220822) & permit==223372 ;
replace portlnd1 = "BELLE HAVEN" if portlnd1=="" & (tripid>=1104442 & tripid<=1564520) & permit==223384 ;
replace portlnd1 = "BELLE HAVEN" if portlnd1=="" & (tripid>=928789 & tripid<=1177286) & permit==223406 ;
replace portlnd1 = "RUMBLEY" if portlnd1=="" & (tripid>=1273650 & tripid<=1273730) & permit==223461 ;
replace portlnd1 = "RUMBLEY" if portlnd1=="" & (tripid>=1301656 & tripid<=1378758) & permit==223461 ;
replace portlnd1 = "CRIEHAVEN" if portlnd1=="" & (tripid>=1301644 & tripid<=1872478) & permit==231564 ;
replace portlnd1 = "HARPSWELL" if portlnd1=="" & (tripid>=1082794 & tripid<=1083110) & permit==231886 ;

replace portlnd1 = "RODANTHE" if portlnd1=="" & (tripid>=1645640 & tripid<=1659381) & permit==232452 ;
replace portlnd1 = "HARBORTON" if portlnd1=="" & (tripid>=1136582 & tripid<=1847153) & permit==233181 ;
replace portlnd1 = "HARPSWELL" if portlnd1=="" & (tripid==1407473) & permit==233254 ;
replace portlnd1 = "HARPSWELL" if portlnd1=="" & (tripid>=1077422 & tripid<=1077492) & permit==241615 ;

replace portlnd1 = "ONANCOCK" if portlnd1=="" & (tripid>=1480755 & tripid<=1480814) & permit==242546 ;
replace portlnd1 = "SOUTHPORT" if portlnd1=="" & (tripid>=1263361 & tripid<=1380542) & permit==250399 ;
replace portlnd1 = "SOUTHPORT" if portlnd1=="" & (tripid>=878019 & tripid<=1336660) & permit==320620 ;
replace portlnd1 = "NEWPORT" if portlnd1=="" & (tripid>=590356 & tripid<=1254384) & permit==330288 ;
replace portlnd1 = "NEWPORT" if portlnd1=="" & (tripid>=458302 & tripid<=1521628) & permit==330336 ;

replace portlnd1 = "COINJOCK" if portlnd1=="" & (tripid>=2184259 & tripid<=2187303) & permit==330828 ;
replace portlnd1 = "COINJOCK" if portlnd1=="" & (tripid==2170633) & permit==410286 ;
replace portlnd1 = "WINTERPORT" if portlnd1=="" & (tripid>=1388134 & tripid<=1406226) & permit==410474 ;


replace portlnd1 = "QUINBY" if portlnd1=="" & permit==146836 & tripid==1692109;
replace portlnd1 = "QUINBY" if portlnd1=="" & permit==233167 & tripid==1569906;


replace portlnd1 = "JONESBORO" if portlnd1=="" & permit==148419 & tripid==2323047;


replace portlnd1 = "SAGAMORE" if portlnd1=="" & permit==137794 & tripid==1611295;
replace portlnd1 = "EAST ORLEANS" if portlnd1=="" & permit==148012 & tripid==2242586;


replace portlnd1 = "STUMPY POINT" if portlnd1=="" & permit==223381 & tripid==1653713;



replace portlnd1 = "GOOSE CREEK" if portlnd1=="" & (tripid==1301644) & permit==223461 ;

replace portlnd1 = "YARMOUTH" if portlnd1=="" & (tripid==1656882) & permit==148867 ;

replace portlnd1 = "PRIVATE HARBOR" if portlnd1=="" & (tripid==1754719) & permit==213054 ;
replace portlnd1="WARREN GROVE" if permit==251212 & portlnd1=="OTHER NJ" & dbyear==2016;
replace portlnd1="WARREN GROVE" if permit==251212 & portlnd1=="OTHER NEW JERSEY" & dbyear==2016;

replace portlnd1="BRONX" if permit==310153 & portlnd1=="OTHER NY" & dbyear==2016;
replace portlnd1="BRONX" if permit==310153 & portlnd1=="OTHER NEW YORK" & dbyear==2016;


replace portlnd1="HAMPTON" if portlnd1=="HAMPTON/SEABROOK" & state1=="NH";



merge m:1 portlnd1 state1 using "${data_external}\communities_cleaned3.dta", keep(1 3) ;

drop if state1== "WA" ;
drop if state1== "FL" ;
drop if state1== "GA" ;



replace _merge = 3 if _merge == 1 & portlnd1 ~= "";
*assert _merge==3;
drop _merge;
rename date date;
collapse (sum) qtykept, by(permit tripid dbyear sppcode state1 portlnd1 port year myspp date month cousubns cousubfp geoid namelsad IFQ NGOM INC GC LADAS Nopermit_scal);
count;

gen state = substr(string(port, "%06.0f"), 1, 2) ;
gen county = substr(string(port, "%06.0f"), 5, 2) ;	
destring state county, replace;

/************************COMMENTED OUT 
merge m:1 myspp state year using "myspp_xfactor_state.dta", keep (1 3);

/*******replace the unmatched HAKNS, TILE SQNS, FLDR with x-factor==1 FOR NOW************************************************************************************/

replace state_xfactor=1 if  state_xfactor==. ;
replace qtykept=0 if qtykept==.;
gen adj_qtykept= state_xfactor*qtykept  ;
******END COMMENTED OUT********************/


/*there some landings that are coded as Northern Shrimp that are ocurring in places to the south. These are assuredly data errors */
replace myspp=738 if myspp==736 & inlist(state1,"VA", "NJ", "VA", "NC");



rename myspp nespp3 ;
*drop _merge ;



/*Changing VTR nespp3 numbers to be consisent with CFDBS numbers*/
replace nespp3 = 365 if nespp3 == 373;
compress;
/*Cancer crab seems to be Atlantic Rock crab, so replacing cancer crab price, which doesn't exist in CFDBS, for Atlantic Rock crab*/
replace nespp3 = 712 if nespp3 == 714;

/*A small number of people seem to be reporting calico scallop instead of sea scallop*/
replace sppcode = "SCAL" if sppcode == "SCC" & dbyear>=2005;
replace nespp3 = 800 if nespp3 == 797 & dbyear>=2005;
/*We still need to check if the SCC VTR reports from pre-2005 are "wrong"*/

/*********now merge in prices
This merges prices for everything. 
**************/

#delimit ;
local prefix "${data_intermediate}/$allprefix";
local monk_prefix "${data_intermediate}/$monk_prefix";


merge m:1 nespp3 port date using "`prefix'1.dta", keep (1 3) nogenerate ;

merge m:1 nespp3 state county date using "`prefix'2.dta", keep (1 3) nogenerate ;
replace price1=price2 if inlist(price1,0,.);

merge m:1 nespp3 state date using "`prefix'3.dta", keep (1 3) nogenerate ;
replace price1=price3  if inlist(price1,0,.);

merge m:1 nespp3 date using "`prefix'4.dta", keep (1 3) nogenerate ;
replace price1=price4  if inlist(price1,0,.);

merge m:1 nespp3 port year month using "`prefix'5.dta", keep (1 3) nogenerate ;
replace price1=price5  if inlist(price1,0,.);

merge m:1 nespp3 state county year month using "`prefix'6.dta", keep (1 3) nogenerate ;
replace price1=price6  if inlist(price1,0,.);

merge m:1 nespp3 state month year using "`prefix'7.dta", keep (1 3) nogenerate ;
replace price1=price7  if inlist(price1,0,.);

merge m:1 nespp3 month year using  "`prefix'8.dta", keep (1 3) nogenerate ;
replace price1=price8  if inlist(price1,0,.);

/*use the yearly average price for all species, but use $0.15 for herring instead of the yearly price*/
merge m:1 nespp3 year using  "`prefix'9.dta", keep (1 3) nogenerate ;
replace price1=price9  if inlist(price1,0,.) & nespp3~=168;
replace price1=0.15  if inlist(price1,0,.) & nespp3==168;

compress;



drop if nespp3==662 ; /**********spotted hake****************/
rename nespp3 myspp;

/* This is a good place to fix monkfish */

preserve;
tempfile monk_fix;

keep if inlist(myspp,012,011);
/*merge monk_prices here.*/
merge m:1 sppcode port date using "`monk_prefix'1.dta", keep (1 3) nogenerate ;


merge m:1 sppcode state county date using "`monk_prefix'2.dta", keep (1 3) nogenerate ;
replace price1=price2 if inlist(price1,0,.);

merge m:1 sppcode state date using "`monk_prefix'3.dta", keep (1 3) nogenerate ;
replace price1=price3  if inlist(price1,0,.);

merge m:1 sppcode date using "`monk_prefix'4.dta", keep (1 3) nogenerate ;
replace price1=price4  if inlist(price1,0,.);

merge m:1 sppcode port year month using "`monk_prefix'5.dta", keep (1 3) nogenerate ;
replace price1=price5 if inlist(price1,0,.);

merge m:1 sppcode state county year month using "`monk_prefix'6.dta", keep (1 3) nogenerate ;
replace price1=price6 if inlist(price1,0,.);

merge m:1 sppcode state month year using "`monk_prefix'7.dta", keep (1 3) nogenerate ;
replace price1=price7  if inlist(price1,0,.);

merge m:1 sppcode month year using  "`monk_prefix'8.dta", keep (1 3) nogenerate ;
replace price1=price8  if inlist(price1,0,.);
/*use the yearly average price for all species, but use $0.15 for herring instead of the yearly price*/
merge m:1 sppcode year using  "`monk_prefix'9.dta", keep (1 3) nogenerate ;
replace price1=price9  if inlist(price1,0,.);


save `monk_fix';

restore;
drop if inlist(myspp,012,011);
append using `monk_fix';












gen raw_revenue=qtykept*price1;
cap drop revenue1;



save "${data_main}\veslog_species_huge_${vintage_string}.dta", replace;

use "${data_main}\veslog_species_huge_${vintage_string}.dta", replace;


drop price* sppcode month ; 
*notes: the SCALLOP PERMIT dummy variables (LGCA-SG1B, IFQ, NGOM, INC, GC, NoPermit, LADAS) are only filled in for observations for which myspp==800.;
gen str4 source="VTR";

append using "${data_intermediate}\sfclam96_2013.dta";
foreach var of varlist IFQ NGOM INC GC LADAS{;
replace `var'=0 if `var'==.;
};
replace Nopermit_scal=1 if Nopermit_scal==.;
replace source="SFOQ" if source=="";

replace dbyear=year if dbyear==.;
notes tripid: There are no tripids for SF/OQ';
compress;

/*Deal with missing revenue due to missing prices */
/* pout and wolffishes  -- set this to $1/lb for the missing observations*/
replace raw_revenue=qtykept if (myspp==250 | myspp==512) & raw_revenue==.;

/* Fixing some data problem with SQUID NK and FLOUNDERS NK */

/* There are 9 obs of SQUID NK with no prices. These are just going to be replaced as SQUID-LOLIGO*/
drop if myspp==803 & tripid==2753216 & permit==210991; /* SCUP that got encoded as SQUID NS */
replace myspp=801 if myspp==803 & inlist(raw_revenue, 0,.);


/*fill in the yearly price of 801 for these observations  */
preserve;
keep if myspp==801 & year==2007;
collapse (sum) qtykept raw_revenue, by(year);
gen price803=raw_revenue/qty;
keep year price803;
tempfile p803;
sort year;
save `p803';

restore;
merge m:1 year using `p803';
drop _merge;
replace myspp=801 if myspp==803 & raw_revenue==.;
replace raw_revenue=qtykept*price803 if inlist(raw_revenue, 0,.) & myspp==801;
drop price803;

/* There are 33 obs of FLOUNDER NK (126) with no prices. These are just going to be replaced with the weighted average flounder price (120-125)*/
preserve;
keep if myspp>=120 & myspp<=125;
drop if inlist(raw_revenue,0,.);
collapse (sum) qtykept raw_revenue, by(year);
gen price126=raw_revenue/qtykept;
keep year price;
tempfile p126;
sort year;
save `p126';

restore;
merge m:1 year using `p126';

replace raw_revenue=qtykept*price126 if inlist(raw_revenue, 0,.) & myspp==126;
drop _merge;
drop price126;

/*Penaeid shrimp sells for $2.20/lb in 2006, and $1.90/lb in 2004, so using a price of $2 for 2005 (only 3 observations)*/
replace raw_revenue=qtykept*2 if inlist(raw_revenue, 0,.) & myspp==738 & year == 2005;
/*Unclassified eel sold for $0.64/lb in 2009 and 2007, and $0.71/lb in 2008, so using a price of $0.67 for 2010 - 2014*/
replace raw_revenue=qtykept*.67 if inlist(raw_revenue, 0,.) & myspp==117;
/*Ribbonfish sold for $0.31/lb in 2005, $0.49 in 2007, and $0.35/lb in 2008, so using a price of $0.45 for missing prices, given that that year has much higher number of observerations*/
replace raw_revenue=qtykept*.45 if inlist(raw_revenue, 0,.) & myspp==98;
/*Frigate mackerel sold for roughly $1/lb in 2012, 2013, and 2014, so using $1 as price for 2013 (~50 lbs reported landed in VTR) */
replace raw_revenue=qtykept if inlist(raw_revenue, 0,.) & myspp==132 & year == 2013;
/*Greenland halibut sold for $1.52/lb in 2011, $1.62 in 2010, so using a price of $1.5 for missing prices, given that that year has much higher number of observerations*/
replace raw_revenue=qtykept*1.5 if inlist(raw_revenue, 0,.) & myspp==158;

/*Lumpfish has very few sales recorded in CFDBS, all less than $2. Using price of $1, given variability and small amount of landings*/
replace raw_revenue=qtykept if inlist(raw_revenue, 0,.) & myspp==210;

/*Blue marlin have no sales recorded in CFDBS. Using price of $1.3, given landings prices in S&T commercial landings info*/
replace raw_revenue=qtykept*1.3 if inlist(raw_revenue, 0,.) & myspp==217;

/*Sculpins have very little sales recorded in CFDBS. Using price of $0.1, given what info exists*/
replace raw_revenue=qtykept*.1 if inlist(raw_revenue, 0,.) & myspp==326;

/*Rough scad have no sales recorded in CFDBS. Using price of $0.7, given landings prices in S&T commercial landings info for all scads*/
replace raw_revenue=qtykept*0.7 if inlist(raw_revenue, 0,.) & myspp==331;

/*Chained Dogfish have no sales recorded in CFDBS. Using price of $0.5, given landings prices that are in CFDBS*/
replace raw_revenue=qtykept*0.7 if inlist(raw_revenue, 0,.) & myspp==346;

/*Wreckfish have few sales recorded in CFDBS. Using price of $3, given landings prices that are in CFDBS*/
replace raw_revenue=qtykept*3 if inlist(raw_revenue, 0,.) & myspp==513;

/*Queen snow crab have no sales recorded in CFDBS. Using price of $2.5, given landings prices that are in S&T commercial landings database*/
replace raw_revenue=qtykept*2.5 if inlist(raw_revenue, 0,.) & myspp==718;

/*Using price of $1 for unclassified shrimp, given landings prices that are in CFDBS*/
replace raw_revenue=qtykept if inlist(raw_revenue, 0,.) & myspp==735;

/*Using price of $1.75 for mantis shrimp, given landings prices that are in CFDBS*/
replace raw_revenue=qtykept*1.75 if inlist(raw_revenue, 0,.) & myspp==737;

/*Using price of $1 for penaeid shrimp, given landings prices that are in CFDBS*/
replace raw_revenue=qtykept if inlist(raw_revenue, 0,.) & myspp==738;

/*Using price of $1.5 for lightning whelk, given landings prices that are in CFDBS*/
replace raw_revenue=qtykept*1.5 if inlist(raw_revenue, 0,.) & myspp==778;

/*Using price of $.7 for unclassified octopus, given landings prices that are in CFDBS*/
replace raw_revenue=qtykept*.7 if inlist(raw_revenue, 0,.) & myspp==786;

/*Using price of $.1 for starfish, given landings prices that are in CFDBS*/
replace raw_revenue=qtykept*.1 if inlist(raw_revenue, 0,.) & myspp==828;

/*Using price of $.2 for alewife, given landings prices that are in CFDBS*/
replace raw_revenue=qtykept*.2 if inlist(raw_revenue, 0,.) & myspp==1;


/* There are a number of unclassified seatrout with no prices. These are just going to be replaced with the weighted average seatrout price (344-345)*/
preserve;
keep if inlist(myspp, 344, 345);
drop if inlist(raw_revenue,0,.);

collapse (sum) qtykept raw_revenue, by(year);
gen price344=raw_revenue/qtykept;
keep year price;
tempfile p344;
sort year;
save `p344';
restore;



merge m:1 year using `p344';
replace raw_revenue=qtykept*price344 if inlist(raw_revenue, 0,.) & myspp==344;

drop _merge;
drop price344;

/* There are a number of unclassified dogfish with no prices. These are just going to be replaced with the weighted average seatrout price (351-352)*/
preserve;
keep if inlist(myspp, 351, 352);
drop if inlist(raw_revenue,0,.);
collapse (sum) qtykept raw_revenue, by(year);
gen price350=raw_revenue/qtykept;
keep year price;
tempfile p350;
sort year;
save `p350';
restore;
merge m:1 year using `p350';
replace raw_revenue=qtykept*price350 if inlist(raw_revenue, 0,.) & myspp==350;
drop _merge;
drop price350;

/* There are a number of shark with no prices. These are just going to be replaced with the weighted average shark price*/
preserve;
keep if inlist(myspp, 348, 349,353,354,355,357,358,359,360,475, 476,477,478,479,480
	481,482,483,484,485,486,487,488,489,490,491,492,493,494,495,496,497,498,499,500,501,502,503);
drop if inlist(raw_revenue,0,.);

collapse (sum) qtykept raw_revenue, by(year);
gen price349=raw_revenue/qtykept;
keep year price;
tempfile p349;
sort year;
save `p349';
restore;
merge m:1 year using `p349';
replace raw_revenue=qtykept*price349 if inlist(raw_revenue, 0,.) & inlist(myspp,348,349,354,357,480,483,486,493,495,496,490);
drop _merge;
drop price349;
/* There are unclassified tilefish landings with no prices. These are just going to be replaced with the weighted average tilefish price*/
preserve;
keep if inlist(myspp, 444,445,446);
drop if inlist(raw_revenue,0,.);
collapse (sum) qtykept raw_revenue, by(year);
gen price447=raw_revenue/qtykept;
keep year price;
tempfile p447;
sort year;
save `p447';
restore;
merge m:1 year using `p447';
replace raw_revenue=qtykept*price447 if inlist(raw_revenue, 0,.) & inlist(myspp,447);
drop _merge;
drop price447;
/* There are unclassified tuna landings with no prices. These are just going to be replaced with the weighted average tuna price, excluding bluefin and yellowfin*/
preserve;
keep if inlist(myspp, 464,466,468,469,470);
drop if inlist(raw_revenue,0,.);

collapse (sum) qtykept raw_revenue, by(year);
gen price465=raw_revenue/qtykept;
keep year price;
tempfile p465;
sort year;
save `p465';
restore;
merge m:1 year using `p465';
replace raw_revenue=qtykept*price465 if inlist(raw_revenue, 0,.) & inlist(myspp,465);
drop _merge;
drop price465;
/* There are barndoor and thorny landings with no prices. These are just going to be replaced with the weighted average skate price*/

preserve;
keep if inlist(myspp, 364,365,366,367,368,369,370,371,372,373);
drop if inlist(raw_revenue,0,.);

collapse (sum) qtykept raw_revenue, by(year);
gen price370=raw_revenue/qtykept;
keep year price;
tempfile p370;
sort year;
save `p370';
restore;
merge m:1 year using `p370';
replace raw_revenue=qtykept*price370 if inlist(raw_revenue, 0,.) & inlist(myspp,370,368);
drop _merge;
drop price370;

/* There are unclassified clam landings with no prices. These are just going to be replaced with the weighted average clam price, excluding ocean quahog and surfclam*/
preserve;
keep if inlist(myspp, 763,765,748,743);
drop if inlist(raw_revenue,0,.);

collapse (sum) qtykept raw_revenue, by(year);
gen price764=raw_revenue/qtykept;
keep year price;
tempfile p764;
sort year;
save `p764';
restore;
merge m:1 year using `p764';
replace raw_revenue=qtykept*price764 if inlist(raw_revenue, 0,.) & inlist(myspp,764,765);
drop _merge;
drop price764;


preserve;
keep if inlist(myspp, 754, 769);
drop if inlist(raw_revenue,0,.);

collapse (sum) qtykept raw_revenue, by(year);
gen price769=raw_revenue/qtykept;
keep year price;
tempfile p769;
sort year;
save `p769';
restore;
merge m:1 year using `p769';
replace raw_revenue=qtykept*price769 if inlist(raw_revenue, 0,.) & inlist(myspp,754, 769);
drop _merge;
drop price769;







/* There are Whelks with no prices. These are just going to be replaced with the weighted whelk */
preserve;
keep if inlist(myspp, 774, 776,777,778,779);
drop if inlist(raw_revenue,0,.);

collapse (sum) qtykept raw_revenue, by(year);
gen price777=raw_revenue/qtykept;
keep year price;
tempfile p777;
sort year;
save `p777';
restore;
merge m:1 year using `p777';
replace raw_revenue=qtykept*price777 if inlist(raw_revenue, 0,.) & inlist(myspp,774, 776,777,778,779);
drop _merge;
drop price777;







compress;

notes drop _all;

notes: The variable myspp is the NESPP3 code with TWO exceptions.;
notes: For SKATES, we have classified everything into 1 skate category.  Although i Don't think Skates were included in this dataset;
notes: For HAKES, we reclassify WHAK as SHAK if it was caught with small mesh (misreporting).  We bundle the Black/Offshore and Silver Hake together.;
notes: SC and OQ are taken from the SFCLAM schema.;
notes: the SCALLOP PERMIT dummy variables (LGCA-SG1B, IFQ, NGOM, INC, GC, NoPermit, LADAS) are only filled in for observations for which myspp==800.;
notes: Geoid and Cousubns are two different codes for the spatial unit.  Every Geoid corresponds to a distinct cousubns. Every cousubns corresponds to a distinct geoid.;
notes: dealnums 99998, 1,2, 5, 7, 8 were excluded from this dataset.;
notes tripid:  There are no tripids for SF/OQ;
notes cousubns: cousubns is an ANSI code.  See Geographic Names Information System (GNIS) code.;
notes geoid: Geoid is the unique spatial unit and is formed by concatenating statefp, countyfp, and cousubfp from Census County Subdivision data.;
notes namelsad: namelsad contains the "name" and the "legal/statistical area description for the county subdivision";
notes cousubfp: This is the 5 digit county subdivision FIPS code. This is useless without statefp and countyfp.;
notes state_xfactor: This is the expansion factor that can be used to adjust qtykept from VTR so that it matches Dealer;

notes qtykept: LBS from VTR, with corrections for scallops;
*notes adj_qtykept: LBS from VTR multiplied by the state_xfactor;

notes raw_revenue: qtykept*price;

/*rename hampton NY to EASTHAMPTON and code it to the proper GEOID */
replace port=350635 if geoid==3611531885;
replace portlnd1="EAST HAMPTON" if geoid==3611531885;
replace geoid=3610322194 if geoid==3611531885;
replace geoid=2302999999  if port==220919 & geoid==.;
replace namelsad="East Hampton town" if geoid==3610322194;


/*rename permit 310153 in dbyear 2016 other ny --> montauk, ny */
replace portlnd1="MONTAUK" if permit==310153 & portlnd1=="OTHER NY" & dbyear==2016;
replace port=350635 if permit==310153 & portlnd1=="MONTAUK" & dbyear==2016;
replace geoid=3610322194 if permit==310153 & portlnd1=="MONTAUK" & dbyear==2016;
replace namelsad="East Hampton town" if geoid==3610322194;




/*clean up some of the surfclam mismatches -- put them into the county level */
replace geoid=2500199999  if port==240901 & geoid==. ;
replace geoid=3605999999  if port==350915 & geoid==.;
replace geoid= 3610399999 if strmatch(portlnd1, "OTHER SUFFOLK") & geoid==.;
replace geoid=3402999999 if strmatch(portlnd1, "OTHER OCEAN") & geoid==.;
replace geoid=3401199999 if strmatch(portlnd1, "OTHER CUMBERLAND") & geoid==.;
replace geoid=4400599999 if strmatch(portlnd1, "OTHER NEWPORT") & geoid==.;
replace portlnd1="OTHER" + " " +state1 if strmatch(portlnd1, "") & strmatch(state1,"")==0;
replace namelsad="East Hampton town" if geoid==3610322194;
drop if qtykept==0;


/* fix barnegat, barnegat light, and long beach */

replace geoid=3402941250 if inlist(geoid, 3402903130, 3402903050,3402941250);
replace namelsad="Long Beach township" if geoid==3402941250;



save "${data_main}\veslog_species_huge_${vintage_string}.dta", replace;

keep if inlist(myspp,51,81,120,121,122,123,124,125,126,147,152,153,155,159,212,240,250,269,446,447,509,512,754,769,800,801,802,803);
save "${data_main}\veslog_species_${vintage_string}.dta", replace;



