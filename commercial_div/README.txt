The Fishery_Metadata_Species_Prices\READ-SSB-Lee_spacepanels folder has the primary data pull and QC processes for the data underpinning the diversity indicators. You'll need to change the project_logistics and end year files to be able to pull the data. In the data_extraction_processing

The IEA_Project\ESRs\ESR2026 folder houses the code that creates the indicators themselves. You need to change the years from 2024 to 2025 for next year's indicator run, but otherwise it should run out of the box.

The Fishery_Metadata_Species_Prices\R_Port_of_spacepanels folder has the work I started on porting the code from Stata to R. It runs, but there's definitely something (likely many things) wrong with the code and it doesn't give the same answer as Stata. Sorry I couldn't finalize this code, but it took two weeks just to get it to run from where AI left it.

The 2026 diversity indicators are already processed, and can be found in the   IEA_Project\ESRs\ESR2026\Data\FINAL folder.