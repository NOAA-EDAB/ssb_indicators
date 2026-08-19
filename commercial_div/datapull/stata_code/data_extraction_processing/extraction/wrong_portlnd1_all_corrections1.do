/* This do files uses VESLOG T, S, G, and PORT.
It extracts the VTR images of all entries that:
a.  Have a portlnd1 that was renamed "OTHER" during the data entry process
b.  Landed the species of fish that we care about in ME --> VA.
c.  Does not have a dealnum=some strange dealnum

The VTR images are renamed by P<permit_number>_S<serial_num>.tif and placed in the home directory.


In veslog G -- sideid corresponds to the directory in which the files are stored.
            -- filename is the filename.  side_id is also the extension, but the capital X must be remapped to a lowercase x

NOTE: I think 2014 images would be stored in folder xa2, but these are not available yet.
This is one part of the data cleaning step for ports. 
The other part is dealing with "PORT" that were set to "null"

Our goal for data cleaning of portlnd1 and state1 is to get the right city and state. 
While there will be some error associated with this, we will spatial join to the Census CCD/MCD level.  This will sweep out much of the errors.


It ONLY examines VTRs for the FED94 species.  The corrected is at the "tripid" but some of the code used
to correct that data cleans it using permit or serial number.  The code is a fragile - take care in re-using it. 



Min-Yang.Lee@noaa.gov
July 15, 2014

We are getting a few extra records, these are the 'RED' and 'CAT' VTRS 


*/
#delimit; 



