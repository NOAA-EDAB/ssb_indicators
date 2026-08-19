/* Spelling fixer
This .do file fixes any obvious spelling mistakes in the PORTLND1 and state1 columns.  
The reason for fixing this is so we can eventually use PORTLND1 and state1 to merge to the port community dataset
This spelling fixer corrects a very large number of mistakes that are in VESLOG.

 */

#delimit;
 replace portlnd1=ltrim(rtrim(itrim(portlnd1)));

replace portlnd1="CHESAPEAKE" if portlnd1=="CHESAPEAKE BAY" & state1=="VA" ;
replace portlnd1="SEAFORD" if portlnd1=="CITY OF SEAFORD" & state1=="VA" ;
replace portlnd1="COLD SPRING" if portlnd1=="COLD SPRING CAPE MAY" & state1=="NJ" ;
replace portlnd1="DEER ISLE" if (portlnd1=="CANARY COVE" | portlnd1=="CONORY COVE" | portlnd1=="CONARY COVE") ;
replace portlnd1="POINT PLEASANT" if portlnd1=="DELAWARE BAY" & state1=="DE" ;
replace portlnd1="FIRE ISLAND INLET" if portlnd1=="FIRE ISLAND" & state1=="NY" ;
replace portlnd1="HAMPTON BAYS" if portlnd1=="HAMPTON BAY" & state1=="NY" ;
replace portlnd1="HARWICH PORT" if portlnd1=="HARWICHPORT" & state1=="MA" ;
replace portlnd1="PEMBROKE" if portlnd1=="PEMPBROKE" & state1=="MA" ;
replace portlnd1="ROQUE BLUFFS" if portlnd1=="ROGUE BLUFFS" & state1=="ME" ;
replace portlnd1="SEAFORD" if portlnd1=="SEFORD" & state1=="VA" ;
replace portlnd1="DYER BAY" if portlnd1=="DYERS BAY"  ;
replace portlnd1="NORTHEAST HARBOR" if portlnd1=="NORTHWEST HARBOR" ;
replace portlnd1="SPRUCE HEAD" if portlnd1=="SPRUCEHEAD" & state1=="ME" ;
replace portlnd1="STEUBEN" if portlnd1=="STUEBEN" & state1=="ME" ;
replace portlnd1="BARNEGAT" if portlnd1=="LONG BEACH" & state1=="NJ" ;
replace portlnd1="BARNEGAT" if strmatch(portlnd1,"BARNEGAT*")==1 & state1=="NJ";
replace state1="NJ" if portlnd1=="POINT PLEASANT";

replace portlnd1="ROBBINSTON" if (portlnd1=="BACK RIVER" & state1=="ME") ;
replace portlnd1="BALDWIN" if (portlnd1=="BALDWAIN" & state1=="NY") ;
replace portlnd1="BARRINGTON" if (portlnd1=="BARINGTON" & state1=="RI") ;
replace state1="NJ" if (portlnd1=="BELFORD" & state1=="MA");
replace portlnd1="CAPTREE" if (portlnd1=="CAPTURE" & state1=="NY");
replace portlnd1="BLOCK ISLAND" if portlnd1=="BLACK ISLAND" & state1=="RI" ;
replace state1="CT" if (portlnd1=="STONINGTON" & state1=="RI") ;
replace portlnd1="EAST ROCKAWAY" if (portlnd1=="DEBS INLET" | portlnd1=="DEBS ISLAND" | portlnd1=="DEBS ONLET") ;
replace portlnd1="EAST MARION" if portlnd1=="E MARION" ;
replace portlnd1="EAST MORICHES" if portlnd1=="E MORICIA" ;
replace portlnd1="EAST MORICHES" if portlnd1=="E MORICHES" ;
replace portlnd1="EAST MORICHES" if portlnd1=="EAST MONIKER" ;
replace portlnd1="EAST MORICHES" if portlnd1=="EAST MORICH" ;
replace portlnd1="EAST MORICHES" if portlnd1=="EAST MORIDSA" ;
replace portlnd1="EAST MORICHES" if portlnd1=="EAST NORWICH" ;
replace portlnd1="THREE MILE HARBOR" if portlnd1=="EAST HARBOR" & state1=="NY";
replace portlnd1="EAST MARION" if (portlnd1=="EAST MARIAM" | portlnd1== "EAST MARIAN");
replace state1="NJ" if (portlnd1=="ELIZABETH" & state1=="NY");
replace portlnd1="GALILEE" if (portlnd1=="GALILLEE" |  portlnd1=="GALLILEE");
replace portlnd1="GAY HEAD (AQUINNAH)" if portlnd1=="GAY HEAD/AQUINNAH" ;
replace portlnd1="CHINCOTEAGUE" if portlnd1=="GOOSECREEK" ;
replace portlnd1="GOSHEN" if state1=="NJ" & (portlnd1=="GOSLAN" | portlnd1=="GOSLEN");
replace portlnd1="HEISLERVILLE" if state1=="NJ" & (portlnd1=="HEISCERVILLE" | portlnd1=="HEISLERVICCE" | portlnd1=="HEISSLERVILLE" | portlnd1=="HIESLERVILLE");
replace portlnd1="MATTITUCK" if (portlnd1=="MARATOCH" | portlnd1=="MARATOCK" | portlnd1=="MATITUCK");
replace portlnd1="AMAGANSETT" if (portlnd1=="AMAG" & state1=="NY") ;
replace portlnd1="AMAGANSETT" if (portlnd1=="AMAC" & state1=="NY") ;
replace portlnd1="ACCOMAC" if portlnd1=="OCCOHANNOCK CREEK" ;
replace portlnd1="ACCOMAC" if portlnd1=="OCCOHANNOCK CREEK" ;
replace portlnd1="WESTERLY" if  portlnd1=="WESTERLEY";
replace portlnd1="WEST SAYVILLE" if  (portlnd1=="W. SAYVILLE" | portlnd1=="W SAYVILLE");
replace portlnd1="WEST BABYLON" if  portlnd1=="W. BABYLON";

