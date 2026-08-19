#delimit;
/* data for surfclam is in a bunch of places 

1995-1999 the data is in SFYYVR (and PR)
2000-2002 is stored in SFYYYYVR (and PR)
2003 to present is stored in SFOQPR and SFOQVR
*/



/*sfYYvr has data for 1994-1999 */
clear;
tempfile portregular;
odbc load, exec("select port, port_name as portnm, state_abb as stateabb from CAMS_GARFO.CFG_PORT;") $oracle_cxn;  
renvarlab, lower; 
destring, replace;
save `portregular';

clear;
odbc load,  exec("select * from NEFSC_GARFO.sfclam_sfoqvr") $oracle_cxn;
renvarlab, lower;
gen year=year(dofc((cd)));
gen month=month(dofc((cd)));
gen day=day(dofc((cd)));
rename bush quantity;
rename pr price;
gen value=pr*quantity;
rename num permit;
label var quantity "quantity in bushels";
gen str3 nespp3="754" if substr(anum,1,1)=="Q";

replace nespp3="769" if substr(anum,1,1)=="C";
gen str6 port=st+pc+cy;
drop if inlist(vr_rec_id,81908, 84676);
keep dnum permit quantity price year month day nespp3 value port carea;

replace port= "330221" if port=="altcit";
replace port= "330201" if port=="atcity";
replace port= "330201" if port=="atlant";
replace port= "330201" if port=="atlcit";
replace port="310993" if port=="" & year==2011 &  dnum==1379 & permit==320409;
destring, replace;

gen quantity_meat=quantity*10;
replace quantity_meat=quantity*17 if nespp3==769;

replace quantity_meat=quantity*11 if nespp3==754 & substr(string(port),1,2)=="22";


notes: quantity_meat is "meat weights, in pounts".  Surfclam has 17 lbs of meats per bushel, quahog has 10 lbs of meats per bushel. Maine quahog has 11 lbs of meats per bushel;
notes: quantity is in bushels;
notes: price is dollars per bushel;

gen date=mdy(month, day, year);
format date %td;
compress;
destring, replace ;

rename nespp3 myspp ;
rename quantity_meat qtykept ;
rename value revenue1;
rename dnum dealnum;

replace port=330201 if permit==410141 & dealnum==2996 & port>=990000;
collapse (sum) qtykept revenue1, by(permit dealnum myspp port year date carea);
merge m:1 port using `portregular', keep(1 3);
assert _merge==3;
drop _merge;
rename portnm portlnd1;
rename stateabb state1;
/* a little bit of cleaning */

/* Lou's corrections */
#delimit cr
quietly do "${extraction_code}\spelling_fixer1.do"

gen new_portlnd1=""


replace new_portlnd1="OCEANSIDE" if strmatch(portlnd1,"OTHER NASSAU") & date>d(01jan2011) & state1=="NY"
replace new_portlnd1="OCEANSIDE" if permit==310506 & strmatch(portlnd1,"OTHER NASSAU") & new_portlnd1==""
replace new_portlnd1="OCEANSIDE" if permit==330124 & strmatch(portlnd1,"OTHER NASSAU") & new_portlnd1==""
replace new_portlnd1="OCEANSIDE" if permit==330132 & strmatch(portlnd1,"OTHER NASSAU") & new_portlnd1==""
replace new_portlnd1="OCEANSIDE" if permit==330183 & strmatch(portlnd1,"OTHER NASSAU") & new_portlnd1==""
replace new_portlnd1="OCEANSIDE" if permit==330233 & strmatch(portlnd1,"OTHER NASSAU") & new_portlnd1==""
replace new_portlnd1="OCEANSIDE" if permit==330451 & strmatch(portlnd1,"OTHER NASSAU") & new_portlnd1==""
replace new_portlnd1="OCEANSIDE" if permit==330632 & strmatch(portlnd1,"OTHER NASSAU") & new_portlnd1==""
replace new_portlnd1="OCEANSIDE" if permit==330801 & strmatch(portlnd1,"OTHER NASSAU") & new_portlnd1==""
replace new_portlnd1="OCEANSIDE" if permit==410324 & strmatch(portlnd1,"OTHER NASSAU") & new_portlnd1==""


