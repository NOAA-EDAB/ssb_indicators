
#delimit;
clear;
/*******************************************************************************************************************************************/


/****************steps in this data creation
Create a cleaned up scallop dataset, with permit/port/qytkept from veslogT and veslogS and permit information from "permit.vps_fishery_ner"
This file gets saved as 
"scal_tripid_permits_ports.dta" 

In order to run this code, you need a connection to ORACLE and the stata dta file "null_ports_trim.dta" that is a key file to clean up some of the messy port data.
*/


/*************SCALLOP DATASET*********************/
/* Extract scallop landings by permit, port, date, tripid, and SPPCODE 
  a.  1994-2013 
  b.  a commercial or RSA trip 
  c.  Fish were sold
  
Stick it all into a large dataset 

*/



/*************************************************************/



/* make a table of nespp3 and 4 */
tempfile nespp34 ;
odbc load, exec("select distinct nespp3, nespp4, sppcode from vlsppsyn;") $oracle_cxn;   
destring, replace ;
renvarlab, lower ;
duplicates drop (sppcode), force  ;
save `nespp34', replace ;
clear;



quietly forvalues yr=$firstyr/$lastyr{ ;
	tempfile new;
	local NEWfiles `"`NEWfiles'"`new'" "'  ;
	clear;
	odbc load, exec("select sum(s.qtykept) as qtykept, s.sppcode, s.dealnum, t.state1, t.portlnd1, t. permit, t.port, t.tripid, trunc(nvl(s.datesold, t.datelnd1)) as datesell from veslog`yr's s, veslog`yr't t 
		where t.tripid= s.tripid and (t.tripcatg=1 or t.tripcatg=4)
			and s.dealnum not in ('99998', '1', '2', '5', '7', '8')  and s.qtykept>=1
			and s.sppcode in ('SCAL', 'SCALS', 'SCALB', 'SCALG')    
			group by s.sppcode, s.dealnum, t.state1, t.portlnd1, t. permit, t.port, t.tripid, trunc(nvl(s.datesold, t.datelnd1));")  $oracle_cxn;
	gen dbyear=`yr';
                   
	quietly save `new';
};
dsconcat `NEWfiles';
	renvarlab, lower;
	destring, replace;
	compress;
merge m:1 sppcode using `nespp34', keep(1 3) ; /********get nespp3/4*********/   
assert _merge==3;
drop _merge;

gen date = dofc(datesell) ;
format date %td ;
format datesell %tc ;
label var dbyear "YEAR ACCORDING TO DB YEAR";
gen month= month(date)  ;

/* There are no scallop reports that are from before 1996 
list permit tripid datesell year if year(dofc(datesell))<=1995;
*/
save "veslog_scallops.dta", replace;


/* Extract the "plan" and "cat" corresponding to those tripids (based on datelnd1 and permit) 
  a.  1994-2013 
  b. Just the "scallop" plans
Stick it all into a large dataset */


quietly forvalues yr=$firstyr/$lastyr{ ;
    tempfile new1;
    local scalVESfiles `"`scalVESfiles'"`new1'" "'  ;
    clear;
    odbc load, exec("select t.permit, t.tripid, p.plan, p.cat from veslog`yr't t, vps_fishery_ner p
        where t.permit=p.vp_num and trunc(t.datelnd1) between trunc(p.start_date) and trunc(p.end_date) 
		and p.plan in ('SC','SCG','SG','LGC');") $oracle_cxn;  
    gen dbyear=`yr';
		quietly count;
	if r(N)==0{;
	set obs 1;
	};

    quietly save `new1';
};
dsconcat `scalVESfiles';



    renvarlab, lower;
    destring, replace;
    compress;
    
    
    /* duplicates drop is needed here.  Because of the way VPS_FISHERY_NER is constructed, if a vessel "lands" fish on the date that the permit changes is effect, it will match to TWO
    records.  For an example of this, see tripid=981463, vp_num=114454, and ap_year=1999. */
	duplicates drop;
 label var dbyear "YEAR ACCORDING TO DB YEAR";

   
 save "scal_tripid_permits.dta", replace;  

    gen mark=1;
	gen plan_cat= plan+cat;
    drop plan;
	drop cat;
	drop if plan_cat==""; 
	reshape wide mark, i(permit tripid dbyear) j(plan_cat) string;
    compress;
    renvars mark*, predrop(4);

/*************************************************************/
/*************************************************************/

merge 1:m tripid permit dbyear using "veslog_scallops.dta", keep(2 3);
save "scal_tripid_permits.dta", replace;
foreach p of varlist LGCA-SG1B{ ;
	replace `p'=0 if `p'==.;
};
egen pp= rowtotal(LGCA-SG1B);
tab pp;
gsort -pp;

