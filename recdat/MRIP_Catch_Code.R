#source("C:/Users/geret.depiper/Documents/R/Rec_SOE_filepaths.R")
library(here)
library(haven)
library(plyr)
library(dplyr)
library(tidyr)
library(tidytable)
library(purrr)
library(stringr)
library(survey)
options(scipen=999)
options(survey.lonely.psu = "certainty")
#Current year is not complete nor final, so should be dropped
Incomplete_year=2025

#File paths are set up for container, so ITD needs to map appropriately.

mrip_location <- file.path("home/gdepiper/mrfss/products/mrip_estim/Public_data_cal2018")

Output_location <- file.path("home/gdepiperIEA_Project/Recreational_Indicators")

filelist <- list.files(file.path(mrip_location), 
                       pattern=glob2rx("trip*.sas7bdat"),
                       full.names = TRUE) 
#Removing non-final data
#This list will likely need to change after the next MRIP calibration
filelist <- filelist[!grepl("orig*",filelist)]
filelist <- filelist[!grepl("Copy*",filelist)]
filelist <- filelist[!grepl("trip_1981",filelist)]
filelist <- filelist[!grepl(paste0("trip_",Incomplete_year,sep=""), filelist)]

#Column names are a mix of lowercase and uppercase, so need to standardize
Tripdata <- ldply(filelist, function(x) {
  temp <- read_sas(x)
  names(temp) <- tolower(names(temp))
  return(temp)
})

save(Tripdata, file=file.path(Output_location,"rectrip_2026.Rdata"))

#mode_fx levels
# 1=Man-Made
# 2=Beach/Bank
# 3=Shore
# 4=Headboat
# 5=Charter Boat (sub_reg=6 or 7 & mode_f=7)
# 7=Private/Rental Boat

# mode_test <- Tripdata %>% filter(mode_fx==6) %>%
#   count(mode_f, year) 
#All mode_fx ==6 are either Party or Charter trips so will reclassify

Tripdata <- Tripdata %>% 
  mutate(var_id = ifelse(var_id=="",strat_id,var_id),
         mode_fc = mode_fx,
         mode_fc= ifelse(mode_fc%in%c("5","6"),"4",mode_fc)) %>%
  dplyr::select(strat_id,
            psu_id,
            id_code,
            st,
            cnty,
            intsite,
            wave,
            mode_fc,
            var_id,
            region, 
            sub_reg,
            wp_int,
            year) 


Tripdata  <- Tripdata %>% 
  arrange(strat_id, psu_id, id_code) %>%
  mutate(dtrip=1)


REC_DATA <- Tripdata %>% filter(sub_reg %in% c(4,5)) %>%
  mutate(dtrip=1,
    mode_fc=factor(mode_fc,levels=c("3","4","7"),
    labels=c("Shore","Party_Charter","Private_Rental")),
    Region=factor(sub_reg,levels=c("4","5"),
    labels=c("NE","MA")))

Effortdesign <- svydesign(
  ids = ~psu_id, 
  strata = ~var_id, # Specify the strata variable
  weights = ~wp_int, # Specify the weight variable
  data = REC_DATA,
  nest=TRUE
)

Effortmeans <- svyby(~dtrip, by=~year+
                       mode_fc+
                       Region, svytotal,
                      design=Effortdesign)

Effortmeans$dtrip <- ceiling(Effortmeans$dtrip)

TotalEffort <- Effortmeans %>% group_by(Region,year) %>%
  summarise(All_Modes=sum(dtrip)) %>% ungroup

Effortmeans <- left_join(Effortmeans,TotalEffort, by=c("Region","year"))

Effortmeans$Percent <- -(Effortmeans$dtrip/Effortmeans$All_Modes)*
  log(Effortmeans$dtrip/Effortmeans$All_Modes)
E_SHANNON  <- Effortmeans %>%
                group_by(Region, year) %>%
  summarise(Value=exp(sum(Percent,na.rm=TRUE)) )%>% 
  ungroup %>% 
  select("year","Region","Value") 
E_SHANNON$Units <- 'Effective Shannon'
E_SHANNON$Var <- 'Recreational fleet effort diversity across modes'
E_SHANNON$Source <- 'MRIP effort time series, processed to generate diversity measure.'
write.csv(E_SHANNON,file=file.path(Output_location,"Rec_angler_effort_eShannon_2026.csv"))

Effortmeans <- svyby(~dtrip, by=~year+
                       Region, svytotal,
                     design=Effortdesign)

