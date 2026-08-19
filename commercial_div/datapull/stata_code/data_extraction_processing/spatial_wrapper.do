#delimit;
clear;
set more off;
pause off;

/*******************************************************************************************************/
/********************************************************************************************************/
/****Please see the project 
https://github.com/minyanglee/spacepanels
and the readme at

https://github.com/minyanglee/spacepanels/blob/master/README.md





*/





/*******************************************************************************************************/
/*******************************************************************************************************/


/* GLOBALS to set up YEARS and OTHER STUFF  
These will get passed to the other do files.*/
global firstyr=1996; 
global lastyr=2024;
 

global firstdets=$firstyr; 
global lastdets=2003; 



global firstders=2004; 
global lastders=$lastyr; 





global monk_prefix monkprice;

global scal_prefix SCALpricing;
global allprefix ALLpricing;
timer clear;
timer on 1;
/**************************************************************************************************************/
/*******This .do includes TWO new do files, "%%_with_dealnum.do", that are encoded to extract dealnum for confidentiality purposes*******/
/**************************************************************************************************************/




/*Wrong_portlnd1_all_corrections1.do is the do file that corrects any "wrong" portlnd1 in our VTR data.  It ONLY examines VTRs for the FED94 species.  The corrected is at the "tripid" but some of the code used
to correct that data cleans it using permit or serial number.  The code is a fragile - take care in re-using it.  */

do "${extraction_code}\wrong_portlnd1_all_corrections1.do" ;

/*pulls out data for scallops 
do "scallop_data_extraction_and_cleaning.do" ;
*/

/*Extracts surfclam and ocean quahog data */

do "${extraction_code}\sfclam.do";

/* this file just does the scallop revenues 
do "construct_revenues.do";
*/
do "${extraction_code}\allspecies_prices.do" ;
do "${extraction_code}\monkfish_prices.do";



do "${extraction_code}\allspecies.do" ; 

/*NOTE, THIS PARTICULAR STEP NEEDS SOME MANUAL INTERVENTION AND WORK IN GIS 
do "/home/mlee/Documents/projects/spacepanels/port data/arc_to_stata.do";
/*note the coordinate data is stored in universe_data.dta and universe_coordinates.dta 

updated through here*/
*/

do "${extraction_code}\sfclam_areas.do";

do "${processing_code}\geret_area_extra.do";

do "${processing_code}\geret_area_extra2.do";
/* do "${processing_code}\setup_scallop_for_indices_by_plancat_v2.do"; */

timer off 1;
timer list;
do "${processing_code}\just_ports.do";



do "${processing_code}\tripid_geoid.do";



/* cleanup extra or unnecessary files*/

#delimit ;
shell rm ${data_intermediate}\$monk_prefix*.dta;
shell rm ${data_intermediate}\$allprefix*.dta;
shell rm ${data_intermediate}\scal_tripid_permits.dta;
/*
shell rm sfclam96_2013.dta;*/



