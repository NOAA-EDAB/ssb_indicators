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
odbc load,  exec("select * from NEFSC_GARFO.SFCLAM_sfoqvr") $oracle_cxn;
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

rename vr_rec_id tripid;
notes: sfclam tripid is the vr_rec_id and only is available from 2003 to present;
keep dnum tripid permit quantity price year month day nespp3 value port;


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
collapse (sum) qtykept revenue1, by(permit dealnum myspp port year date tripid);
merge m:1 port using `portregular', keep(1 3);
assert _merge==3;
drop _merge;
rename portnm portlnd1;
rename stateabb state1;
/* a little bit of cleaning */
quietly do "${extraction_code}\spelling_fixer1.do";

/* Lou's corrections */
#delimit cr
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

replace new_portlnd1="POINT PLEASANT" if permit==330183 & strmatch(portlnd1,"OTHER NJ")
replace new_portlnd1="POINT PLEASANT" if permit==330183 & strmatch(portlnd1,"OTHER NEW JERSEY")

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
assert _merge==3;



/*
drop unknown port codes:
drop if port>=990000;
*/

drop areakey hcounty lat lon _merge placenm placest countyfp statefp cousubfp;
compress;

save "${data_intermediate}/sfclam96_2013.dta", replace;