drop if qtykept==.;
gsort -pp LGCA qtykept ;



gen state = substr(string(port, "%06.0f"), 1, 2)   ;
destring, replace  ;
save "scal_tripid_permits.dta", replace  ;

/*********************************************/
/******************FY dates*******************/
/*********************************************/
gen FY=1994  ;
replace FY=1995 if date>= d(01mar1995) & date< d(01mar1996) ;
replace FY=1996 if date>= d(01mar1996) & date< d(01mar1997)  ;
replace FY=1997 if date>= d(01mar1997) & date< d(01mar1998) ;
replace FY=1998 if date>= d(01mar1998) & date< d(01mar1999) ;
replace FY=1999 if date>= d(01mar1999) & date< d(01mar2000) ;
replace FY=2000 if date>= d(01mar2000) & date< d(01mar2001) ;
replace FY=2001 if date>= d(01mar2001) & date< d(01mar2002) ;
replace FY=2002 if date>= d(01mar2002)  & date< d(01mar2003);
replace FY=2003 if date>= d(01mar2003) & date< d(01mar2004) ;
replace FY=2004 if date>= d(01mar2004) & date< d(01mar2005) ;
replace FY=2005 if date>= d(01mar2005) & date< d(01mar2006) ;
replace FY=2006 if date>= d(01mar2006) & date< d(01mar2007) ;
replace FY=2007 if date>= d(01mar2007) & date< d(01mar2008) ;
replace FY=2008 if date>= d(01mar2008) & date< d(01mar2009) ;
replace FY=2009 if date>= d(01mar2009) & date< d(01mar2010) ;
replace FY=2010 if date>= d(01mar2010) & date< d(01mar2011) ;
replace FY=2011 if date>= d(01mar2011) & date< d(01mar2012) ;
replace FY=2012 if date>= d(01mar2012) & date< d(01mar2013);
replace FY=2013 if date>= d(01mar2013) & date< d(01mar2014);
replace FY=2014 if date>= d(01mar2014) & date< d(01mar2015);

 /***********A FEW SCALG CORRECTIONS*******************************/

replace sppcode="SCAL" if permit==240954 & tripid==3296229 ;   
replace sppcode="SCALB" if permit==221273 & tripid==2187129 ;
replace sppcode="SCAL" if permit==121685 & tripid==2045517 ;

replace sppcode="SCAL" if permit==221555 & tripid==221555 ;   /************this is the only vessel in our states that had a gallon of scallops********/
replace qtykept=qtykept*8.3 if permit==221555 & tripid==221555 ;

/***************end SCALG corrections**************/


/*************Deal with SCALS in the GC********** First I sorted by all the GC categories and qty kept (gsort -sppcode - LGCA - LGCB - LGCC - SCG1 - SG1A - SG1B - qtykept).  
I looked at the first few observations with the highest qty and spot checked them to make sure they were correctly entered 
from the trip report scan.  Next-- some people report the actual shell weight conversion and some people don't.  
To deal with this, any value above the cutoff values for GC posession limits (both pre and post aug 1, 2011) we divide by 8.33. */

replace qtykept=19 if (permit==150542 & tripid==3289572 & qtykept==19207);/*********Only 1 sketchy SCALS report************/

/* assume that those who reported over the quota reported in shell weight.  For the few DAS vessels that landed shelled, 
I guess we have to trust they reported correctly--we cant adjust them b/c they don't necessarily have a possession limit
We added a fudge factor over the possession limit to account for possiblity of having an observer on board.********/

/*********Adjusted the 'dates' below b/c they were not coded correctly*************/

replace qtykept=(qtykept/8.33) if (sppcode=="SCALS" & pp==1 & LGCA==1 & qtykept>900 & (date> d(01aug2011))) ;
replace qtykept=(qtykept/8.33) if (sppcode=="SCALS" & pp==1 & LGCA==1 & qtykept>700 & (date< d(01aug2011))) ;
replace qtykept=(qtykept/8.33) if (sppcode=="SCALS" & pp==1 & LGCC==1 & qtykept>100);

replace qtykept=(qtykept/8.33) if (sppcode=="SCALS" & pp==1 & SCG1==1 & qtykept>700);	
replace qtykept=(qtykept/8.33) if (sppcode=="SCALS" & pp==1 & SG1A==1 & qtykept>700);
replace qtykept=(qtykept/8.33) if (sppcode=="SCALS" & pp==1 & SG1B==1 & qtykept>700);