names(Effortmeans) <- c("Time","Region","Value","Std_err")
Effortmeans$Units <- 'Number of days fished'
Effortmeans$Var <- 'Recreational Effort'
Effortmeans$Source <- 'MRIP effort time series.'
write.csv(Effortmeans,file=file.path(Output_location,"Rec_angler_days_fished_2026.csv"))

filelist <- list.files(file.path(mrip_location), 
                       pattern=glob2rx("catch*.sas7bdat"),
                       full.names = TRUE) 
filelist <- filelist[!grepl("orig*",filelist)]
filelist <- filelist[!grepl("Copy*",filelist)]
filelist <- filelist[!grepl("bak*",filelist)]
filelist <- filelist[!grepl("delete*",filelist)]
filelist <- filelist[!grepl("catch_1981",filelist)]
filelist <- filelist[!grepl(paste0("catch_",Incomplete_year,sep=""),filelist)]
filelist <- filelist[!grepl("1.sas7bdat",filelist)]

Catchdata <- ldply(filelist, function(x) {
  temp <- read_sas(x)
  names(temp) <- tolower(names(temp))
  return(temp)
})
save(Catchdata, file=file.path(Output_location,"reccatch_2026.Rdata"))

Catchdata  <- Catchdata %>% 
  arrange(strat_id, psu_id, id_code) %>% 
  mutate(var_id = ifelse(var_id=="",strat_id,var_id),
         var_id = ifelse(is.na(var_id),strat_id,var_id),
         wp_catch = ifelse(is.na(wp_catch),wp_int,wp_catch)) %>%
  dplyr::select(strat_id,
                psu_id,
                id_code,
                year,
                wave,
                st,
                sub_reg,
                common,
                sp_code,
                wp_catch,
                wp_int,
                tot_cat,
                wgt_ab1,
                var_id) %>%
  filter(sub_reg %in% c(4,5)) %>%
  mutate(Region = "",
         Region = ifelse(sub_reg ==4,"NE",Region),
         Region = ifelse(sub_reg ==5,"MA",Region)) %>% 
  left_join(Tripdata)
#landings and catch weight are reported in kg and need to be converted to lbs
Catchdata$lbslanded <- Catchdata$wgt_ab1*2.2046

#Code below keeps species groupings for MA and NE different as currently applied