replace portlnd1="OAKDALE" if portlnd1=="OAKLAKE";
replace portlnd1="OAKDALE" if portlnd1=="OKADALE";


replace portlnd1="MASTIC" if portlnd1=="MASTIE";
replace portlnd1="MATTS LANDING" if portlnd1=="MATT'S LANDING";
replace portlnd1="MELVILLE" if portlnd1=="MELLEVILLE" & state1=="RI";
replace portlnd1="MOUNT SINAI" if (portlnd1=="MT SINAI" | portlnd1=="MT. SINAI") ;

replace portlnd1="TUCKERTON" if portlnd1=="TUCKERTOWN" & state1=="NJ" ;
replace portlnd1="STONY BROOK" if portlnd1=="STONYBROOK" & state1=="NY" ;
replace portlnd1="STONINGTON" if (portlnd1=="STONNINGTON" & state1=="CT") ;
replace portlnd1="SOUTHAMPTON" if (portlnd1=="SOUTHHAMPTON" | portlnd1=="SOUTH HAMPTON") ;
replace state1="NY" if portlnd1=="STATEN ISLAND" ;
replace portlnd1="SAKONNET" if (portlnd1=="SOKONNET" | portlnd1=="SAKONNETTE POINT");
replace portlnd1="SMITHTOWN" if portlnd1=="SMITHTOWN BAY" ;
replace portlnd1="SMITH POINT (MD)" if portlnd1=="SMITH POINT MD" ;
replace portlnd1="SETAUKET" if (portlnd1=="SETAUKET LONG ISLAND" | portlnd1=="SETAUKET LI" | portlnd1=="SETAUCKET");
replace state1="NY" if portlnd1=="SETAUKET" ;
replace portlnd1="POINT PLEASANT" if portlnd1=="PT. PLEASANT" ;
replace portlnd1="POINT JUDITH" if portlnd1=="PT JUDITH" ;
replace portlnd1="PIGEON COVE" if portlnd1=="PIGEON CDOVE" ;
replace portlnd1="NANTICOKE" if portlnd1=="NANTITIKE" ;
replace portlnd1="YARMOUTH" if (portlnd1=="PARKER RIVER" & state1=="MA");

replace portlnd1="WESTERLY" if (portlnd1=="AVONDALE" & state1=="RI") ;
replace portlnd1="ISLAND PARK" if portlnd1=="ISLAND BANK"  ;
replace portlnd1="OCEANPORT" if portlnd1=="OCEAN PORT";

replace portlnd1="NEWPORT NEWS" if portlnd1=="SMALL BOAT HARBOR" ;
replace portlnd1="REHOBOTH" if (portlnd1=="REHOBETH" | portlnd1=="ROHOBETH") & state1=="DE";
replace portlnd1="CUNDYS HARBOR" if portlnd1=="QUAHOG BAY" & state1=="ME";


replace portlnd1="BEAUFORT" if portlnd1=="BEAUMONT" & state1=="NY";
replace state1="NC" if portlnd1=="BEAUFORT" & state1=="NY";

replace state1="NC" if portlnd1=="BROAD CREEK" & state1=="MD";