/********convert the rest of the SCALS by the conversion factor*************
replace qtykept=qtykept/8.33 if  pp==1 & sppcode=="SCALS" & ( SC2==1);*/

replace qtykept=qtykept/8.33 if  pp==1 & sppcode=="SCALS" & ( SC2==1 | SC3==1 | SC4==1 | SC5==1 | SC6==1 | SC7==1 | SC8==1 | SC9==1);

				/*******There are 5 SCALS dual-permit holders.  We apply same rule to decide whether to divide by the shell conversion or not
replace qtykept=qtykept/8.33 if  pp==2 & sppcode=="SCALS" & qtykept>400 & (SC1==1):
***********/

replace qtykept=qtykept/8.33 if  pp==2 & sppcode=="SCALS" & qtykept>400 & (SC2==1 | SC3==1 | SC4==1 | SC5==1 | SC6==1 | SC7==1 | SC8==1 | SC9==1);

/*************SCALLOP BUSHELS**********************/

/***********I went through the quantities of bushels >60 and spot checked for errors.  I corrected the following obs***/

replace qtykept=50 if permit==231221 & tripid==1230404 & qtykept==9520;
replace qtykept=50 if permit==221273 & tripid==1236361 & qtykept==4000;
replace qtykept=50 if permit==221273 & tripid==1236362 & qtykept==4000;
replace qtykept=50 if permit==250542 & tripid==1236151 & qtykept==4000;
replace qtykept=50 if permit==221273 & tripid==1236350 & qtykept==4000;
replace qtykept=49 if permit==250542 & tripid==1236165 & qtykept==3920;
replace qtykept=45 if permit==250542 & tripid==1236161 & qtykept==3840;
replace qtykept=50 if permit==410540 & tripid==1709683 & qtykept==504;
replace qtykept=50 if permit==251138 & tripid==1423433 & qtykept==500;
replace qtykept=50 if permit==231221 & tripid==1418570 & qtykept==500;
replace sppcode="SCAL" if permit==250270 & tripid==1060572;
replace qtykept=50 if permit==241038 & tripid==1354404 & qtykept==150;
replace qtykept=13 if permit==223518 & tripid==1186787 & qtykept==131;
replace qtykept=12 if permit==223518 & tripid==1186795 & qtykept==121;
replace qtykept=18.5 if permit==231221 & tripid==1490127 & qtykept==119;
replace qtykept=38 if permit==250175 & tripid==2178347 & qtykept==111;
replace qtykept=46 if permit==230748 & tripid==1744473 & qtykept==92;
replace qtykept=41.6 if permit==230748  & tripid==1744467 & qtykept==88;
replace qtykept=32 if permit==250542 & tripid==1313898 & qtykept==82;
replace qtykept=50 if permit==310951 & tripid==2303386 & qtykept==73;
replace qtykept=26 if permit==241038 & tripid==1278291 & qtykept==66;
replace qtykept=40 if permit==221273  & tripid==1236358 & qtykept==3600;
replace qtykept=42 if permit==250542 & tripid==1236154 & qtykept==3360;
replace qtykept=40 if permit==221273 & tripid==1236356 & qtykept==3200;

/*******This guy....*************/
replace qtykept=50 if permit==231221 & tripid==1230402 & qtykept==2800;
replace qtykept=50 if permit==231221 & tripid==1230407 & qtykept==2400;
replace qtykept=50 if permit==231221 & tripid==1230407 & qtykept==1600;

replace qtykept=135 if permit==242848 & tripid==4145536 & qtykept==788;


/***this was the Squid-Loligo guy I couldn't find before***/
drop if permit==410349 & tripid==3210591 & qtykept==11000 ;
/***this guy is LADAS not GC***/
replace LGCC=0 if permit==330823 & tripid==3193117 & qtykept==18000;
replace SC2=1 if permit==330823 & tripid==3193117 & qtykept==18000;





 /********those are all the "fixable" SCALB's.  Now we multiply each SCALB by 50 for shell weight per bushel, 
 and then divide by 8.33 to get meat weight*************************/
 
 replace qtykept=(50*qtykept)/8.33 if sppcode=="SCALB" ;

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