Catchdata <- Catchdata %>%
  mutate(my_common="All_OTHER_SPECIES",
         my_common=ifelse(common=="ATLANTIC COD"| sp_code=='8791030402',"ATLANTIC COD",my_common),
         my_common=ifelse(common=="HADDOCK" | sp_code=='8791031301',"HADDOCK",my_common),
         my_common=ifelse(common=="ATLANTIC MACKEREL" | sp_code=='8850030302',"ATLANTIC MACKEREL",my_common),
         my_common=ifelse(common=="WINTER FLOUNDER" | sp_code=='8857042001',"WINTER FLOUNDER",my_common),
         my_common=ifelse(common=="TAUTOG" | sp_code=='8839010101',"TAUTOG",my_common),
         my_common=ifelse(common=="POLLOCK" | sp_code=='8791030901',"POLLOCK",my_common),
         my_common=ifelse(common=="SUMMER FLOUNDER" | sp_code=='8857030301',"SUMMER FLOUNDER",my_common),
         my_common=ifelse(common=="SCUP" | sp_code=='8835430101',"SCUP",my_common),
         my_common=ifelse(common=="BLACK SEA BASS" | sp_code=='8835020301',"BLACK SEA BASS",my_common),
         my_common=ifelse(common=="BLUEFISH" | sp_code=='8835250101',"BLUEFISH",my_common),
         my_common=ifelse(common=="TILEFISH" | sp_code=='8835220201',"TILEFISH",my_common),
         my_common=ifelse(common=="SPINY DOGFISH" | sp_code=='8710010201',"SPINY DOGFISH",my_common),
         my_common=ifelse(common=="STRIPED BASS" | sp_code=='8835020102',"STRIPED BASS",my_common),
         my_common=ifelse(common=="AMERICAN EEL" | sp_code=='8741010101',"AMERICAN EEL",my_common),
         my_common=ifelse(common=="ATLANTIC STURGEON" | sp_code=='8729010105',"ATLANTIC STURGEON",my_common),
         my_common=ifelse(common=="BLACK DRUM" | sp_code=='8835440801',"BLACK DRUM",my_common),
         my_common=ifelse(common=="COBIA" | sp_code=='8835260101',"COBIA",my_common),
         my_common=ifelse(common=="RED DRUM" | sp_code=='8835440901',"RED DRUM",my_common),
         my_common=ifelse(common=="SPOT" | sp_code=='8835440401',"SPOT",my_common),
         my_common=ifelse(common=="SPANISH MACKEREL" | sp_code=='8850030502',"SPANISH MACKEREL",my_common),
         my_common=ifelse(common=="SPOTTED SEATROUT" | sp_code=='8835440102',"SPOTTED SEATROUT",my_common),
         my_common=ifelse(common=="WEAKFISH" | sp_code=='883544004',"WEAKFISH",my_common),
         my_common=ifelse(common=="ALMACO JACK" | sp_code=='8835280803' & sub_reg==5,"ALMACO JACK",my_common),
         my_common=ifelse(common=="ATLANTIC CROAKER" | sp_code=='8835440702' & sub_reg==5,"ATLANTIC CROAKER",my_common),
         my_common=ifelse(common=="ATLANTIC HERRING" | sp_code=='8747010201' & sub_reg==5,"ATLANTIC HERRING",my_common),
         my_common=ifelse(common=="ATLANTIC MENHADEN" | sp_code=='8747010401' & sub_reg==5,"ATLANTIC MENHADEN",my_common),
         my_common=ifelse(common=="ATLANTIC SPADEFISH" | sp_code=='8835520101' & sub_reg==5,"ATLANTIC SPADEFISH",my_common),
         my_common=ifelse(common=="BANDED RUDDERFISH" | sp_code=='8835280804' & sub_reg==5,"BANDED RUDDERFISH",my_common),
         my_common=ifelse(common=="BAR JACK" | sp_code=='8835280308' & sub_reg==5,"BAR JACK",my_common),
         my_common=ifelse(common=="BLACK GROUPER" | sp_code=='8835020502' & sub_reg==5,"BLACK GROUPER",my_common),
         my_common=ifelse(common=="BLACK SNAPPER" | sp_code=='8835360201' & sub_reg==5,"BLACK SNAPPER",my_common),
         my_common=ifelse(common=="BLACKFIN SNAPPER" | sp_code=='8835360106' & sub_reg==5,"BLACKFIN SNAPPER",my_common),
         my_common=ifelse(common=="BLUE RUNNER" | sp_code=='8835280306' & sub_reg==5,"BLUE RUNNER",my_common),
         my_common=ifelse(common=="BLUELINE TILEFISH" | sp_code=='8835220104' & sub_reg==5,"BLUELINE TILEFISH",my_common),
         my_common=ifelse(common=="CERO" | sp_code=='8850030503' & sub_reg==5,"CERO",my_common),
         my_common=ifelse(common=="CONEY" | sp_code=='8835020802' & sub_reg==5,"CONEY",my_common),
         my_common=ifelse(common=="COTTONWICK" | sp_code=='8835400111' & sub_reg==5,"COTTONWICK",my_common),
         my_common=ifelse(common=="CUBERA SNAPPER" | sp_code=='8835360101' & sub_reg==5,"CUBERA SNAPPER",my_common),
         my_common=ifelse(common=="DOG SNAPPER" | sp_code=='8835360109' & sub_reg==5,"DOG SNAPPER",my_common),
         my_common=ifelse(common=="GAG" | sp_code=='8835020501' & sub_reg==5,"GAG",my_common),
         my_common=ifelse(common=="GOLIATH GROUPER" | sp_code=='8835020401' & sub_reg==5,"GOLIATH GROUPER",my_common),
         my_common=ifelse(common=="GRAY SNAPPER" | sp_code=='8835360102' & sub_reg==5,"GRAY SNAPPER",my_common),
         my_common=ifelse(common=="GRAY TRIGGERFISH" | sp_code=='8860020201' & sub_reg==5,"GRAY TRIGGERFISH",my_common),
         my_common=ifelse(common=="GRAYSBY" | sp_code=='8835021801' & sub_reg==5,"GRAYSBY",my_common),
         my_common=ifelse(common=="GREATER AMBERJACK" | sp_code=='8835280801' & sub_reg==5,"GREATER AMBERJACK",my_common),
         my_common=ifelse(common=="HOGFISH" | sp_code=='889010901' & sub_reg==5,"HOGFISH",my_common),
         my_common=ifelse(common=="JOLTHEAD PORGY" | sp_code=='8835430502' & sub_reg==5,"JOLTHEAD PORGY",my_common),
         my_common=ifelse(common=="KING MACKEREL" | sp_code=='8850030501' & sub_reg==5,"KING MACKEREL",my_common),
         my_common=ifelse(common=="KNOBBED PORGY" | sp_code=='8835430506' & sub_reg==5,"KNOBBED PORGY",my_common),
         my_common=ifelse(common=="LANE SNAPPER" | sp_code=='8835360112' & sub_reg==5,"LANE SNAPPER",my_common),
         my_common=ifelse(common=="LESSER AMBERJACK" | sp_code=='8835280802' & sub_reg==5,"LESSER AMBERJACK",my_common),
         my_common=ifelse(common=="LITTLE TUNNY" | sp_code=='8850030102' & sub_reg==5,"LITTLE TUNNY",my_common),
         my_common=ifelse(common=="LONGSPINE PORGY" | sp_code=='8835430102' & sub_reg==5,"LONGSPINE PORGY",my_common),
         my_common=ifelse(common=="MAHOGANY SNAPPER" | sp_code=='8835360110' & sub_reg==5,"MAHOGANY SNAPPER",my_common),
         my_common=ifelse(common=="MARGATE" | sp_code=='8850030501' & sub_reg==5,"MARGATE",my_common),
         my_common=ifelse(common=="MISTY GROUPER" | sp_code=='8835020409' & sub_reg==5,"MISTY GROUPER",my_common),
         my_common=ifelse(common=="MUTTON SNAPPER" | sp_code=='8835360103' & sub_reg==5,"MUTTON SNAPPER",my_common),
         my_common=ifelse(common=="NASSAU GROUPER" | sp_code=='8835020412' & sub_reg==5,"NASSAU GROUPER",my_common),
         my_common=ifelse(common=="OCEAN TRIGGERFISH" | sp_code=='8860020502' & sub_reg==5,"OCEAN TRIGGERFISH",my_common),
         my_common=ifelse(common=="PUDDINGWIFE" | sp_code=='8839010709' & sub_reg==5,"PUDDINGWIFE",my_common),
         my_common=ifelse(common=="QUEEN SNAPPER" | sp_code=='8835360301' & sub_reg==5,"QUEEN SNAPPER",my_common),
         my_common=ifelse(common=="RED GROUPER" | sp_code=='8835020408' & sub_reg==5,"RED GROUPER",my_common),
         my_common=ifelse(common=="RED HIND" | sp_code=='8835020406' & sub_reg==5,"RED HIND",my_common),
         my_common=ifelse(common=="RED PORGY" | sp_code=='8835430602' & sub_reg==5,"RED PORGY",my_common),
         my_common=ifelse(common=="RED SNAPPER" | sp_code=='8835360107' & sub_reg==5,"RED SNAPPER",my_common),
         my_common=ifelse(common=="ROCK HIND" | sp_code=='8835020402' & sub_reg==5,"ROCK HIND",my_common),
         my_common=ifelse(common=="ROCK SEA BASS" | sp_code=='8835020305' & sub_reg==5,"ROCK SEA BASS",my_common),
         my_common=ifelse(common=="SAILORS CHOICE" | sp_code=='8835400117' & sub_reg==5,"SAILORS CHOICE",my_common),
         my_common=ifelse(common=="SAND TILEFISH" | sp_code=='8835220301' & sub_reg==5,"SAND TILEFISH",my_common),
         my_common=ifelse(common=="SAUCEREYE PORGY" | sp_code=='8835430503' & sub_reg==5,"SAUCEREYE PORGY",my_common),
         my_common=ifelse(common=="SCAMP" | sp_code=='8835020505' & sub_reg==5,"SCAMP",my_common),
         my_common=ifelse(common=="SCHOOLMASTER" | sp_code=='8835360104' & sub_reg==5,"SCHOOLMASTER",my_common),
         my_common=ifelse(common=="SILK SNAPPER" | sp_code=='8835360113' & sub_reg==5,"SILK SNAPPER",my_common),
         my_common=ifelse(common=="SNOWY GROUPER" | sp_code=='8835020411' & sub_reg==5,"SNOWY GROUPER",my_common),
         my_common=ifelse(common=="SOUTHERN FLOUNDER" | sp_code=='8857030304' & sub_reg==5,"SOUTHERN FLOUNDER",my_common),
         my_common=ifelse(common=="SPANISH MACKEREL" | sp_code=='8850030502' & sub_reg==5,"SPANISH MACKEREL",my_common),
         my_common=ifelse(common=="SPECKLED HIND" | sp_code=='8835020404' & sub_reg==5,"SPECKLED HIND",my_common),
         my_common=ifelse(common=="SPINY DOGFISH" | sp_code=='8710010201' & sub_reg==5,"SPINY DOGFISH",my_common),
         my_common=ifelse(common=="TOMTATE" | sp_code=='8835400101' & sub_reg==5,"TOMTATE",my_common),
         my_common=ifelse(common=="VERMILION SNAPPER" | sp_code=='8835360501' & sub_reg==5,"VERMILION SNAPPER",my_common),
         my_common=ifelse(common=="WAHOO" | sp_code=='8850030601' & sub_reg==5,"WAHOO",my_common),
         my_common=ifelse(common=="WARSAW GROUPER" | sp_code=='8835020410' & sub_reg==5,"WARSAW GROUPER",my_common),
         my_common=ifelse(common=="WHITE GRUNT" | sp_code=='8835400102' & sub_reg==5,"WHITE GRUNT",my_common),
         my_common=ifelse(common=="WHITEBONE PORGY" | sp_code=='8835430505' & sub_reg==5,"WHITEBONE PORGY",my_common),
         my_common=ifelse(common=="WRECKFISH" | sp_code=='8835022801' & sub_reg==5,"WRECKFISH",my_common),
         my_common=ifelse(common=="YELLOWEDGE GROUPER" | sp_code=='8835020405' & sub_reg==5,"YELLOWEDGE GROUPER",my_common),
         my_common=ifelse(common=="YELLOWFIN GROUPER" | sp_code=='8835020506' & sub_reg==5,"YELLOWFIN GROUPER",my_common),
         my_common=ifelse(common=="YELLOWMOUTH GROUPER" | sp_code=='8835020504' & sub_reg==5,"YELLOWMOUTH GROUPER",my_common),
         my_common=ifelse(common=="YELLOWTAIL SNAPPER" | sp_code=='8835360401' & sub_reg==5,"YELLOWTAIL SNAPPER",my_common))