tempfile portfixer1 scallopfixer1;

	tempfile new_portlnd;
	local port_files `"`port_files'"`new_portlnd'" "'  ;
	clear;
	odbc load,  exec("select g.filename, g.sideid, g.imgtype,to_char(t.docid) as tripid, g.serial_num, t.vessel_permit_num as permit, t.port1 as portlnd1, t.state1, t.PORT1_NUMBER as port, EXTRACT(YEAR from t.DATE_LAND) as dbyear 
	from NEFSC_GARFO.document t, NEFSC_GARFO.catch s, NEFSC_GARFO.images g
where g.imgid=s.imgid and t.docid=g.docid and 
s.dealer_num not in ('99998', '1', '2', '5', '7', '8') and s.kept>=1 and s.kept is not null and 
t.state1 in('NH','MA','RI','CT','NJ','DE','MD','VA','PA','NY','DC','ME') and 
s.species_id in ('TILE','TILEG','BUT','COD', 'FLBB','FLUKE','FLGS','FLYT','FLSD', 'FLDAB','FLSD','FLDR', 'HADD','HAL','MACK','RED','POUT','POLL','CAT','LOL','ILX','SQNS', 'WHAK','HAKNS','RHAK','WHAK','SHAK','HAKOS','WHB')    
and (t.port1 like '%OTHER%')
order by t.vessel_permit_num, g.serial_num, t.state1, t.PORT1_NUMBER, t.port1;") $oracle_cxn;
	quietly count;
	if r(N)==0{;
	qui set obs 1;
	qui gen emptyds=1;
	};
drop if DBYEAR>$lastyr;
	quietly save `new_portlnd', emptyok;

dsconcat `port_files';
cap drop emptyds;
/* drop the duplicates tripid-permit-serial_nums */
 renvarlab, lower;
duplicates drop tripid permit dbyear, force;
drop if tripid==""; /*This takes care of years for which there were no data */


/*assemble the file names and directories */

gen extension=lower(sideid);
gen full_file= filename + "." + extension;



/* Clean up directory naming
1.  X01 through X05 map to img1 to img5
2.  img7-8
3.  img10-12
4.  don't know what happened to img9 or img6
*/
/*Requires egenmore package*/
egen p=sieve(sideid), omit(X);
gen str8 directory= "img"+p;
replace directory="img1" if strmatch(directory, "img01");
replace directory="img2" if strmatch(directory, "img02");
replace directory="img3" if strmatch(directory, "img03");
replace directory="img4" if strmatch(directory, "img04");
replace directory="img5" if strmatch(directory, "img05");
replace directory="img7-8" if strmatch(directory, "img07");
replace directory="img7-8" if strmatch(directory, "img08");
replace directory="img10-12/img10" if strmatch(directory, "img10");
replace directory="img10-12/img11" if strmatch(directory, "img11");
replace directory="img10-12/img12" if strmatch(directory, "img12");




drop extension p;
sort permit dbyear serial_num;
notes: this file created by "U:/READ-SSB-Lee-spacepanels/stata_code/data_extraction_processing/extraction/wrong_portlnd1_all_correction.do";
label var dbyear "VESLOG_YYYY";
notes: dbyear is the YYYY corresponding to veslog and may or may not be equal to the year of datelnd, datesail, or datesold.;
keep permit tripid serial_num dbyear portlnd1 state1 full_file directory sideid;


save `portfixer1.dta', replace;

/********************************************************************/
/********************************************************************/
/*If we don't need to actually get the image files, we can comment this out. */
/********************************************************************/
/********************************************************************/


/*
/* loop over the "full_files".  Copy them from the network into our working directory.  give them the name PPPPPP_SSSSSSSS.tif*/

/* I've set the variable retrieved =1 when the file is retrieved.
I run "capture confirm" before copying. This checks to see if the file exists. If the file exists, it is copied and "retrieved" is set to zero.  Otherwise, nothing happens.
This prevents the loop from breaking.
*/
gen retrieved=0;
quietly count;
local myobs =r(N);


quietly forvalues i=1/`myobs'{;
	local serverdir=directory[`i'];
	local serverfile=full_file[`i'];
	local myperm=permit[`i'];
	local myserial=serial_num[`i'];
	capture confirm file "/win/net/permit_img/`serverdir'/`serverfile'";
	if _rc==0{;
	copy "/win/net/permit_img/`serverdir'/`serverfile'" "P`myperm'_S`myserial'.tif", replace;
	replace retrieved=1 if _n==`i';
	};
	else{;
	display "the file `i' is missing";
	};
	else;
};
drop sideid ;


order permit tripid serial_num dbyear;
sort permit tripid serial dbyear;
drop full_file directory;
*/

/* NOTE: ON WINDOWS, the copy statement will be a bit different. I think the slashes will be reversed and you may have to use the drive letter that you mapped to 'net' 
so this might be something like:

    capture confirm file "U:/`serverdir'/`serverfile'";
    if _rc==0{;
    copy "U:/`serverdir'/`serverfile'" "P`myperm'_S`myserial'.tif", replace;
Where U is mapped to net\\permit_img 

*/


/*an alternative would be to put these into different directories by permit  
I'm not sure stata can generate directories for you in the copy statement or if you need to first generate folders for each permit and then copy into those folders

This statement may or may not work
	copy "/win/net/permit_img/`serverdir'/`serverfile'" "/`myperm'/S`myserial'.tif", replace;
*/
/********************************************************************/
/********************************************************************/
/*If we don't need to actually get the image files, we can comment this out. */
/********************************************************************/
/********************************************************************/


gen written_port=""  ;
replace written_port="OCEANPORT" if permit==109433  & dbyear<=2014; 
replace written_port="NORTHPORT" if permit==115913  & dbyear<=2014;
replace written_port="GREAT KILLS" if permit==116569 & dbyear<=2014;	 ; /**FOR SOME OF HIS TRIPS, HE REPORTED ANOTHER TRIPID HOBOKEN (WHICH MAY HAVE BEEN FOR PERSONAL CONSUMPTION),BUT THAT IS NOT IN THE TABLE, SO ALL TRIPS CATEGORIZED TO GREAT KILLS***/ 
replace state1="NY" if permit==116569 & written_port=="GREAT KILLS"	& dbyear<=2014;										
replace written_port="NORTHPORT" if permit==121260  & dbyear<=2014;	
replace written_port="OAKDALE" if permit==122950 & dbyear<=2014;	
replace written_port="ISLAND PARK" if permit==122963 & dbyear<=2014;	
replace written_port="BROAD CHANNEL" if permit==123003 & dbyear<=2014;	
replace written_port="NARRAGANSETT" if permit==125841 & dbyear<=2014;	
replace written_port="EAST ROCKAWAY" if permit==126762 & dbyear<=2014;	
replace written_port="DEBS INLET" if permit==127170   & dbyear<=2014;	
replace written_port="JAMAICA BAY" if permit==127222 & dbyear<=2014;	
replace written_port="MORICHES" if permit==128205 & dbyear<=2014;	
replace written_port="GOSHEN" if permit==130097 & dbyear<=2014;	
replace written_port="EAST ROCKAWAY" if permit==130574 & dbyear<=2014;	
replace written_port="CENTER MORICHES" if permit==146574 & dbyear<=2014;
replace written_port="EASTPORT" if permit==146575 & dbyear<=2014;
replace written_port="MOUNT SINAI" if permit==146663 & dbyear<=2014;
replace written_port="ISLAND PARK" if permit==146741 & dbyear<=2014;
replace written_port="ISLAND PARK" if permit==146779 & dbyear<=2014;
replace written_port="OCEANSIDE" if permit==146783 & dbyear<=2014;
replace written_port="OCCOQUAN" if permit==146836 & dbyear<=2014;
replace written_port="ISLAND PARK" if permit==148394 & dbyear<=2014;
replace written_port="MOUNT SINAI" if permit==148541 & dbyear<=2014;
replace written_port="NORTHPORT" if permit==148644 & dbyear<=2014;
replace written_port="MARGATE" if permit==149370 & dbyear<=2014;
replace written_port="HEISLERVILLE" if permit==149401 & dbyear<=2014;
replace written_port="LAMOINE" if permit==149458 & dbyear<=2014;
replace written_port="ALLENS HARBOR" if permit==149571 & dbyear<=2014; 
replace written_port="FIRE ISLAND INLET" if permit==149597 & dbyear<=2014;
replace written_port="RUMBLEY" if permit==149995 & dbyear<=2014;
replace written_port="ONANCOCK" if permit==150257 & dbyear<=2014;
replace written_port="WYCHMERE HARBOR" if permit==213029 & dbyear<=2014;
replace written_port="EAST HAMPTON" if permit==213555 & dbyear<=2014;
replace written_port="MASTIC" if permit==213661 & dbyear<=2014;
replace written_port="ISLAND PARK" if permit==214883 & dbyear<=2014;
replace written_port="EAST HAMPTON" if permit==220171 & dbyear<=2014;
replace written_port="MORICHES" if permit==220235 & dbyear<=2014;
replace written_port="ROCKAWAY BEACH" if permit==220481 & dbyear<=2014;
replace written_port="SAKONNET POINT" if permit==221313 & dbyear<=2014;
replace written_port="SHELTER ISLAND" if permit==222289 & dbyear<=2014;
replace written_port="SHELTER ISLAND" if permit==222469 & dbyear<=2014;
replace written_port="ISLAND PARK" if permit==222532 & dbyear<=2014;
replace written_port="ISLAND PARK" if permit==222536 & dbyear<=2014;
replace written_port="OCEANSIDE" if permit==222797 & dbyear<=2014;
replace written_port="SNUG HARBOR" if permit==222843 & dbyear<=2014;
replace written_port="WEST ISLIP" if permit==223350 & dbyear<=2014;
replace written_port="OCEANSIDE" if permit==223369 & dbyear<=2014;
replace written_port="BROAD CHANNEL" if permit==223438 & dbyear<=2014;
replace written_port="MORICHES" if permit==223518 & dbyear<=2014;
replace written_port="SETAUKET" if permit==231494 & dbyear<=2014;
replace written_port="PORT MONMOUTH" if permit==232036 & dbyear<=2014;
replace written_port="MORICHES" if permit==232178 & dbyear<=2014;
replace written_port="SEABROOK" if permit==232278 & dbyear<=2014;
replace state1="NH" if written_port=="SEABROOK" & permit==232278 & dbyear<=2014;
replace written_port="ISLAND PARK" if permit==233458 & dbyear<=2014;
replace written_port="HAMPTON BAYS" if permit==233468 & dbyear<=2014;
replace written_port="SHELTER ISLAND" if permit==233495 & dbyear<=2014;
replace written_port="CEDAR HILL" if permit==233536  & dbyear<=2014;/**NO CEDAR HILL IN TABLE***/
replace written_port="HAMPTON BAYS" if permit==233649 & dbyear<=2014;
replace written_port="MARTHAS VINEYARD" if permit==240095  & dbyear<=2014;/**NO MV IN TABLE***/
replace written_port="MENEMSHA" if permit==240150 & dbyear<=2014;
replace written_port="EAST HAMPTON" if permit==240383 & dbyear<=2014;
replace written_port="MENEMSHA" if permit==240535 & dbyear<=2014;
replace written_port="CAPTREE" if permit==241616 & dbyear<=2014;
replace written_port="NEW YORK" if permit==242710 & dbyear<=2014;
replace written_port="HUNTINGTON" if permit==250004 & dbyear<=2014;
replace written_port="HOWARD BEACH" if permit==250238 & dbyear<=2014;
replace written_port="MENEMSHA" if permit==250458 & dbyear<=2014;
replace written_port="SAYVILLE" if permit==250516 & dbyear<=2014;
replace written_port="SAYVILLE" if permit==250516 & dbyear<=2014;
replace written_port="ATLANTIC BEACH" if permit==310714 & dbyear<=2014;
replace written_port="POINT PLEASANT" if permit==310980 & dbyear<=2014;
replace written_port="CHESAPEAKE" if permit==320162 & dbyear<=2014;
replace written_port="BLOCK ISLAND" if permit==320341 & dbyear<=2014;
replace written_port="CAPTREE STATE PARK" if permit==320464 & dbyear<=2014;
replace written_port="POINT PLEASANT" if permit==320584 & dbyear<=2014;
replace written_port="THREE MILE HARBOR" if permit==320619 & dbyear<=2014;
replace written_port="BEAUFORT" if permit==320664 & dbyear<=2014;
replace state1="NC" if permit==320664 & dbyear<=2014;
replace written_port="CITY ISLAND" if permit==320789 & dbyear<=2014;
replace written_port="CAPE MAY" if permit==330322 & dbyear<=2014;
replace written_port="NORTHPORT" if permit==330630 & dbyear<=2014;

replace written_port="YORKTOWN" if permit==330788 & dbyear<=2014;
replace written_port="YORKTOWN" if permit==330672 & dbyear<=2014;
replace written_port="YORKTOWN" if permit==330672 & dbyear<=2014;
replace written_port="YORKTOWN" if permit==410337 & dbyear<=2014;
replace written_port="SEAFORD" if written_port=="YORKTOWN"& dbyear<=2014;
replace written_port="ROCKAWAY" if permit==800119 & dbyear<=2014;



replace written_port="MOUNT SINAI" if permit==800124 & dbyear<=2014;
replace written_port="JAMAICA BAY" if permit==800155 & dbyear<=2014;
replace written_port="GREENPORT" if permit==800177 & dbyear<=2014; 
replace written_port="SMITHTOWN" if permit==800222 & dbyear<=2014;
replace written_port="SHELTER ISLAND" if permit==800248 & dbyear<=2014;
replace written_port="MORICHES" if permit==800270 & dbyear<=2014;
replace written_port="SHELTER ISLAND" if permit==800318 & dbyear<=2014;
replace written_port="ISLAND PARK" if permit==800322 & dbyear<=2014;
replace written_port="NORTHPORT" if permit==800330 & dbyear<=2014;
replace written_port="GREENPORT" if permit==800332 & dbyear<=2014;
replace written_port="THREE MILE HARBOR" if permit==800334 & dbyear<=2014;
replace written_port="PATCHOGUE" if permit==800352 & dbyear<=2014;
replace written_port="BALDWIN" if permit==800364 & dbyear<=2014;
replace written_port="BROAD CHANNEL" if permit==800371 & dbyear<=2014;
replace written_port="BELLMORE" if permit==800387 & dbyear<=2014;
destring tripid, replace ;
replace written_port="SAYVILLE" if permit==800392 & (tripid==1984063 | tripid==1984065 | tripid==1984079 | tripid==2018907 | tripid==1984070) & dbyear<=2014;
replace written_port="WEST SAYVILLE" if permit==800392 & tripid==2449962 & dbyear<=2014;
replace written_port="BAYPORT" if permit==800392 & (tripid==2449963 | tripid==2550302) & dbyear<=2014;
replace written_port="ACABONACK HARBOR" if permit==800398  & dbyear<=2014;/*******/ 
replace written_port="PATCHOGUE" if permit==800402 & dbyear<=2014;
replace written_port="ISLAND PARK" if permit==800416 & dbyear<=2014;
replace written_port="MORICHES" if permit==800418 & dbyear<=2014;
replace written_port="ROCKAWAY BEACH" if permit==800427 & dbyear<=2014;
replace written_port="SHELTER ISLAND" if permit==800486 & dbyear<=2014;
replace written_port="EAST HAMPTON" if permit==800501 & dbyear<=2014;
replace written_port="EAST HAMPTON" if permit==800545 & dbyear<=2014;
replace written_port="EAST HAMPTON" if permit==800553 & dbyear<=2014;
replace written_port="ACABONACK HARBOR" if permit==800571  & dbyear<=2014;/*******/
replace written_port="MORICHES" if permit==800588 & dbyear<=2014;
replace written_port="SOUTHAMPTON" if permit==800630 & dbyear<=2014;
replace written_port="EAST QUOGUE" if permit==800675 & dbyear<=2014;
replace written_port="FREEPORT" if permit==800682 & dbyear<=2014;
replace written_port="STATEN ISLAND" if permit==800687 & dbyear<=2014;
replace written_port="EAST MORICHES" if permit==800695 & dbyear<=2014;
replace written_port="PATCHOGUE" if permit==800707 & dbyear<=2014;
replace written_port="MORICHES" if permit==800731 & dbyear<=2014;

replace written_port="DEBS INLET" if permit==800844  & dbyear<=2014;/*NOT IN TABLE**/
replace written_port="EAST HAMPTON" if permit==800865 & dbyear<=2014;
replace written_port="ISLAND PARK" if permit==800886 & dbyear<=2014;
replace written_port="GLEN COVE" if permit==800946 & dbyear<=2014;
replace written_port="NORTHPORT" if permit==800985 & dbyear<=2014;

/**************************************************************/

/*GOING THROUGH THE TRIP REPORTS ONES MENTIONED ABOVE, AND TRACING THROUGH DEALER-PERMIT # IN CFDERS:
	1. HOBOKEN GUY SEEMS TO WRITE HOBOKEN WHEN HE IS KEEPING SOME OF HIS CATCH FOR PERSONAL CONSUMPTION  
	2. CEDAR HILL GUY I HAVE NO IDEA B/C HE WRITES "NONE" AS DEALNUM
	3. MARTHAS VINEYARD GUY TRACKED TO WOODS HOLE PORT 
	3. IM PRETTY SURE DEBS INLET IS EAST ROCKAWAY  (BOTTOM OF THIS PAGE http://www.bayparkfishing.com/)   
	4. NOT SURE ABOUT ACABONACK HARBOR    *********************/
/**************************************************************/
					
replace written_port="WOODS HOLE" if permit==240095  & dbyear<=2014;
replace written_port="EAST ROCKAWAY" if written_port=="DEBS INLET" ;
rename serial_num serial_string;




egen serial_num=sieve(serial_string), keep(n);
destring serial_num, replace;

replace written_port="KEANSBURG" if permit==109433 & (serial_num==11410876 |
serial_num==11410877 |
serial_num==11410878 |
serial_num==11410879 |
serial_num==11410880 |
serial_num==11410881 |
serial_num==11410882 |
serial_num==11410883 |
serial_num==11410884 |
serial_num==11410885 |
serial_num==11410886 |
serial_num==11410888 |
serial_num==11410893 |
serial_num==11692702 |
serial_num==11817790 |
serial_num==11817798); 
replace written_port="OCEANPORT" if permit==109433 & (tripid==3947338 | tripid==3947339 | tripid==3941744) ;
replace written_port="BELFORD" if serial_num==11535219 ;
replace state1="NJ" if serial_num==11535219 ;
replace written_port="POINT PLEASANT" if serial_num==11797434 ;
replace state1="NJ" if serial_num==11797434 ;
replace written_port="MASTIC BEACH" if serial_num==11667331 ;
replace written_port="MASTIC BEACH" if serial_num==11667332 ;
replace written_port="MASTIC BEACH" if serial_num==11667333 ;
replace written_port="MASTIC BEACH" if serial_num==11667334 ;
replace written_port="MASTIC BEACH" if serial_num==11667335 ;
replace written_port="MASTIC BEACH" if serial_num==11667336 ;
replace written_port="MASTIC BEACH" if serial_num==11667339 ;
replace written_port="MASTIC BEACH" if serial_num==11667341 ;
replace written_port="MASTIC BEACH" if serial_num==11667342 ;
replace written_port="MASTIC BEACH" if serial_num==11667343 ;
replace written_port="MASTIC BEACH" if serial_num==11667344 ;
replace written_port="MASTIC BEACH" if serial_num==11667345 ;
replace written_port="MASTIC BEACH" if serial_num==11667346 ;
replace written_port="MASTIC BEACH" if serial_num==11667347 ;
replace written_port="MASTIC BEACH" if serial_num==11667348 ;
replace written_port="MASTIC BEACH" if serial_num==11667349 ;
replace written_port="MASTIC BEACH" if serial_num==11667350 ;
replace written_port="GOSHEN" if serial_num==11675249 ;
replace written_port="GOSHEN" if serial_num==11675250 ;
replace written_port="KEANSBURG" if serial_num==11683637 ;
replace written_port="KEANSBURG" if serial_num==11683638 ;
replace written_port="KEANSBURG" if serial_num==11683639 ;
replace written_port="KEANSBURG" if serial_num==11683640 ;
replace written_port="KEANSBURG" if serial_num==11683643 ;
replace written_port="KEANSBURG" if serial_num==11683645 ;
replace written_port="KEANSBURG" if serial_num==11683646 ;
replace written_port="BRONX" if serial_num==11719235 ;
replace written_port="BRONX" if serial_num==11719236 ;
replace written_port="BRONX" if serial_num==11719237 ;
replace written_port="BRONX" if serial_num==11719238 ;
replace written_port="BRONX" if serial_num==11719239 ;
replace written_port="BELFORD" if serial_num==11753632 ;
replace state1="NJ" if serial_num==11753632 ;
replace written_port="EAST ROCKAWAY" if serial_num==11764374 ;
replace written_port="EAST ROCKAWAY" if serial_num==11764390 ;
replace written_port="EAST ROCKAWAY" if serial_num==11764393 ;
replace written_port="NEW YORK" if serial_num==11782800 ;
replace written_port="MASTIC BEACH" if serial_num==11828001 ;
replace written_port="MASTIC BEACH" if serial_num==11828002 ;
replace written_port="MASTIC BEACH" if serial_num==11828003 ;
replace written_port="MASTIC BEACH" if serial_num==11828004 ;
replace written_port="MASTIC BEACH" if serial_num==11828005 ;
replace written_port="MASTIC BEACH" if serial_num==11828007 ;
replace written_port="NEW YORK" if serial_num==11852555 ;
replace written_port="NEW YORK" if serial_num==11852557 ;
replace written_port="NEW YORK" if serial_num==11852558 ;
replace written_port="NEW YORK" if serial_num==11852559 ;
replace written_port="NEW YORK" if serial_num==11852561 ;
replace written_port="NEW YORK" if serial_num==11852563 ;
replace written_port="NEW YORK" if serial_num==11852564 ;
replace written_port="NEW YORK" if serial_num==11852565 ;
replace written_port="NEW YORK" if serial_num==11852566 ;
replace written_port="NEW YORK" if serial_num==11852570 ;
replace written_port="MENEMSHA" if serial_num==11855773 ;
replace state1="MA" if serial_num==11855773 ;
replace written_port="NEW YORK" if serial_num==11885639 ;
replace written_port="NEW YORK" if serial_num==11885640 ;
replace written_port="NEW YORK" if serial_num==11885641 ;
replace written_port="NEW YORK" if serial_num==11885642 ;
replace written_port="NEW YORK" if serial_num==11885643 ;
replace written_port="NEW YORK" if serial_num==11885644 ;
replace written_port="NEW YORK" if serial_num==11885645 ;
replace written_port="NEW YORK" if serial_num==11885646 ;
replace written_port="NEW YORK" if serial_num==11885647 ;
replace written_port="NEW YORK" if serial_num==11885648 ;
replace written_port="MENEMSHA" if serial_num==11885649 ;
replace state1="MA" if serial_num==11885649 ;
replace written_port="BELFORD" if serial_num==11888279 ;
replace state1="NJ" if serial_num==11888279 ;
replace written_port="BELFORD" if serial_num==11888286 ;
replace state1="NJ" if serial_num==11888286 ;
replace written_port="KEANSBURG" if serial_num==11895753 ;
replace written_port="KEANSBURG" if serial_num==11895754 ;
replace written_port="KEANSBURG" if serial_num==11895755 ;
replace written_port="KEANSBURG" if serial_num==11895756 ;
replace written_port="KEANSBURG" if serial_num==11895757 ;
replace written_port="KEANSBURG" if serial_num==11895758 ;
replace written_port="MASTIC BEACH" if (serial_num==11896851 | serial_num==11896852 |
serial_num==11896853 |serial_num==11896854 |serial_num==11896855 |serial_num==11896856 |
serial_num==11896857 |serial_num==11896858 |serial_num==11896859 |serial_num==11896860 |
serial_num==11896861 |serial_num==11896864 |serial_num==11896865 |serial_num==11896866 |
serial_num==11896867 |serial_num==11896868 |serial_num==11896869 |serial_num==11896870 |
serial_num==11896871 |serial_num==11896872 |serial_num==11896873 |serial_num==11896874 |
serial_num==11896875 |serial_num==11896876 |serial_num==11896877 |serial_num==11896878 |
serial_num==11896879 |serial_num==11896880 |serial_num==11896881 |serial_num==11896882 |
serial_num==11896883 |serial_num==11896884 |serial_num==11896885 |serial_num==11896886 |
serial_num==11896887 |serial_num==11896888 |serial_num==11896889 |serial_num==11896890 |
serial_num==11896891 |serial_num==11896892 |serial_num==11896893 |serial_num==11896894 |
serial_num==11896895 |serial_num==11896896 |serial_num==11896897 |serial_num==11896898 |
serial_num==11896899 |serial_num==11896900) ;

replace written_port="NEW YORK" if (serial_num==11897192 |
serial_num==11897193 |serial_num==11897194 |
serial_num==11897195 |serial_num==11905815) ;

replace written_port="GOSHEN" if (serial_num==11906301 |
serial_num==11906302 |serial_num==11906305 |
serial_num==11906306 |serial_num==11906307) ;

replace written_port="MONTAUK" if serial_num==9903168 | serial_num==9903168 ;


replace written_port="CHINCOTEAGUE" if permit==330455 & tripid== 167644;
replace state1="VA" if permit==330455 & tripid== 167644;

replace written_port="NEW BEDFORD" if tripid==176507 & permit==330168;
replace state1="MA"  if tripid==176507 & permit==330168;

replace written_port= "POINT LOOKOUT" if permit==330388 & tripid==149799 ;
replace state1="NY" if permit==330388 & tripid==149799;

replace written_port="MONTAUK" if serial_num==9903169 & permit==114998 ;

replace written_port= "POINT JUDITH" if dbyear==2011 & portlnd1=="OTHER NEWPORT" & written_port==" " ;

replace written_port= "POINT PLEASANT" if permit==242817 & tripid==4393167 ;
replace written_port="HAMPTON" if permit==330220 & tripid== 168612  ;
replace written_port="AMAGANSETT" if written_port=="ACABONACK HARBOR" ;

drop if written_port=="CEDAR HILL" ;
duplicates drop (permit tripid dbyear), force ;


replace written_port="BELFORD" if permit==150729 & tripid==3427973 & dbyear==2010;
replace state1="NJ" if permit==150729 & tripid==3427973 & dbyear==2010;


replace written_port="AMAGANSETT" if permit==233691 & tripid==3826217 & dbyear==2012;
replace state1="NY" if permit==233691 & tripid==3826217 & dbyear==2012;

replace written_port="NEW YORK CITY" if permit==251683 & (tripid==4015348| tripid==4021323)  & dbyear==2012;
replace written_port="NEW YORK CITY" if permit==251683 & (tripid==4348445| tripid==4348447 | tripid==4348449 | tripid==4348451)  & dbyear==2013;
replace written_port="NEW YORK CITY" if permit==251683 & strmatch(portlnd1,"OTHER NY") & dbyear==2014;



replace state1="NY" if permit==251683 & written_port=="NEW YORK CITY";
replace written_port="POINT JUDITH" if permit==250693 & dbyear==2012;



replace state1="RI" if permit==233691 & tripid==3826217 & dbyear==2012;

replace written_port="MORICHES" if permit==232224 & tripid==900032 & dbyear==1999;
replace state1="NY" if permit==233691 & tripid==3826217 & dbyear==2012;

replace written_port="HAMPTON BAYS" if permit==241495 & (tripid==3557986| tripid==3557987) & dbyear==2010;
replace written_port="HAMPTON BAYS" if permit==241495 & (tripid==3557986| tripid==3557987) & dbyear==2010;
replace written_port="MENEMSHA" if permit==250566 & tripid==3388623 & dbyear==2010;
replace written_port="NEWPORT" if permit==320205 & tripid==4197282 & dbyear==2013;
replace state1="RI" if permit==320205 & tripid==4197282 & dbyear==2013;


replace written_port="POINT LOOKOUT" if permit==320410 & tripid==3390821 & dbyear==2010;
	replace state1="NY" if permit==320410 & tripid==3390821 & dbyear==2010;

replace written_port="POINT LOOKOUT" if permit==320410 & tripid==3411709 & dbyear==2010;
	replace state1="NY" if permit==320410 & tripid==3411709 & dbyear==2010;
replace written_port="POINT LOOKOUT" if permit==320410 & tripid==3412194 & dbyear==2010;
	replace state1="NY" if permit==320410 & tripid==3412194 & dbyear==2010;

replace written_port="POINT LOOKOUT" if permit==320410 & tripid==3445401 & dbyear==2010;
	replace state1="NY" if permit==320410 & tripid==3445401 & dbyear==2010;
replace written_port="POINT LOOKOUT" if permit==320410 & tripid==3445403 & dbyear==2010;
	replace state1="NY" if permit==320410 & tripid==3445403 & dbyear==2010;
replace written_port="POINT LOOKOUT" if permit==320410 & tripid==3498409 & dbyear==2010;
	replace state1="NY" if permit==320410 & tripid==3498409 & dbyear==2010;

replace written_port="POINT LOOKOUT" if permit==330303 & tripid==3972512 & dbyear==2012;
	replace state1="NY" if permit==330303 & tripid==3972512 & dbyear==2012;

replace written_port="POINT PLEASANT" if permit==330888 & tripid==3522769 & dbyear==2010;
	replace state1="NJ" if permit==330888 & tripid==3522769 & dbyear==2010;

replace written_port="BRONX" if permit==320645 & dbyear==2013 &  (tripid >=4252550 & tripid<=4252554);

replace written_port="BRONX" if permit==320645 & dbyear==2013 &  (tripid >=4255477 & tripid<=4255479);

replace written_port="BRONX" if permit==320645 & dbyear==2013 &  (tripid >=4258990 & tripid<=4258991);

replace written_port="BRONX" if permit==320645 & dbyear==2013 &  (tripid==4258995 | tripid==4262334 | tripid==4262335 | tripid==4262337| tripid==4288471);
	replace state1="NY" if written_port=="BRONX";
	
	
replace written_port="POINT JUDITH" if permit==250693 & (tripid>=25069311100000);
	replace state1="RI" if permit==250693 & (tripid>=25069311100000);

replace written_port="POINT JUDITH" if permit==250693 & tripid>=2506931110000;




replace written_port="SEAFORD" if portlnd1=="OTHER YORK" & permit==310992 & tripid==4462539; 
replace written_port="SEAFORD" if portlnd1=="OTHER YORK" & permit==310992 & tripid==4472113; 

replace written_port="PORT REPUBLIC" if portlnd1=="OTHER BURLINGTON" & permit==151668 & (tripid==4440730| tripid==4440473 | tripid==4440239); 

replace written_port="OCEAN CITY" if portlnd1=="OTHER NY" & permit==240208 & (tripid==4518121); 
replace  state1="MD" if state1=="NY" & permit==240208 & (tripid==4518121); 
replace written_port="MONTAUK" if tripid==3742242 & dbyear==2011;


replace written_port="OCEAN CITY" if portlnd1=="OTHER NY" & permit==221991 & tripid==4584048 & dbyear==2014;
replace state1="MD" if permit==221991 & tripid==4584048 & dbyear==2014;

replace written_port="BARNEGAT" if permit==251212 & tripid==4583991 & dbyear==2014;
replace state1="NJ" if permit==251212 & tripid==4583991 & dbyear==2014;

replace state1="VA" if permit==320932 & tripid==1771428 & dbyear==2003;






















/*Geret's corrections start here*/

replace portlnd1=ltrim(rtrim(itrim(portlnd1)));
*RI;
replace written_port="SAKONNET POINT" if inlist(permit,121749) & written_port == "" & inlist(tripid,2521161,2521170) ;
replace written_port="SAKONNET" if inlist(permit,210643) & written_port == "" & inlist(dbyear, 2009) ;
replace written_port = "OLD HARBOR" if inlist(permit,146744) & written_port == "" & inlist(portlnd1,"OTHER WASHINGTON(COUNTY)","OTHER MAINE") & inlist(dbyear,2010,2007);
replace state1="RI" if inlist(permit,146744) & state1 == "ME" & inlist(dbyear,2010,2007) & inlist(written_port,"OLD HARBOR");

*MA;
replace written_port="PIGEON COVE" if inlist(tripid,3488504)  & inlist(dbyear, 2010);
replace written_port="MENEMSHA" if inlist(permit,123972, 221217) & written_port == "" & inlist(tripid,3458684, 3335706, 3678567) ;
replace written_port = "SESUIT HARBOR" if inlist(permit,231435) & written_port == "" & inlist(portlnd1,"OTHER MASSACHUSETTS") & inlist(dbyear,2008);
replace written_port = "COHASSET" if inlist(permit,251110) & written_port == "" & inlist(portlnd1,"OTHER BARNSTABLE") & inlist(dbyear,2008, 2011);

*ME;
replace written_port="JONESPORT" if inlist(permit,126081) & written_port == "" & inlist(serial_string,"11505851","11505852") ;
replace state1="ME" if inlist(permit,126081) & state1 == "NY" & written_port == "JONESPORT" ;
replace written_port = "SWANS ISLAND" if inlist(permit,223572,233295) & written_port == "" & inlist(portlnd1,"OTHER HANCOCK") & inlist(dbyear, 2007,2008,2009,2010,2011);

*NY;
replace written_port="EAST HAMPTON" if inlist(permit,146716) & written_port == "" & portlnd1 == "OTHER SUFFOLK" & dbyear ==  2005;
replace written_port="HAMPTON BAYS" if inlist(permit,146737) & written_port == "" & portlnd1 == "OTHER WASHINGTON(COUNTY)" & inlist(dbyear,2010,2011);
replace written_port = "EASTPORT" if inlist(permit,148172) & written_port == "" & inlist(portlnd1,"OTHER SUFFOLK") & inlist(dbyear,2014);
replace written_port = "NEW YORK" if inlist(permit,240192) & written_port == "" & inlist(portlnd1,"OTHER NY") & inlist(dbyear,2012);
replace written_port = "WEST SAYVILLE" if inlist(permit,241161) & written_port == "" & inlist(serial_string,"10775466") & inlist(dbyear,2007);
replace written_port = "SAYVILLE" if inlist(permit,241161,320999) & written_port == "" & inlist(portlnd1,"OTHER SUFFOLK") & inlist(dbyear,2007,2008,2009,2010,2011,2012,2013,2014);
replace written_port = "HAMPTON BAYS" if inlist(permit,250542) & written_port == "" & inlist(portlnd1,"OTHER WASHINGTON(COUNTY)") & inlist(dbyear,2010);
replace written_port = "POINT LOOKOUT" if inlist(permit,242875) & written_port == "" & inlist(portlnd1,"OTHER NY") & inlist(dbyear,2012,2013);
replace written_port = "COLD SPRING" if inlist(permit,320940) & written_port == "" & inlist(portlnd1,"OTHER CAPE MAY");

replace written_port="STONY BROOK" if permit==112875 & tripid==768402	;




*NJ;
replace written_port = "BIDWELL CREEK" if inlist(permit,147950,146576) & written_port == "" & inlist(portlnd1,"OTHER CAPE MAY") & inlist(dbyear,2007);
replace written_port = "BIDWELL CREEK" if inlist(permit,147957) & written_port == "" & inlist(portlnd1,"OTHER ACCOMACK") & inlist(dbyear,2009,2010);
replace written_port = "POINT PLEASANT" if inlist(permit,149517,148080,148280) & written_port == "" & inlist(portlnd1,"OTHER OCEAN") & inlist(dbyear,2010,2009);
replace written_port = "BELFORD" if inlist(permit,230248,240195,250231,320312,320387) & written_port == "" & inlist(portlnd1,"OTHER MASSACHUSETTS") & inlist(dbyear,2009,2008,2010,2011);
replace state1 = "NJ" if inlist(permit,230248,250231,320312,320387) & written_port == "BELFORD" & inlist(portlnd1,"OTHER MASSACHUSETTS") & inlist(dbyear,2009,2011,2010,2008);
replace written_port = "OCEANPORT" if inlist(permit,330810) & written_port == "" & inlist(portlnd1,"OTHER MONMOUTH") & inlist(dbyear,2015);
replace written_port="BARNEGAT" if permit==251212 & inlist(tripid,4760523, 4766818) & dbyear==2015;

*VA;
replace written_port = "VIRGINIA BEACH" if inlist(permit,146925) & inlist(serial_string, "11759267","12287768") & written_port == "" & inlist(dbyear,2011, 2014);
replace written_port = "MATHEWS" if inlist(permit,146925) & inlist(serial_string, "12287767","12287769","12287765","12287766") & written_port == "" & inlist(dbyear,2014);
replace state1="VA" if inlist(permit,146925) & inlist(written_port,"VIRGINIA BEACH") & inlist(dbyear,2014);
replace written_port = "PERRIN RIVER" if inlist(permit,147377) & written_port == "" & inlist(portlnd1,"OTHER VIRGINIA") & inlist(dbyear,2009);
replace written_port = "BATH" if inlist(permit,221379) & written_port == "" & inlist(portlnd1,"OTHER WASHINGTON") & inlist(dbyear, 2007);

*NC;
replace written_port = "SOUTHPORT" if inlist(permit,146821) & written_port == "" & inlist(portlnd1,"OTHER BRUNSWICK") & inlist(dbyear,2007);
replace written_port = "ENGELHARD" if inlist(permit,242545) & written_port == "" & inlist(portlnd1,"OTHER NY") & inlist(dbyear,2007);
replace state1 = "NC" if inlist(permit,242545) & written_port == "" & inlist(written_port,"ENGELHARD") & inlist(dbyear,2007);
replace written_port = "ENGELHARD" if inlist(permit,242545) & written_port == "" & inlist(portlnd1,"OTHER NY") & inlist(dbyear,2007);
replace written_port = "BATH" if inlist(permit,242917) & written_port == "" & inlist(portlnd1,"OTHER BEAUFORT(COUNTY)") & inlist(dbyear, 2009, 2010);
replace written_port = "WRIGHTS CREEK" if inlist(permit,250857,310938,321092,330528) & written_port == "" & inlist(portlnd1,"OTHER BEAUFORT(COUNTY)") & inlist(dbyear, 2006,2008,2010,2011,2012,2014);
replace written_port = "COINJOCK" if inlist(permit,321092,330742,330879,242817,321096) & written_port == "" & inlist(portlnd1,"OTHER CURRITUCK") & inlist(dbyear, 2006,2010,2011,2014);

*OTHER;
replace written_port="SOMERS POINT" if inlist(permit,130806) & written_port == "" & inlist(serial_string,"10529327","10529328","10529329","10529330","10529331","10529332","10529333","10529334","10529335") ;
replace written_port="SOMERS POINT" if inlist(permit,130806) & written_port == "" & inlist(serial_string,"10529336","10529337","10529338","10794572") ;
replace written_port = "OTHER MACINTOSH" if inlist(permit,310938,320370,321092,330528,330879) & written_port == "" & inlist(portlnd1,"OTHER MACINTOSH") ;
replace written_port = "OTHER BEAUFORT" if inlist(permit,310938,320370,320651,330596,330611,330727,330786,330812,330823,410570,410584,310988,330873) & written_port == "" & inlist(portlnd1,"OTHER BEAUFORT") ;
replace written_port = "OTHER ST JOHNS" if inlist(permit,320269,320367) & written_port == "" & inlist(portlnd1,"OTHER ST JOHNS") ;
replace written_port = "OTHER DUVAL" if inlist(permit,321107,330593,330879,410584) & written_port == "" & inlist(portlnd1,"OTHER DUVAL") ;
replace written_port = "OTHER GULF" if inlist(permit,330823) & written_port == "" & inlist(portlnd1,"OTHER GULF") ;
replace written_port = "OTHER CHARLESTON" if inlist(portlnd1, "OTHER CHARLESTON") & inlist(state1,"SC") & written_port == "";
replace written_port = "OTHER BEAUFORT" if inlist(portlnd1, "OTHER BEAUFORT") & inlist(state1,"SC") & written_port == "";


replace written_port=ltrim(rtrim(itrim(written_port)));
drop serial_num;
rename state1 corrected_state;
rename written_port corrected_port;
keep permit tripid dbyear corrected_port corrected_state portlnd1;
gen source="all";



save `portfixer1', replace ;

/* Do the scallop port corrections here */

/*INSER CODE TO READ IN THE DATA HERE  I should get about 168 permit-tripids (1 duplicate) so 169 total */

	tempfile scallop_fixer;
	local port_files2 `"`port_files2'"`scallop_fixer'" "'  ;
	clear;
	odbc load,  exec("select g.filename, g.sideid, g.imgtype,to_char(t.docid) as tripid, g.serial_num, t.VESSEL_PERMIT_NUM as permit, t.port1 as portlnd1, t.state1, t.PORT1_NUMBER as port, EXTRACT(YEAR from t.DATE_LAND) as dbyear from NEFSC_GARFO.document t, NEFSC_GARFO.catch s, NEFSC_GARFO.images g
where g.imgid=s.imgid and t.docid=g.docid and 
s.dealer_num not in ('99998', '1', '2', '5', '7', '8') and s.kept>=1 and s.kept is not null and 
t.state1 in('NH','MA','RI','CT','NJ','DE','MD','VA','PA','NY','DC','ME') and 
s.SPECIES_ID in ('SCAL', 'SCALS', 'SCALG', 'SCALB')    
and (t.port1 like '%OTHER%')
order by t.VESSEL_PERMIT_NUM, g.serial_num, t.state1, t.PORT1_NUMBER, t.port1;") $oracle_cxn;
	quietly count;
	if r(N)==0{;
	qui set obs 1 ;
	qui gen emptyds=1;
	};
	drop if DBYEAR>$lastyr;
	quietly save `scallop_fixer', emptyok;


dsconcat `port_files2';
cap drop emptyds;
/* drop the duplicates tripid-permit-serial_nums */
renvarlab, lower;

duplicates drop tripid permit dbyear, force;
destring tripid permit port, replace;
compress;
drop if tripid==.; /*This takes care of years for which there were no data */


/*assemble the file names and directories */
gen extension=lower(sideid);
gen full_file= filename + "." + extension;

/* Clean up directory naming
1.  X01 through X05 map to img1 to img5
2.  img7-8
3.  img10-12
4.  don't know what happened to img9 or img6
*/
egen p=sieve(sideid), omit(X);
gen str8 directory= "img"+p;
replace directory="img1" if strmatch(directory, "img01");
replace directory="img2" if strmatch(directory, "img02");
replace directory="img3" if strmatch(directory, "img03");
replace directory="img4" if strmatch(directory, "img04");
replace directory="img5" if strmatch(directory, "img05");
replace directory="img7-8" if strmatch(directory, "img07");
replace directory="img7-8" if strmatch(directory, "img08");
replace directory="img10-12/img10" if strmatch(directory, "img10");
replace directory="img10-12/img11" if strmatch(directory, "img11");
replace directory="img10-12/img12" if strmatch(directory, "img12");

drop extension p;
sort permit dbyear serial_num;
notes: this file created by "/home/mlee/Documents/projects/spacepanels/port data/wrong_portlnd1_all_correction.do";
label var dbyear "VESLOG_YYYY";
notes: dbyear is the YYYY corresponding to veslog and may or may not be equal to the year of datelnd, datesail, or datesold.;
keep permit tripid serial_num dbyear portlnd1 state1 full_file directory sideid port;

save `scallopfixer1', replace;

/***************METHOD:  1. replace written_port with what was written on vtr ticket.  
						 2. If that matched up, with a non 'other' portlnd1, use this. 
						 3. Most did not match up like this, so I based the portlnd1 on where the 
						 dealer transaction was recorded in cfders. I would search the dealnum and permit in that 
						 year and see what port showed up.  Most of these searches resulted in one port only showing up.
						 When that happened I used this as the portlnd1/port number. A
						 Few had a multiple ports show up.  The next criteria was by matching the ports with the states reported. 
						 This matched many of the transactions to the portlnd1.
						 4. A few of the dealnums and permit corresponded to ports in separate states, like permit 330817 when 
						 they reported "OTHER SUFFOLK" and the dealer was in New Bedford.  In this situation, 
						 New Bedford was the chosen port.  Some other permit/dealnums did not exist, so I would
						 query where that dealer dealed in that year and made the correct choice based on state.  For the 
						 Marthas Vineyard guy, the only dealer he recorded in that year were Provnincetown and Glaucestor.  
						 I chose Provincetown b/c it is closer to MV.  
						 5.  With correct portlnd1's I merged on the dealer port's and got the correct  and replaced the old 'other' ports with correct port numbers.
						 6.  Drop the scallop to fix from the original dataset and append the corrected ones.   ***************************/

						 /*some of these corrections are extraneous, like correcting for the port code, but it took me a while to figure out the best way to do this.  Also, we can 
						 do tilefish and the other species (if necessary) port corrections separately */

						 /*****************************************************************************************************************************************************************************/						 


/********************************CORRECTIONS TO MERGE TO JULIE'S TABLE************************************************************************/
/***********************FOR ENTRIES NOT IN THE TABLE I USED THE OTHER INFORMATION TO CLASSIFY A PORTPLAND1*************************************/

gen written_port="";
replace written_port="POINT LOOKOUT" if tripid==149799 & dbyear==1996 ; 
replace port= 351215 if tripid==149799 & dbyear==1996 ; 
replace written_port="FALL RIVER" if strmatch(portlnd1,"*FALL RIVER*")==1 & state1=="MA" & dbyear<=2014;
replace written_port="DAMARISCOTTA" if permit==150023 & (tripid==3102564 | tripid==3102570) ;
replace written_port="COLD SPRING" if permit==150433 & dbyear<=2014; 
replace written_port="MORICHES" if permit==223518 & dbyear<=2014 ;
replace written_port="FIRE ISLAND INLET" if permit==233341  & dbyear<=2014;
replace written_port="FIRE ISLAND INLET" if permit==330817  & dbyear<=2014;
replace written_port="STAGE HARBOR" if permit==240271 & dbyear<=2014;
replace written_port="SOMERS POINT" if permit==240630 & dbyear<=2014;
replace written_port="SAYVILLE" if permit==241161 & dbyear<=2014;
replace written_port="HAMPTON BAYS" if permit==241495 & dbyear<=2014;
replace written_port="COLD SPRING" if permit==250434 & dbyear<=2014;
replace written_port="HAMPTON BAYS" if permit==250542 & dbyear<=2014;
replace written_port="POINT PLEASANT" if permit==320584 & dbyear<=2014;
replace written_port="COLD SPRING" if permit==320662 & dbyear<=2014;
replace written_port="POINT LOOKOUT" if portlnd1=="OTHER NY" & permit==321092 & dbyear<=2014 ;/**got this from code above, 
	so as to not deal with the Long Island entries in the communities table***********/
replace written_port= "POINT LOOKOUT" if  portlnd1=="OTHER NASSAU"  & dbyear<=2014;/******no jones beach*/
replace written_port="SEAFORD" if (permit==330402 | permit==330476 | permit==330788 | permit==410337) & dbyear<=2014;
replace written_port="FREEPORT" if permit==330818  & dbyear<=2014;
replace written_port="COLD SPRING" if permit==330829 & dbyear<=2014;
replace written_port="CHESAPEAKE" if permit==330852 & dbyear<=2014;
replace written_port="POINT PLEASANT" if permit==320888 & dbyear<=2014;
replace written_port="COLD SPRING" if permit==410286 & dbyear<=2014;
replace written_port="NEW BEDFORD" if portlnd1=="OTHER BARNSTABLE"  & dbyear<=2014;  /****this was one of few sketchy
	ones.  Reported Cape Cod, but dealer from New Bedford.  OOOO i get it.  This guy said he 
	was offshore waiting for weather to land.  Maybe a NB ship came out and got his scallops. ***/
replace written_port="COLD SPRING" if portlnd1=="OTHER CAPE MAY" & dbyear<=2014 ;	 
replace written_port="SEAFORD" if portlnd1=="OTHER YORK" & dbyear<=2014;

replace written_port="POINT PLEASANT" if portlnd1=="OTHER OCEAN" & dbyear<=2014;
replace written_port="PROVINCETOWN" if portlnd1=="OTHER DUKES" & permit==231296 & tripid==2856454 & dbyear<=2014;


replace written_port="POINT LOOKOUT" if portlnd1=="OTHER NY" & permit==242545  & dbyear<=2014;/**got this from code above, 
	so as to not deal with the Long Island entries in the communities table***********/

/*Geret's corrections start here*/
*RI;
replace written_port="SAKONNET POINT" if inlist(permit,121749) & written_port == "" & inlist(tripid,2521161,2521170) ;
replace written_port="SAKONNET" if inlist(permit,210643) & written_port == "" & inlist(dbyear, 2009) ;
replace written_port = "OLD HARBOR" if inlist(permit,146744) & written_port == "" & inlist(portlnd1,"OTHER WASHINGTON(COUNTY)","OTHER MAINE") & inlist(dbyear,2010,2007);
replace state1="RI" if inlist(permit,146744) & state1 == "ME" & inlist(dbyear,2010,2007) & inlist(written_port,"OLD HARBOR");

*MA;
replace written_port = "PIGEON COVE" if inlist(permit,148853) & written_port == "" & inlist(dbyear,2010);
replace written_port="MENEMSHA" if inlist(permit,123972, 221217) & written_port == "" & inlist(tripid,3458684, 3335706, 3678567) ;
replace written_port = "SESUIT HARBOR" if inlist(permit,231435) & written_port == "" & inlist(portlnd1,"OTHER MASSACHUSETTS") & inlist(dbyear,2008);

*ME;
replace written_port="JONESPORT" if inlist(permit,126081) & written_port == "" & inlist(serial_num,"11505851","11505852") ;
replace state1="ME" if inlist(permit,126081) & state1 == "NY" & written_port == "JONESPORT" ;
replace written_port = "SWANS ISLAND" if inlist(permit,223572,233295) & written_port == "" & inlist(portlnd1,"OTHER HANCOCK") & inlist(dbyear, 2007,2008,2009,2010,2011);

*NY;
replace written_port="EAST HAMPTON" if inlist(permit,146716) & written_port == "" & portlnd1 == "OTHER SUFFOLK" & dbyear ==  2005;
replace written_port="HAMPTON BAYS" if inlist(permit,146737) & written_port == "" & portlnd1 == "OTHER WASHINGTON(COUNTY)" & inlist(dbyear,2010,2011);
replace written_port = "EASTPORT" if inlist(permit,148172) & written_port == "" & inlist(portlnd1,"OTHER SUFFOLK") & inlist(dbyear,2014);
replace written_port = "NEW YORK" if inlist(permit,240192) & written_port == "" & inlist(portlnd1,"OTHER NY") & inlist(dbyear,2012);
replace written_port = "WEST SAYVILLE" if inlist(permit,241161) & written_port == "" & inlist(serial_num,"10775466") & inlist(dbyear,2007);
replace written_port = "SAYVILLE" if inlist(permit,241161) & written_port == "" & inlist(portlnd1,"OTHER SUFFOLK") & inlist(dbyear,2008,2012,2013,2014);

*NJ;
replace written_port = "BIDWELL CREEK" if inlist(permit,147950,146576) & written_port == "" & inlist(portlnd1,"OTHER CAPE MAY") & inlist(dbyear,2007);
replace written_port = "BIDWELL CREEK" if inlist(permit,147957) & written_port == "" & inlist(portlnd1,"OTHER ACCOMACK") & inlist(dbyear,2009,2010);
replace written_port = "POINT PLEASANT" if inlist(permit,149517,148080,148280) & written_port == "" & inlist(portlnd1,"OTHER OCEAN") & inlist(dbyear,2010,2009);
replace written_port = "BELFORD" if inlist(permit,230248,240195) & written_port == "" & inlist(portlnd1,"OTHER MASSACHUSETTS") & inlist(dbyear,2009,2008);
replace state1 = "NJ" if inlist(permit,230248) & written_port == "BELFORD" & inlist(portlnd1,"OTHER MASSACHUSETTS") & inlist(dbyear,2009);
replace written_port = "OCEANPORT" if inlist(permit,330810) & written_port == "" & inlist(portlnd1,"OTHER MONMOUTH") & inlist(dbyear,2015);
replace written_port="BARNEGAT" if permit==251212 & inlist(tripid,4760523, 4766818) & dbyear==2015;

*VA;
replace written_port = "VIRGINIA BEACH" if inlist(permit,146925) & inlist(serial_num, "11759267","12287768") & written_port == "" & inlist(dbyear,2011, 2014);
replace written_port = "MATHEWS" if inlist(permit,146925) & inlist(serial_num, "12287767","12287769","12287765","12287766") & written_port == "" & inlist(dbyear,2014);
replace state1="VA" if inlist(permit,146925) & inlist(written_port,"VIRGINIA BEACH") & inlist(dbyear,2014);
replace written_port = "PERRIN RIVER" if inlist(permit,147377) & written_port == "" & inlist(portlnd1,"OTHER VIRGINIA") & inlist(dbyear,2009);
replace written_port = "BATH" if inlist(permit,221379) & written_port == "" & inlist(portlnd1,"OTHER WASHINGTON") & inlist(dbyear, 2007);

*NC;
replace written_port = "SOUTHPORT" if inlist(permit,146821) & written_port == "" & inlist(portlnd1,"OTHER BRUNSWICK") & inlist(dbyear,2007);
replace written_port = "ENGELHARD" if inlist(permit,242545) & written_port == "" & inlist(portlnd1,"OTHER NY") & inlist(dbyear,2007);
replace state1 = "NC" if inlist(permit,242545) & written_port == "" & inlist(written_port,"ENGELHARD") & inlist(dbyear,2007);
replace written_port = "ENGELHARD" if inlist(permit,242545) & written_port == "" & inlist(portlnd1,"OTHER NY") & inlist(dbyear,2007);
replace written_port = "BATH" if inlist(permit,24917) & written_port == "" & inlist(portlnd1,"OTHER BEAUFORT(COUNTY)") & inlist(dbyear, 2009, 2010);

*OTHER;
replace written_port="SOMERS POINT" if inlist(permit,130806) & written_port == "" & inlist(serial_num,"10529327","10529328","10529329","10529330","10529331","10529332","10529333","10529334","10529335") ;
replace written_port="SOMERS POINT" if inlist(permit,130806) & written_port == "" & inlist(serial_num,"10529336","10529337","10529338","10794572") ;















rename written_port corrected_port;
rename state1 corrected_state;

gen source="scallop";
save `scallopfixer1', replace ;
append using `portfixer1';

keep permit tripid dbyear portlnd1 corrected_port corrected_state;





/* more corrections Min-Yang 3/23/2016 */
replace corrected_port="STONY BROOK" if permit==148419 & inlist(tripid,1453571, 1453575,1453583,1652420,1652423,1652425,1750842);
replace corrected_port="STONINGTON" if permit==117930 & inlist(tripid,1291234, 1291236,1291238,1301119,1301132, 1378595,1378597,1378607,1378610,1378616,1378618,1378622,1404261,1404262,1404263,1404264,1404265,1404266,1414631,1414633,1414641,1617027,1617028,1617032,1640613,1640621,1761203,1761204,1761205,1761207);
replace corrected_state="CT" if permit==117930 & inlist(tripid,1291234, 1291236,1291238,1301119,1301132,1378595,1378597,1378607,1378610,1378616,1378618,1378622,1404261,1404262,1404263,1404264,1404265,1404266,1414631,1414633,1414641,1617027,1617028,1617032,1640613,1640621,1761203,1761204,1761205,1761207);


replace corrected_port="MARTHAS VINEYARD" if permit==128321 & inlist(tripid,720374,720377);

replace corrected_port="PEMBROKE" if permit==144999 & inlist(tripid,1737554);
replace corrected_port="DOVER" if permit==142772 & inlist(tripid,1793019, 1803578);

replace corrected_port="POINT LOOKOUT" if permit==146776 & inlist(tripid,998562, 1098903, 1098904);
replace corrected_port="POINT LOOKOUT" if permit==148088 & inlist(tripid,1293048, 1293385,1486142);
replace corrected_port="SOMERS POINT" if permit==146839 & inlist(tripid,1042628, 1071416,1158197,1158202, 1158324,1158325,1158327,1158650 );

replace corrected_port="HEISLERVILLE" if permit==148329 & inlist(tripid,1627516, 1627517,1627518,1629899);
replace corrected_port="SOMERS POINT" if permit== 148594 & inlist(tripid,1539730);
replace corrected_port="NEWBURY" if permit== 148867 & inlist(tripid,1656880,1656910);
replace corrected_port="MATHEWS" if permit== 149138 & inlist(tripid,1790694);

replace corrected_port="LONG BEACH" if permit== 149254 & inlist(tripid,2219299);
replace corrected_port="SWAMPSCOTT" if permit== 211573 & inlist(tripid,1940893);
replace corrected_port="SHARPTOWN" if permit== 211840 & inlist(tripid,882300,883360,1064347,1064349,1064351,1064352,1064353,1064354,1064943,1072309,1072320,1072326,1088406,1088513,1090111,1240936,1414673);

replace corrected_port="REHOBOTH" if permit== 213054 & inlist(tripid,1754719);
replace corrected_port="REHOBOTH" if permit== 213214 & inlist(tripid,2313112);
replace corrected_port="REHOBOTH" if permit== 213539 & inlist(tripid,506569);

replace corrected_port="REHOBOTH" if permit== 220186 & inlist(tripid,271161,414771,414804,414806,414810,414815,427832,427834,427844,427850,427852,455166,455170,511969,511971,524331,524334,550732,550733,550735,550740,583178,619875,619880,619881,633080,633088,633099,633108,633113,702414,702415, 761884,761897,761900,761904,761907,761910,784700,784797,812782,812785,812792,812794,812796,812798,830487,948222);
replace corrected_port="MARTHAS VINEYARD" if permit== 220438 & inlist(tripid,742341,742345);

replace corrected_port="MATHEWS" if permit== 223372 & inlist(tripid,1087387,1108387,1108388,1108389,1108391,1108392,1108393,1108395,1108398,1111425,1172967);

replace corrected_port="BELLE HAVEN" if permit== 223384 & inlist(tripid,1104459,1116736, 1117426,1166514,1319695,1319697,1334588,1340400,1340405,1340407,1340410,1340412,1340414,1340416,1340429,1340432,1341157,1365129,1544515,1544922,1544926,1544928,1544929,1544930,1544931,1564519,1564535);

replace corrected_port="ONANCOCK" if permit== 223406 & inlist(tripid,961778, 961780,961782,961783,961785,961788,961792,961794,961795, 961798,1177267,1177268, 1177271,1177274, 1177275,1177278, 1177281,1182719);

replace corrected_port="HARPSWELL" if permit== 233254  & inlist(tripid,1395768);

replace corrected_port="SANDWICH" if permit== 241110  & inlist(tripid,999918,999923,999926,999928,999931,999939,999941,999947,1023829,1023833,1023836,1023840,1023843,1023849,1023852,1043852,1062740,1062741);
replace corrected_port="ONANCOCK" if permit== 242546 & inlist(tripid,1480758,1480772,1480775,1480780,1480784,1480786,1480788,1480789,1480790,1480792,1480793,1480795,1480798,1480805,1480807,1480811,1527385);
replace corrected_port="MARTHAS VINEYARD" if permit== 250274 & inlist(tripid,1346564);
replace corrected_port="MILFORD" if permit== 250872 & inlist(tripid,404064,405154,405179);
replace corrected_port="BARNEGAT" if permit== 251212 & inlist(tripid,4823796);

replace corrected_port="MARTHAS VINEYARD" if permit== 310274 & inlist(tripid,540549, 540552,540850);

replace corrected_port="HAMPTON BAYS" if permit== 310459 & inlist(tripid,1866044);
replace corrected_port="BEAUFORT" if permit== 310562 & inlist(tripid,1505004);

replace corrected_state="NC" if permit== 310562 & inlist(tripid,1505004);
replace corrected_port="POINT JUDITH" if permit== 320338 & inlist(tripid,2329533);
replace corrected_port="NEWARK" if permit== 320657 & inlist(tripid,1576063);

		replace corrected_port="HAMPTON" if permit== 320932 & inlist(tripid,1771428);
		replace corrected_state="VA" if permit== 320932 & inlist(tripid,1771428);
replace corrected_port="HAMPTON BAYS" if permit== 321085 & inlist(tripid,1572773);

replace corrected_port="MARTHAS VINEYARD" if permit== 330198 & inlist(tripid,1302688);
replace corrected_port="LONG BEACH" if permit== 330388 & inlist(tripid,337270);
	

replace corrected_port="POINT LOOKOUT" if permit== 330390 & inlist(tripid,473409,473410,473412,473414,473415,473416,473417,478391,478392,478393,478394);
	
replace corrected_port="YORKTOWN" if permit== 330402 & inlist(tripid,2169545);

replace corrected_port="POINT LOOKOUT" if permit== 330529 & inlist(tripid,411431,745796,745813);

replace corrected_port="NEWPORT NEWS" if permit== 330620 & inlist(tripid,1740322,1789964,1804710,2290558, 2297773,2311327);
replace corrected_port="DORCHESTER" if permit== 330719 & inlist(tripid,1687614,1687616,1694821,1694826);
replace corrected_port="NEWPORT NEWS" if permit== 330727 & inlist(tripid,1446564,1446566,1446567 );
replace corrected_port="COLD SPRING" if permit== 330886 & inlist(tripid,4693695,4710115 );

replace corrected_port="HAMPTON BAYS" if permit== 800331 & inlist(tripid,1828051);
replace corrected_port="SAG HARBOR" if permit== 800331 & inlist(tripid,1920825,1920827,1920828,1920831,1920833,1920835,1920837,1920839,1920841,1920842,1920844,1920845,1920847,1920849,1920850,1920852,1920853);
replace corrected_port="JAMESPORT" if permit== 800379 & inlist(tripid,1575129,1575135,1575137,1696630,1696631,1696633,1696634);
replace corrected_port="SAYVILLE" if permit== 800392 & inlist(tripid,1613229,1869572,2216976,2216978,2216979,2219286,2241644,2241655,2241676,2242395,2242397,2242399,2280553);

replace corrected_port="HAMPTON" if permit== 330452 & tripid>=33045214121316 & portlnd1=="OTHER CITY OF HAMPTON";
replace corrected_port="HAMPTON" if permit== 330521  & tripid>=33052115111115 & portlnd1=="OTHER CITY OF HAMPTON";

replace corrected_port="CAPE MAY" if permit==410173   & tripid>=41017315050915   & portlnd1=="OTHER CAPE MAY";

replace corrected_port="KITTERY" if permit==128337   & tripid==2269996 ;

replace corrected_port="INWOOD" if permit==148088   & tripid==1293099 ;
replace corrected_port="GOOSE CREEK" if permit==223461   & tripid==1301644;
replace corrected_port="HARBORTON" if permit==233181   & inlist(tripid,1136579,1301644,1136585,1136588,1187384);
replace corrected_port="HAMPTON BAY" if permit==250175   & inlist(tripid,2248301);
replace corrected_port="MONTAUK" if permit==310153 &   portlnd1=="OTHER BRONX" & inlist(tripid,4812913,4812914,4812915,4812916,4812917,4812918,4812919,4812920,4812921,4812922,4812924,4813380,4813381,4813382,4813386,4813387,4813390,4817004,4817050,4822088,4822091,4836068,4836069,4836070,4836072,4836074,4836315,4836317,4836323,4836455) ;
replace corrected_port="CAPE MAY" if permit==320716 & inlist(tripid,1708398);
replace corrected_state="NJ" if permit==320716& inlist(tripid,1708398);
replace corrected_port="ATLANTIC CITY" if permit==330592 & inlist(tripid,2255429);
replace corrected_port="PORT JEFFERSON" if permit==800093 & inlist(tripid,670850);

replace corrected_port="HAMPTON BAYS" if permit==800328 & inlist(tripid,1753740);

replace corrected_port="MOUNT SINAI" if permit==800355 & inlist(tripid,2266096,2290545,2290548);
replace corrected_port="MONTAUK" if permit==800389 & inlist(tripid,1696630,1696631,1696633,1696634);
replace corrected_port="SHINNECOCK" if permit==800422 & inlist(tripid,687440);

replace corrected_port="AMAGANSETT" if permit==800877 & inlist(tripid,2281351);




/*
replace corrected_port="XXX" if permit== PPPPP & inlist(tripid,TTTTT);



*/







duplicates drop;
compress;

/*logic check that there are corrected_ports with zero length 
gen lp=length(corrected_port);
quietly summ lp;
assert r(min)>0;
drop lp;
*/
keep permit tripid dbyear corrected_port corrected_state;
quietly duplicates tag permit tripid dbyear, gen(dup1);
drop if dup1 ~= 0 & corrected_port == "";
drop dup1;
save "${data_intermediate}/final_all_port_corrections.dta", replace ;


/*

append using cleaned_scal_ports.dta;
*/





use `portfixer1.dta', clear;


/*
merge m:1 portlnd1 state1 using "communities_cleaned2.dta", keep(1 3);
drop  placenm placest areakey hcounty lat lon statefp countyfp cousubfp retrieved _merge ;
duplicates drop (tripid dbyear), force ;
save "final_all_port_corrections.dta", replace ;
*/