replace qtykept=33654 if permit==330340 & tripid==1338779 ; /********this was the observation I sent you.  Looking at the vessel's landing trends, I believe the mystery # to be a 3******/
replace qtykept=17900 if permit==330908 & tripid==4279019;
replace qtykept=48000 if permit==330292 & tripid==3197199;
replace qtykept=16434.5 if permit==330570 & tripid==1280688;
replace qtykept=18120 if permit==410193 & tripid==1658001;
replace qtykept=8177.5 if permit==330664 & tripid==1284810;
replace qtykept=41000 if permit==410019 & tripid==3371216;
replace qtykept=15300 if permit==330903 & tripid==3407371;
replace qtykept=8000 if permit==310928 & tripid==3147948;
replace qtykept=23500 if permit==330353 & tripid==1609901;
replace qtykept=20331 if permit==410167 & tripid==1637399;
replace qtykept=6950 if permit==330832 & tripid==3710712;
replace qtykept=16962 if permit==420045 & tripid==1565296;
replace qtykept=27847 if permit==410341 & tripid==1298016;
replace qtykept=6353.5 if permit==320932 & tripid==1386972;
replace qtykept=31500 if permit==410444 & tripid==2231118;
replace qtykept=6601 if permit==330331 & tripid==1425632;
replace qtykept=24216 if permit==410175 & tripid==1839970;

notes: the qty difference from the errors was 1078083.5 lbs. ;

/**********Classify the scallop permit holder (who have 2 permits simultaneously) into correct categories, based on the following decision rules*************/
/* I BROKE THIS INTO MULTIPLE LINES  just to make the logic easier to follow

A trip is IFQ
a. It has an IFQ permit and no other Scallop permit
b. It had an IFQ permit, another permit, and sold between 400 and 900 lbs of scallop meats after August 1, 2011
b. It had an IFQ permit, another permit, and sold between 200 and 700 lbs of scallop meats before August 1, 2011
*/

gen IFQ=0;
replace IFQ=1 if pp==1 & LGCA==1;
replace IFQ=1 if pp==2 & LGCA==1 & qtykept<=900  & date> d(01aug2011) ;
replace IFQ=1 if pp==2 & LGCA==1 & qtykept<=700 & date< d(01aug2011) & date> d(02nov2004) ;

/*************The industry funded observer program started with amm 16 on Nov 16, 2004.  It was then 'reactivated' in 2008, but as of now, 
				I do not know when it was deactivated, I'll have to check this out
ML: Okay, good catch. we'll leave this code here but commented out so we can get it back in later.

****************************/

/* I BROKE THIS INTO MULTIPLE LINES  just to make the logic easier to follow
A trip is NGOM if:
a. It has an NGOM permit and no other Scallop permit
b. It had an NGOM permit, a DAS permit, and sold between <300 lbs of scallop
*/
gen NGOM=0;
replace NGOM=1 if pp==1 & LGCB==1;

replace NGOM=1 if pp==2 & LGCB==1 & qtykept<=300;

gen INC=0;
replace INC=1 if pp==1 & LGCC==1;
replace INC=1 if pp==2 & LGCC==1 & qtykept<=80;  /********possession limit for INC is 40 lbs********/			

/********Effective August 1, 2011, (http://www.nero.noaa.gov/nero/nr/nrdoc/11/11ScallA15-FW22%20PHL.pdfLAGCIFQ)
							vessels could land up to 600lbs.  We add +300 to the GC/IFQ "cutoff" to account for observer coverage/(research set-aside?).
							For NGOM, the possession limit is 200 lbs, we add 100 for the cutoff point
							For INC we add 60 lbs to the cutoff point*********************************************/

/***********group GC pre IFQ era into one category***************************/

gen GC=1 if (pp==1 & SCG1==1) | (pp==1 & SG1A==1) | (pp==1 & SG1B==1)	;					

/*make sure no GC gets double-clasified**********/

foreach p of varlist IFQ-GC{ ;
	replace `p'=0 if `p'==.;
};
egen ppp= rowtotal(IFQ-GC);
gsort -ppp;
/*********Make the "No-permit" category.  Those not classified into GC (or IFQ, NGOM, INC), will be classified into LA-DAS vessels***********/
gen Nopermit=1 if _merge==2	;					
replace Nopermit=0 if Nopermit==.;
gen LADAS=1 if ppp==0 & Nopermit==0;
replace LADAS=0 if LADAS==.;

/*********Now make sure there are no double classified**********/
drop ppp;
egen pppp= rowtotal (IFQ-LADAS);
assert pppp==1;
drop pppp;
rename _merge permitmerge ;
save "scal_tripid_permits.dta", replace	;

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