Catchdata$my_common[is.na(Catchdata$my_common)] <- "All_OTHER_SPECIES"

Catchdata <- Catchdata %>%
    group_by(strat_id,psu_id,id_code,
           var_id, wp_int,
           wp_catch,my_common,year,Region) %>%
  summarise(tot_cat=sum(tot_cat, na.rm=TRUE),
            lbslanded=sum(lbslanded,na.rm=TRUE)) %>% ungroup

Catchdesign <- svydesign(
  ids = ~psu_id, # Specify the cluster variable
  strata = ~var_id, # Specify the strata variable
  weights = ~wp_catch, # Specify the weight variable
  data = Catchdata,
  nest=TRUE
)

REC_CATCH <- svyby(~tot_cat, by=~year+my_common+Region, svytotal,
                    design=Catchdesign)

names(REC_CATCH) <- c("Time","Species","Region","Value")

TOT_REC_CATCH <- aggregate(Value~Time+Region, data=REC_CATCH, FUN=sum)
names(TOT_REC_CATCH) <- c('Time','Region','Tot_Catch') 
REC_CATCH <- merge(REC_CATCH,TOT_REC_CATCH, by=c('Time','Region'))
REC_CATCH$P_Catch <- -(REC_CATCH$Value/REC_CATCH$Tot_Catch*
                         log(REC_CATCH$Value/REC_CATCH$Tot_Catch))
