version 17.0

#delimit ;


/*
global user minyang;
or 
global user minyangWin;
or
global user cameron;
global user geret;
*/

if strmatch("$user","geret"){;
global my_projdir "X:/gdepiper/Research/READ-SSB-Lee-spacepanels";
};

if strmatch("$user","minyang"){;
};
if strmatch("$user","minyangWin"){;
global my_projdir "C:/Users/Min-Yang.Lee/Documents/spacepanels";

};

if strmatch("$user","cameron"){;
global my_projdir "U:/incomemobility";
};
cap mkdir $my_projdir;

global my_codedir "${my_projdir}/stata_code";
cap mkdir $my_codedir;

global my_adopath "${my_codedir}/spacepanels_ado";
cap mkdir $my_adopath;


global extract_process "${my_codedir}/data_extraction_processing";
cap mkdir $extract_process;

global extraction_code "${my_codedir}/data_extraction_processing/extraction";
cap mkdir $extraction_code;

global processing_code "${my_codedir}/data_extraction_processing/processing";
cap mkdir $processing_code;

global analysis_code "${my_codedir}/analysis";
cap mkdir $analysis_code;


/* setup data folder */
global my_datadir "${my_projdir}/data_folder";
cap mkdir $my_datadir;


global data_raw "${my_datadir}/raw";
cap mkdir $data_raw;



global data_internal "${my_datadir}/internal";
cap mkdir $data_internal;

global data_external "${my_datadir}/external";
cap mkdir $data_external;

global data_main "${my_datadir}/main";
cap mkdir $data_main;

global data_intermediate "${my_datadir}/intermediate";
cap mkdir $data_intermediate;

global trade_clean "${data_intermediate}/intra_clean";
cap mkdir $trade_clean;

/* don't need this one 
global spacepanels "/home/mlee/Documents/projects/spacepanels/scallop/spatial_project_11182019";
*/

/* setup results, tables, images folders */

global my_results "${my_projdir}/results";
cap mkdir $my_results;



global my_tables "${my_projdir}/tables";
cap mkdir $my_tables;


/* setup images folders */

global my_images "${my_projdir}/images";
cap mkdir $my_images;


global exploratory "${my_images}/exploratory";
cap mkdir $exploratory;
