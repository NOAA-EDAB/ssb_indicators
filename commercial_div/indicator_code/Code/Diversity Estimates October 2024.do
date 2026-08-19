clear
do "C:\Users\geret.depiper\Documents\Stata do\ORACLE_CONNECT"
macro list _all
odbc load, exec("select distinct ap_year,vp_num, hull_id, len, crew, gtons, ntons, vhp, blt from NEFSC_GARFO.permit_vps_vessel ;") $oracle_cxn
rename HULL_ID HULLNUM
rename (VP_NUM AP_YEAR) (permit year)
destring BLT NTONS LEN CREW VHP, replace
collapse (mean) NTONS BLT LEN CREW GTONS VHP, by(year permit)
save "F:\ESRs\ESR2025\Data\vesselsALL2025", replace


#delimit;
clear;
do "C:\Users\Geret.Depiper\Documents\Stata do\ORACLE_CONNECT";
cd "F:\ESRs\ESR2025\Data" ;
set mem 800m;
set more off; 
global firstyr =1996; 
global lastyr =2023; 
global firstders =$firstyr; 
global lastders =$lastyr; 
global scal_prefix SCALpricing;
global allprefix  ALLpricing;
timer clear;
timer on 1;

	tempfile new;
	local NEWfiles `"`NEWfiles'"`new'" "'  ;
	clear;
	odbc load, exec("select unique s.kept as qtykept, s.discarded as qtydisc, t.VESSEL_PERMIT_NUM as permit,t.docid as tripid,
	g.gearcode, extract(year from t.DATE_SAIL) as year,
	extract(year from t.Date_land) as dbyear 
	from NEFSC_GARFO.catch s,  NEFSC_GARFO.document t,  NEFSC_GARFO.images g 
		where t.docid = g.docid and g.imgid=s.imgid and (t.tripcatg=1 or t.tripcatg=4);")  $oracle_cxn;                    
	quietly save `new';

dsconcat `NEWfiles';
	renvarlab, lower;
	destring, replace;
	compress;
	drop dbyear;
	 duplicates drop;
	 replace qtykept = 0 if qtykept == .;
	 replace qtydisc = 0 if qtydisc == .;
	 gen double qty = qtykept+qtydisc;
	 collapse (sum) qty, by(year tripid permit gearcode);
	bysort year tripid permit: egen double q_max = max(qty);
	drop if q_max ~= qty;
	duplicates drop year tripid permit, force;
save "veslog_gear_2025.dta", replace;


set more off
cd "F:\ESRs\ESR2025\Data"
use "SOE_diversityrevenuedata_2025", clear
drop _merge*
merge m:1 permit tripid year using "veslog_gear_2025.dta", update
drop if _merge == 2
drop _merge
merge m:1 permit year using "F:\ESRs\ESR2025\Data\vesselsALL2025"
drop if _merge == 2
drop _merge
gen MAFMC = 0
	replace MAFMC = 1 if inlist(species_group, "DGSP","MONK")
	replace MAFMC = 1 if inlist(species_group, "CLQU","CLSU","TILE","BSBFLK","SCUP","BSCUP","LOL","ILX")
	replace MAFMC = 1 if inlist(myspp,335,121,329,23,51,212,352,446,748)
	replace MAFMC = 1 if inlist(myspp,754,755,801,802)
gen NEFMC = 0
	replace NEFMC = 1 if inlist(species_group, "SKATE","SCAL", "FLYT")
	replace NEFMC = 1 if inlist(myspp, 81, 120, 122, 123, 147, 269, 153, 124, 240)
	replace NEFMC = 1 if inlist(myspp, 82, 125, 154, 159, 250, 152, 155, 507, 508)
	replace NEFMC = 1 if inlist(myspp, 509, 710)
	bysort permit year: egen MAFMCPermit = sum(MAFMC)
	bysort permit year: egen NEFMCPermit = sum(NEFMC)
	rename (LEN)  (len)
gen lencat = ""
	replace  lencat = "Less than 30'" if len < 30 
	replace  lencat = "30 to < 50" if len >= 30 & len < 50
	replace  lencat = "50 to < 75'" if len >= 50 & len < 75
	replace  lencat = "75 and above" if len >= 75
replace gearcode = "DRC" if inlist(myspp, 754,769) & gearcode == ""

gen gearcode2 = "OTH"
	replace gearcode2 = "Scallop Dredge" if inlist(gearcode, "DRS","DSC","DTC","DTS")
	replace gearcode2 = "Other Dredge" if inlist(gearcode, "DRM","DRO","DRU")
	replace gearcode2 = "Gillnet" if inlist(gearcode,"GND","GNT","GNO","GNR","GNS")
	replace gearcode2 = "Hand" if inlist(gearcode,"HND")
	replace gearcode2 = "Longline" if inlist(gearcode,"LLB","LLP")
	replace gearcode2 = "Bottom Trawl" if inlist(gearcode, "OTB","OTF","OTO","OTC","OTS","OHS","OTR","OTT","PTB")
	replace gearcode2 = "Midwater Trawl" if inlist(gearcode,"OTM","PTM")
	replace gearcode2 = "Pot" if inlist(gearcode,"PTL","PTW","PTC","PTE","PTF","PTH","PTL","PTO")
	replace gearcode2 = "Pot" if inlist(gearcode,"PTS","PTX")
	replace gearcode2 = "Purse Seine" if inlist(gearcode,"PUR")
	replace gearcode2 = "Clam Dredge" if inlist(gearcode,"DRC")
**************************************************************
preserve
	rename real_revenue R_REV
	collapse (sum) R_REV, by(year permit gearcode2)
	bysort year permit: egen double r_max = max(R_REV)
	drop if r_max ~= R_REV
	drop r_max R_REV
	rename gearcode2 majgear
	duplicates drop
	drop if permit == 330845 & year == 2014 & majgear ~= "DRS"
	drop if permit == 330898 & year == 2014 & majgear ~= "DRS"
	drop if permit == 410618 & year == 2014 & majgear ~= "DRS"
	drop if permit == 221567 & year == 2011 & majgear == "OTH"
	tempfile mgear
	save "F:\ESRs\ESR2025\Data\majorgear", replace
restore
*************************************************************
merge m:1 year permit using "F:\ESRs\ESR2025\Data\majorgear"
	drop gearcode2
	gen mrev = real_revenue/1000000
	gen State = state1
		replace State = "Other" if inlist(State,"CN","FL" "PR","GA","DE","SC","NH","ME")
	gen Species = ""
		replace Species = "Bluefish" if myspp == 23
		replace Species = "Tilefish" if myspp == 446
		replace Species = "O. Quahog" if myspp == 754
		replace Species = "S. Clam" if myspp == 769
		replace Species = "Monkfish" if inlist(myspp, 12, 11)
		replace Species = "B. Seabass" if myspp == 335
		replace Species = "Butterfish" if myspp == 51
		replace Species = "S. Dogfish" if myspp == 352
		replace Species = "Scup" if myspp == 329
		replace Species = "Illex" if myspp == 802
		replace Species = "Loligo" if myspp == 801
		replace Species = "A. Mackerel" if myspp == 212
		replace Species = "S. Flounder" if myspp == 121

	save "F:\ESRs\ESR2025\Data\FinalMAFMCNEFMC_2025", replace
	
cd "F:\ESRs\ESR2025\Data"
	use "F:\ESRs\ESR2025\Data\FinalMAFMCNEFMC_2025", clear
	rename real_revenue R_REV
	drop if year > 2023
preserve
	drop if MAFMCPermit == 0 | MAFMCPermit == .
	replace R_REV = 0 if R_REV == .
	collapse (sum) R_REV, by(permit year species_group)
	bysort permit year: egen trev = sum(R_REV)
	bysort permit year: egen species_count = count(R_REV)
	gen prev = R_REV/trev
	gen pshannonrev = -prev*ln(prev)
	gen pHHIrev = (100*(prev))^2
	bysort year permit: egen Shannonrev = sum(pshannonrev)
	bysort year permit: gen eShannonrev = exp(Shannonrev)
	bysort year permit: egen HHIrev = sum(pHHIrev)
	drop R_REV prev pshannonrev pHHIrev species_group
	duplicates drop
	collapse (mean) Shannonrev eShannonrev HHIrev, by(year)
	line eShannonrev year, saving(ShannonEffMAFMCpermitrev_2025 , replace) graphregion(fcolor(white) icolor(white)) lwidth(medthick) ytitle("MAFMC" "Effective Shannon Index") 
	gen Region = "MA"
	gen Units = "effective Shannon"
	gen Var = "Permit revenue species diversity"
	rename (year eShannon) (Time Value) 
	export delimited Time Region Value Var Units using "F:\ESRs\ESR2025\Data\MAFMCspeciesdiversity_2025", replace	
restore
preserve
	drop if NEFMCPermit == 0 | NEFMCPermit == .
	replace R_REV = 0 if R_REV == .
	collapse (sum) R_REV, by(permit year species_group)
	bysort permit year: egen trev = sum(R_REV)
	gen prev = R_REV/trev
	gen pshannonrev = -prev*ln(prev)
	gen pHHIrev = (100*(prev))^2
	bysort year permit: egen Shannonrev = sum(pshannonrev)
	bysort year permit: gen eShannonrev = exp(Shannonrev)
	bysort year permit: egen HHIrev = sum(pHHIrev)
	bysort permit year: egen species_count = count(R_REV)
	drop R_REV prev pshannonrev pHHIrev species_group
	duplicates drop
	gen meaneShannonrev = exp(Shannonrev)
	collapse (mean) Shannonrev eShannonrev HHIrev, by(year)
	line eShannonrev year, saving(ShannonEffNEFMCpermitrev_2025 , replace) graphregion(fcolor(white) icolor(white)) lwidth(medthick) ytitle("Effective Shannon Index") 
	gen Region = "NE"
	gen Units = "effective Shannon"
	gen Var = "Permit revenue species diversity"
	rename (year eShannon) (Time Value) 
	export delimited Time Region Value Var Units using "F:\ESRs\ESR2025\Data\NEFMCspeciesdiversity_2025", replace	
restore
preserve
	drop if MAFMCPermit == 0 | MAFMCPermit == .
	replace R_REV = 0 if R_REV == .
	collapse (sum) R_REV, by(lencat majgear year)
	bysort year: egen trev = sum(R_REV)
	gen prev = R_REV/trev
	gen pshannonrev = -prev*ln(prev)
	gen pHHIrev = (100*(prev))^2
	bysort year: egen Shannonrev = sum(pshannonrev)
	bysort year: gen eShannonrev = exp(Shannonrev)
	bysort year: egen HHIrev = sum(pHHIrev)
	bysort year: egen fleet_count = count(R_REV)
	drop R_REV prev pshannonrev pHHIrev lencat majgear
	duplicates drop
	collapse (mean) Shannonrev eShannonrev HHIrev fleet_count, by(year)
	
	line fleet_count year , saving(FleetcountMAFMC_2025, replace) graphregion(fcolor(white) icolor(white)) lwidth(medthick) ytitle("Number of Fleets") 
	line Shannonrev year , saving(ShannonMAFMCfleetrev_2025 , replace) graphregion(fcolor(white) icolor(white)) lwidth(medthick) ytitle("Shannon Index") 
	
	egen meShannon = mean(eShannonrev)
	egen SDeShannon = sd(eShannonrev)
	gen leShannon = meShannon-SDeShannon
	gen ueShannon = meShannon+SDeShannon
	line eShannonrev year, saving(ShannonEffMAFMCfleetrev_2025 , replace) graphregion(fcolor(white) icolor(white)) ytitle("Effective Shannon Index") lwidth(medthick) legend(off)
	gen Region = "MA"
	gen Units = "effective Shannon"
	gen Var = "Fleet diversity in revenue"
	rename (year eShannonrev) (Time Value) 	
	export delimited Time Region Value Var Units using "F:\ESRs\ESR2025\Data\MAFMCfleetdiversity_2025", replace
	replace Units = "number of fleets"
	replace Var = "Fleet count"
	drop Value
	rename (fleet_count) (Value) 
	export delimited Time Region Value Var Units using "F:\ESRs\ESR2025\Data\MAFMCfleetcount_2025", replace
restore
preserve
	drop if NEFMCPermit == 0 | NEFMCPermit == .
	replace R_REV = 0 if R_REV == .
	collapse (sum) R_REV, by(lencat majgear year)
	bysort year: egen trev = sum(R_REV)
	gen prev = R_REV/trev
	gen pshannonrev = -prev*ln(prev)
	gen pHHIrev = (100*(prev))^2
	bysort year: egen Shannonrev = sum(pshannonrev)
	bysort year: gen eShannonrev = exp(Shannonrev)
	bysort year: egen HHIrev = sum(pHHIrev)
	bysort year: egen fleet_count = count(R_REV)
	export delimited using "F:\ESRs\ESR2025\Data\NEFMCfleetdiversity_2025", replace
	drop R_REV prev pshannonrev pHHIrev lencat majgear
	duplicates drop
	collapse (mean) Shannonrev eShannonrev HHIrev fleet_count, by(year)
	line fleet_count year , saving(FleetcountNEFMC_2024, replace) graphregion(fcolor(white) icolor(white)) lwidth(medthick) ytitle("Number of Fleets") 
	line Shannonrev year , saving(ShannonNEFMCfleetrev_2025 , replace) graphregion(fcolor(white) icolor(white)) lwidth(medthick) ytitle("Shannon Index") 
	line eShannonrev year, saving(ShannonEffNEFMCfleetrev_2025 , replace) graphregion(fcolor(white) icolor(white)) ytitle("Effective Shannon Index") lwidth(medthick)
	line HHIrev year, saving(HHINEFMCfleetrev_2025 , replace) graphregion(fcolor(white) icolor(white)) lwidth(medthick)  ytitle("HHI") 
	gen Region = "NE"
	gen Units = "effective Shannon"
	gen Var = "Fleet diversity in revenue"
	rename (year eShannonrev) (Time Value) 
	export delimited Time Region Value Var Units using "F:\ESRs\ESR2025\Data\NEFMCavgfleetdiversity_2025", replace
	replace Units = "number of fleets"
	replace Var = "Fleet count"
	drop Value
	rename (fleet_count) (Value) 
	export delimited Time Region Value Var Units using "F:\ESRs\ESR2025\Data\NEFMCfleetcount_2025", replace
restore