replace new_portlnd1="HYANNIS" if permit==240740 & strmatch(portlnd1,"OTHER*") & new_portlnd1==""
replace new_portlnd1="HYANNIS" if permit==241211 & strmatch(portlnd1,"OTHER*") & new_portlnd1==""
replace new_portlnd1="HYANNIS" if permit==151370 & strmatch(portlnd1,"OTHER*") & new_portlnd1==""
replace new_portlnd1="HYANNIS" if strmatch(portlnd1,"OTHER BARNSTABLE") & date>d(01jan2011) & state1=="MA"
replace new_portlnd1="HYANNIS" if permit==310993 & strmatch(portlnd1,"OTHER*") & new_portlnd1==""
replace new_portlnd1="HYANNIS" if permit==311006 & strmatch(portlnd1,"OTHER*") & new_portlnd1==""
replace new_portlnd1="HYANNIS" if permit==320297 & strmatch(portlnd1,"OTHER*") & new_portlnd1==""
replace new_portlnd1="HYANNIS" if permit==320409 & strmatch(portlnd1,"OTHER*") & new_portlnd1==""
replace new_portlnd1="HYANNIS" if permit==320409 & portlnd1=="BARNSTABLE" & new_portlnd1==""
replace new_portlnd1="HYANNIS" if permit==320621 & strmatch(portlnd1,"OTHER*") & new_portlnd1==""
replace new_portlnd1="HYANNIS" if permit==320695 & strmatch(portlnd1,"OTHER*") & new_portlnd1==""
replace new_portlnd1="HYANNIS" if permit==320895 & strmatch(portlnd1,"OTHER*") & new_portlnd1==""
replace new_portlnd1="HYANNIS" if permit==321097 & strmatch(portlnd1,"OTHER*") & new_portlnd1==""
replace new_portlnd1="HYANNIS" if permit==321114 & strmatch(portlnd1,"OTHER*") & new_portlnd1==""




replace new_portlnd1="EASTERN HARBOR" if permit==119870 & strmatch(portlnd1,"OTHER*")

replace new_portlnd1="JONESPORT" if permit==120079 & strmatch(portlnd1,"OTHER*") 
replace new_portlnd1="JONESPORT" if permit==123550 & strmatch(portlnd1,"OTHER*") 
replace new_portlnd1="JONESPORT" if permit==123859 & strmatch(portlnd1,"OTHER*") 
replace new_portlnd1="JONESPORT" if permit==130510 & strmatch(portlnd1,"OTHER*") & inlist(dealnum, 403)
replace new_portlnd1="JONESPORT" if permit==131009 & strmatch(portlnd1,"OTHER*") & dealnum==0
replace new_portlnd1="JONESPORT" if permit==131486 & strmatch(portlnd1,"OTHER*") & inlist(dealnum, 345, 0, 403)
replace new_portlnd1="JONESPORT" if permit==135903 & strmatch(portlnd1,"OTHER*") & inlist(dealnum, 2363)
replace new_portlnd1="JONESPORT" if permit==138581 & strmatch(portlnd1,"OTHER*") 
replace new_portlnd1="JONESPORT" if permit==146640 & strmatch(portlnd1,"OTHER*") 
replace new_portlnd1="JONESPORT" if permit==220615 & strmatch(portlnd1,"OTHER*") & dealnum==403
replace new_portlnd1="JONESPORT" if permit==700000 & strmatch(portlnd1,"OTHER*")


replace new_portlnd1="ADDISON" if permit==220615 & strmatch(portlnd1,"OTHER*") & dealnum==2454
replace new_portlnd1="ADDISON" if permit==221911 & strmatch(portlnd1,"OTHER*")
replace new_portlnd1="ADDISON" if permit==135903 & strmatch(portlnd1,"OTHER*") & inlist(dealnum, 2454)
replace new_portlnd1="ADDISON" if permit==130510 & strmatch(portlnd1,"OTHER*") & inlist(dealnum, 345)


replace new_portlnd1="SOUTH ADDISON" if permit==130510 & strmatch(portlnd1,"OTHER*") & inlist(dealnum,348, 2454)

replace new_portlnd1="BEALS ISLAND" if permit==131009 & strmatch(portlnd1,"OTHER*") & dealnum==405

replace new_portlnd1="BUCKS HARBOR" if permit==137698 & strmatch(portlnd1,"OTHER*")
replace new_portlnd1="BUCKS HARBOR" if permit==146501 & strmatch(portlnd1,"OTHER*")
replace new_portlnd1="BUCKS HARBOR" if permit==146862 & strmatch(portlnd1,"OTHER*")