/* rename the port code so i can control how it is updated 
rename port port_fixed;	
*/
/*load in portnm, stateabb from the PORT table, join it to the null_ports_trim table */
 
preserve;
tempfile portfixer;
clear;
odbc load, exec("select port, portnm, stateabb from port;") $oracle_cxn;  
destring, replace;
renvarlab, lower;

merge 1:m port using "null_ports_trim.dta", keep(3) nogenerate;
sort portsyn statesyn ;
order portsyn statesyn port;
rename port port_fixed;
save `portfixer';

restore;

/* merge the data to the portfixer table, update the portlnd1, state1, port_fixed fields if port_fixed was missing and there was a match in the merge */
merge m:1 portsyn statesyn using `portfixer', keep(1 3);
replace portlnd1=portnm if port==. & _merge==3;
replace state1=stateabb if port==. & _merge==3;
replace port=port_fixed if port==. & _merge==3;
replace state1="VA" if permit==330340 & tripid==247199 & state1=="";
replace portlnd1="SEAFORD" if permit==330340 & tripid==247199 & portlnd1=="";
replace port=490869 if permit==330340 & tripid==247199 & port==.;
drop port_fixed stateabb portnm portsyn statesyn;


/*Drop states we don't care about, and remove any fishing recodrs before FY 1996*/

drop if state1== "WA" ;
drop if state1== "FL" ;
drop if state1== "GA" ;
drop if state1== "NC";

/*********Because we have converted all scallops to meat weight, we can collapse by everything besides the sppcode to get rid of duplicate (tripid,permit, etc) observations************/

collapse (sum)  qtykept, by (FY permit dealnum tripid LGCA-LGCC SC* SG* portlnd1 state1 port date month dbyear IFQ NGOM INC GC Nopermit LADAS) ;
gen year=year(date);
save "scal_tripid_permits_ports.dta", replace  ;




merge m:1 permit tripid dbyear using "final_all_port_corrections.dta", keep(1 3);
replace portlnd1=corrected_port if _merge==3;
replace state1=corrected_state if _merge==3;
drop corrected_port corrected_state _merge;

assert strmatch(portlnd1,"*OTHER*")==0;
assert port~=.;

/*******WE HAVE TO CORRECT THE SPELLINNG MISTAKES IN THIS DATASET SO THEY MERGE CORRECTLY TO JULIES TABLE.  THESE are obvious spelling mistakes**************/
quietly do "spelling_fixer1.do";


/*******These require a bit of judgement, so I've separated them from the other "spelling_fixer1.do" file**************/
drop if portlnd1=="BROAD CREEK" & state1=="MD"; /* This is way inland.  We're not going to keep these two observations */
replace portlnd1="POINT PLEASANT" if (portlnd1=="JONES BEACH" & permit==330683 & tripid==1943643) ;
replace state1="NJ" if permit==330683 & tripid==1943643 ;
replace portlnd1="SANDWICH" if portlnd1=="CAPE COD BAY" & state1=="MA" & permit==241110 ;
replace portlnd1="HARWICH PORT" if portlnd1=="CAPE COD" & state1=="MA" & permit==148245 ;
replace portlnd1="SAQUATUCKET HARBOR" if portlnd1=="CAPE COD" & state1=="MA" & permit==146862 ;
replace portlnd1="ATLANTIC CITY" if portlnd1=="DOCKSIDE" ;

/* There is 1 entry that has a completely missing port code and portlnd. Fix this by hand */


save "scal_tripid_permits_ports.dta", replace  ;

/*******************************************************Now merge these to communities_clean2----NOTES: must drop duplicates in communitites_2**************/

merge m:1 portlnd1 state1 using "communities_cleaned2.dta",  keep(1 3);
drop if state1== "WA" ;
drop if state1== "FL" ;
drop if state1== "GA" ;
drop if state1== "NC";
assert _merge==3;
drop _merge;



/*********Extract state, county, and port from the PORT code
The port codes will be wrong for all of the PORTLND1, STATE1s that we have fixed.  
We use the port codes to merge to cfders. But there isn't much we can do about this, because we cannot correct the wrong port codes in dealer.
************/

gen state = substr(string(port, "%06.0f"), 1, 2) 	; 
gen county = substr(string(port, "%06.0f"), 5, 2) 	;
destring, replace ; 


format date %td  ;
gen myspp=800  ;
drop placenm placest areakey hcounty lat lon statefp countyfp;

save "scal_tripid_permits_ports.dta", replace  ;