REC_CATCH <- aggregate(P_Catch~Time+Region, data=REC_CATCH, FUN=sum)
REC_CATCH$Value <- exp(REC_CATCH$P_Catch)
REC_CATCH <- subset(REC_CATCH, select=c('Time','Region','Value'))
REC_CATCH$Units <- 'Effective Shannon'
REC_CATCH$Var <- 'Recreational Diversity of Catch' 
REC_CATCH$Source <- 'MRIP catch time series.'
write.csv(REC_CATCH,file=file.path(Output_location,"Rec_Species_Diversity_2026.csv"))

Landingdesign <- svydesign(
  ids = ~psu_id, # Specify the cluster variable
  strata = ~var_id, # Specify the strata variable
  weights = ~wp_catch, # Specify the weight variable
  data = Catchdata,
  nest=TRUE
)

Landingmeans <- svyby(~lbslanded, by=~year+Region, svytotal,
                      design=Landingdesign)
Landingmeans$lbslanded <- round(Landingmeans$lbslanded, 0)

Landingmeans$Var <- 'Recreational Seafood'
Landingmeans$Units <- 'lbs of fish'
Landingmeans$Source <- 'MRIP National harvest and release totals'

names(Landingmeans) <- c("Time","Region","Value","SE","Var","Units","Source")
write.csv(Landingmeans,file=file.path(Output_location,'REC_HARVEST_2026.csv'))
