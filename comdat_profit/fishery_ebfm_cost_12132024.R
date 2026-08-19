#R Program used to construct trip cost files by lat/lon
# John Walden, NEFSC
#Sept. 11, 2024
##############################################################################
rm(list = ls())
##############################################################################
library(data.table)
library(tidyverse)
library(dplyr)
library(plyr)
library(ROracle)
library(odbc)
library(readr)
library(haven)
library(psych)
library(bea.R)
# library(RODBC)
library(ecodata)
############################################################################################
############################################################################################
############################################################################################
##################################################################
load("trip_cost_spatial.RData")
#Only keep 2000-2009 data. This has location data for 2000-2009
trip_data <- subset(trip_data, YEAR <= 2009)

trip_data <- trip_data[(!duplicated(trip_data$CAMSID)), ]
#######################################################################
#Read in Sam's Trip Cost Data. This is 2010-2023 data
load(here::here("output/sam_trip_cost_v2.RData"))
load(here::here("output/GDPD.RData"))
###############################################################################################
## not running oracle pull -- read in from Sam's spreadsheet
# psswd<- .rs.askForPassword("Oracle Password")
# drv<-dbDriver("Oracle")
# host <- "nefscdb1.nmfs.local"
# port <- 1526
# service_name<-"NEFSC_USERS"
# connect.string<-paste(
#   "(DESCRIPTION=",
#   "(ADDRESS=(PROTOCOL=tcp)(HOST=", host, ")(PORT=", port, "))",
#   "(CONNECT_DATA=(SERVICE_NAME=", service_name, ")))", sep="")
# con<-dbConnect(drv, "jwalden", password=psswd, dbname=connect.string)
# ###############################################################################################
# START.YEAR=2010
# END.YEAR=2023
#
# VTR_locations<-NULL
# CFDETT<-NULL
#
# for (years in START.YEAR:END.YEAR){
#   con<-dbConnect(drv, "jwalden", password=psswd, dbname=connect.string)
#
#   pull_year<-paste0("Now on year ", years)
#   print(pull_year)
#   trips<-paste0("select PERMIT, YEAR, DOCID, CAMSID, LAT_DD, LON_DD
#                 from CAMS_GARFO.CAMS_SUBTRIP
#                 where YEAR=",years," and permit not in ('000000','190998','390998')")
#   location<-dbGetQuery(con,trips)
#   location<-na.omit(location)
#   location<-location[!duplicated(location$CAMSID),]
#   VTR_locations<-rbind(VTR_locations,location)
#
#   dbDisconnect(con)
# }
##################################################################################
#End of Data Pull
##################################################################################

cams_dat <- dplyr::bind_rows(
  readxl::read_excel(here::here("input/latlongs_4M.xlsx"), sheet = 1),
  readxl::read_excel(here::here("input/latlongs_4M.xlsx"), sheet = 2),
  readxl::read_excel(here::here("input/latlongs_4M.xlsx"), sheet = 3),
  readxl::read_excel(here::here("input/latlongs_4M.xlsx"), sheet = 4)
)

saveRDS(cams_dat, here::here("output/cams_data.RDS"))

location <- cams_dat |>
  tidyr::drop_na()

VTR_locations <- location[!duplicated(location$CAMSID), ]

GDP_terminal <- subset(GDP, YEAR == 2024)
GDP_DEF <- GDP_terminal$GDPD

trip_data_2010_2023 <- join(
  trip_data_2010_2023,
  GDP,
  by = "YEAR",
  type = "inner"
)

trip_data_2010_2023$cost_real =
  trip_data_2010_2023$TRIP_COST_NOMINALDOLS_WINSOR *
  (GDP_DEF / trip_data_2010_2023$GDPD)

trip_data_2010_2023 <- join(
  trip_data_2010_2023,
  VTR_locations,
  by = c("YEAR", "CAMSID"),
  type = "inner"
)


trip_data <- trip_data[, c(
  "YEAR",
  "PERMIT",
  "CAMSID",
  "LAT_DD",
  "LON_DD",
  "cost_real"
)]
trip_data_2010_2023 <- trip_data_2010_2023[, c(
  "YEAR",
  "PERMIT",
  "CAMSID",
  "LAT_DD",
  "LON_DD",
  "cost_real"
)]

trip_data <- rbind(trip_data, trip_data_2010_2023)

save(trip_data, file = here::here("output/trip_cost_spatial.RData"))
##################################################################################
#End of cost by location
# ##################################################################################