replace new_portlnd1="SHINNECOCK" if permit==310506 & strmatch(portlnd1,"OTHER SUFFOLK")
replace new_portlnd1="SHINNECOCK" if permit==330124 & strmatch(portlnd1,"OTHER SUFFOLK")
replace new_portlnd1="SHINNECOCK" if permit==330132 & strmatch(portlnd1,"OTHER SUFFOLK")
replace new_portlnd1="SHINNECOCK" if permit==330183 & strmatch(portlnd1,"OTHER SUFFOLK")
replace new_portlnd1="SHINNECOCK" if permit==330632 & strmatch(portlnd1,"OTHER SUFFOLK")
replace new_portlnd1="SHINNECOCK" if permit==410324 & strmatch(portlnd1,"OTHER SUFFOLK")



replace new_portlnd1="ISLIP" if permit==320999 & strmatch(portlnd1,"OTHER*")
replace state1="NY" if permit==320999 & new_portlnd1=="ISLIP"


replace new_portlnd1="ATLANTIC CITY" if permit==320600 & strmatch(portlnd1,"OTHER*")

replace new_portlnd1="POINT PLEASANT" if permit==330183 & portlnd1=="OTHER NJ"
replace new_portlnd1="POINT PLEASANT" if permit==330183 & portlnd1=="OTHER NEW JERSEY"

replace new_portlnd1="POINT PLEASANT" if permit==330183 & strmatch(portlnd1,"OTHER OCEAN")

replace new_portlnd1="POINT JUDITH" if permit==410204 & strmatch(portlnd1,"OTHER*")


replace new_portlnd1=portlnd1 if new_portlnd1==""
drop portlnd1
rename new_portlnd1 portlnd1


#delimit;
merge m:1 portlnd1 state1 using "${data_external}\communities_cleaned3.dta", keep(1 3);
gen state=floor(port/10000);
gen county=mod(port,100);
gen raw_revenue=revenue1;
gen adj_qtykept=qtykept;
gen state_xfactor=1;
gen dbyear=.;
gen tripid=.;
assert _merge==3;



/*
drop unknown port codes:
drop if port>=990000;
*/

drop areakey hcounty lat lon _merge placenm placest countyfp statefp cousubfp;
compress;


/*patch the areas (inshore into the usual areas) 


631	300*/
replace carea=511  if inlist(carea,013, 017, 022);
replace carea=512  if inlist(carea,018, 028);
replace carea=513  if inlist(carea,003, 026, 039,114);
replace carea=514  if inlist(carea,057, 058, 085, 105, 106, 107, 115, 116, 117);
replace carea=521  if inlist(carea,108);
replace carea=526  if inlist(carea,109);

replace carea=537  if inlist(carea,113);
replace carea=538  if inlist(carea,055, 075, 092, 094, 112);
replace carea=611  if inlist(carea,140, 141, 142, 143, 144, 145, 147, 148, 149, 150, 168);
replace carea=538  if inlist(carea,061, 121, 127, 131, 132, 134);

replace carea=612  if inlist(carea,158, 159, 160, 161, 162, 163, 164, 178, 179, 181, 394);
replace carea=613  if inlist(carea,165, 166, 167);
replace carea=614  if inlist(carea,170, 175,180);
replace carea=621  if inlist(carea,171, 172, 173, 188, 190, 193, 199, 200);
replace carea=621  if inlist(carea,214, 216, 218, 220, 222, 225, 227, 239, 246, 251, 258, 260, 275, 279, 305, 306, 307, 316, 318, 323, 325, 343, 351, 353, 354, 358, 359, 360, 371, 374, 382, 393);




gen str3 EPU="00";
replace EPU="gom" if inlist(carea, 500, 510, 512, 513, 514, 515);
replace EPU="gb" if inlist(carea,521, 522, 523, 524, 525, 526, 551,552,561,562);
replace EPU="mab" if inlist(carea,537,539,600,612, 613, 614, 615, 616,621,622,625,626,631,632);
replace EPU="ss" if inlist(carea,463, 464, 465, 466, 467,511);

/*need to figure out how to deal with 1996 data that has tenmnsq but not carea. */

save "${data_main}\sfclam_areas_$vintage_string.dta", replace;
export delimited "${data_main}\sfclam_areas_$vintage_string.csv", delimit(",") replace;


