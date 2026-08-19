# Geret DePiper
#Shoreside Support numbers from BLS
library(dplyr)

# ******************************************************************************************
qcewGetIndustryData <- function (year, qtr, industry) {
  url <- "http://data.bls.gov/cew/data/api/YEAR/QTR/industry/INDUSTRY.csv"
  url <- sub("YEAR", year, url, ignore.case=FALSE)
  url <- sub("QTR", tolower(qtr), url, ignore.case=FALSE)
  url <- sub("INDUSTRY", industry, url, ignore.case=FALSE)
  read.csv(url, header = TRUE, sep = ",", quote="\"", dec=".", na.strings=" ", skip=0)
}

#Defining states within the Mid-Atlantic
 # For all area codes and titles see:
 # http://data.bls.gov/cew/doc/titles/area/area_titles.htm

 Mid_Atlantic <- c("10000","24000","36000","34000","42000","37000","51000")
 
 #Defining industires of interest
 # For all industry codes and titles see:
 # http://data.bls.gov/cew/doc/titles/industry/industry_titles.htm

 Markets1 <- NULL
 
 #Defining industires of interest
 # For all industry codes and titles see:
 # http://data.bls.gov/cew/doc/titles/industry/industry_titles.htm
 Industries <- c("3117","42446","44522")
 Years <- c(2017:2021)
 for (y in Years) {
   for (x in Industries) {
     TEMP <- qcewGetIndustryData(y,"A",x) %>% 
       filter(area_fips%in%Mid_Atlantic)
     Markets1 <- rbind(Markets1,TEMP)
   }
 }
 
 Industries <- c("3117","42446","44525")
 Years <- c(2022:2024)
 for (y in Years) {
   for (x in Industries) {
     TEMP <- qcewGetIndustryData(y,"A",x) %>% 
       filter(area_fips%in%Mid_Atlantic)
     Markets1 <- rbind(Markets1,TEMP)
   }
 }
 
 
Seafood_markets1 <- Markets1 %>% group_by(year) %>%
  summarise(Establishments=sum(annual_avg_estabs,na.rm=TRUE),
            Confidential=sum(disclosure_code=="N",na.rm=TRUE)) %>% 
  mutate(Confidential = ifelse(is.na(Confidential),0,Confidential),
         Confidential = paste0(Confidential,
                               " confidential observation(s) suppressed in year ",
                               year,
                               ". Bureau of Labor Statistics Quarterly Census of Employment and Wages data",
                               " for Fish and seafood markets, wholesalers and product preparation.", 
                               sep="")) %>% ungroup()

Markets <- NULL
Years <- c(1990:2015)
for (y in Years) {
  temp <- tempfile()
  download.file(
    paste0("https://data.bls.gov/cew/data/files/",y,"/csv/",y,
           "_annual_by_industry.zip",sep=""),temp)
  TEMP1 <- read.csv(unzip(temp, files=
  paste0(y,".annual.by_industry/",y,
  ".annual 3117 Seafood product preparation and packaging.csv")))%>% 
    filter(area_fips%in%Mid_Atlantic)
  TEMP2 <- read.csv(unzip(temp, files=
                paste0(y,".annual.by_industry/",y,
                ".annual 42446 Fish and seafood merchant wholesalers.csv")))%>% 
    filter(area_fips%in%Mid_Atlantic)
  TEMP3 <- read.csv(unzip(temp, files=
          paste0(y,".annual.by_industry/",y,
          ".annual 44522 Fish and seafood markets.csv")))%>% 
    filter(area_fips%in%Mid_Atlantic)
          
  TEMP <- rbind(TEMP1,TEMP2)
  TEMP <- rbind(TEMP,TEMP3)
  Markets <- rbind(Markets,TEMP)
  unlink(temp)
}
#2016 has a different naming structure then all other years
temp <- tempfile()
download.file(
  paste0("https://data.bls.gov/cew/data/files/2016/csv/2016_annual_by_industry.zip",sep=""),temp)
TEMP1 <- read.csv(unzip(temp, files=
      paste0("2016.annual.by_industry/",
      "2016.annual 3117 NAICS 3117 Seafood product preparation and packaging.csv")))%>% 
  filter(area_fips%in%Mid_Atlantic)
TEMP2 <- read.csv(unzip(temp, files=
                          paste0("2016.annual.by_industry/",
                                 "2016.annual 42446 NAICS 42446 Fish and seafood merchant wholesalers.csv")))%>% 
  filter(area_fips%in%Mid_Atlantic)
TEMP3 <- read.csv(unzip(temp, files=
                          paste0("2016.annual.by_industry/",
                                 "2016.annual 44522 NAICS 44522 Fish and seafood markets.csv")))%>% 
  filter(area_fips%in%Mid_Atlantic)

TEMP <- rbind(TEMP1,TEMP2)
TEMP <- rbind(TEMP,TEMP3)
Markets <- rbind(Markets,TEMP)
unlink(temp)

Seafood_markets <- Markets %>% group_by(year) %>%
  summarise(Establishments=sum(annual_avg_estabs_count,na.rm=TRUE),
            Confidential=sum(disclosure_code=="N",na.rm=TRUE)) %>% 
  mutate(Confidential = ifelse(is.na(Confidential),0,Confidential),
         Confidential = paste0(Confidential,
                               " confidential observation(s) suppressed in year ",
                               year,
                               ". Bureau of Labor Statistics Quarterly Census of Employment and Wages data",
                               " for Fish and seafood markets, wholesalers and product preparation.", 
                               sep="")) %>% ungroup()

Seafood_markets <- rbind.data.frame(Seafood_markets,Seafood_markets1)

names(Seafood_markets) <- c('Time','Value','Source')
Seafood_markets$Region <- "MA"
Seafood_markets$Units <- 'Number of establishments'
Seafood_markets$Var <- 'Shoreside Support Businesses'

#Code below was used to identify the correct file names to extract
# temp <- tempfile()
# download.file("https://data.bls.gov/cew/data/files/2016/csv/2016_annual_by_industry.zip",temp)
# data <- unzip(temp, list=TRUE)
# 
# unlink(temp)
# 
# data %>% filter(grepl("*eafood",Name))

#Nonemployer Statistics call below

library("tidyverse")
# Don't use tidycensus, as of October 2024, you cannot get every kind of table, just  subset.
#library("tidycensus")  
library("censusapi")

Sys.setenv(CENSUS_API_KEY="1cd45e48504e0ede8cd652b3ab227e1dc3aa21e4")
Sys.setenv(CENSUS_KEY="1cd45e48504e0ede8cd652b3ab227e1dc3aa21e4")

API_list <- listCensusApis()
API_list %>% filter(grepl("*onemployer",title))

options(scipen=999)

Nonemployer <- NULL
  for (y in 1997:2001) {
  TEMP <- getCensus(
  name = "nonemp",
  vintage = y,
  vars = c("ST","NAICS1997","NESTAB","NESTAB_F"),
  region = "state:10,24,36,34,42,37,51",
  key="1cd45e48504e0ede8cd652b3ab227e1dc3aa21e4",
  show_call=TRUE) %>% filter(NAICS1997 %in%c(3117,42446,44522)) %>%
  mutate(YEAR=y,
         NESTAB=as.numeric(NESTAB)) %>%
  group_by(YEAR) %>%
  summarise(Establishments=sum(NESTAB,na.rm=TRUE),
            Confidential=sum(NESTAB_F=="D",na.rm=TRUE)) %>% 
  mutate(Confidential = ifelse(is.na(Confidential),0,Confidential),
         Confidential = paste0(Confidential,
                               " confidential observation(s) suppressed in year ",
                               YEAR,
                               ". Census Bureau Nonemployer Statistics data",
                               " for Fish and seafood markets, wholesalers and product preparation.", 
                               sep="")) %>% ungroup()
  Nonemployer <- rbind.data.frame(Nonemployer,TEMP)
  }

for (y in 2002:2007) {
  TEMP <- getCensus(
    name = "nonemp",
    vintage = y,
    vars = c("ST","NAICS2002","NESTAB","NESTAB_F"),
    region = "state:10,24,36,34,42,37,51",
    key="1cd45e48504e0ede8cd652b3ab227e1dc3aa21e4",
    show_call=TRUE) %>% filter(NAICS2002 %in%c(3117,42446,44522)) %>%
    mutate(YEAR=y,
           NESTAB=as.numeric(NESTAB)) %>%
    group_by(YEAR) %>%
    summarise(Establishments=sum(NESTAB,na.rm=TRUE),
              Confidential=sum(NESTAB_F=="D",na.rm=TRUE)) %>% 
    mutate(Confidential = ifelse(is.na(Confidential),0,Confidential),
           Confidential = paste0(Confidential,
                                 " confidential observation(s) suppressed in year ",
                                 YEAR,
                                 ". Census Bureau Nonemployer Statistics data",
                                 " for Fish and seafood markets, wholesalers and product preparation.", 
                                 sep="")) %>% ungroup()
  Nonemployer <- rbind.data.frame(Nonemployer,TEMP)
}
for (y in 2008:2011) {
  TEMP <- getCensus(
    name = "nonemp",
    vintage = y,
    vars = c("ST","NAICS2007","NESTAB","NESTAB_F"),
    region = "state:10,24,36,34,42,37,51",
    key="1cd45e48504e0ede8cd652b3ab227e1dc3aa21e4",
    show_call=TRUE) %>% filter(NAICS2007 %in%c(3117,42446,44522)) %>%
    mutate(YEAR=y,
           NESTAB=as.numeric(NESTAB)) %>%
    group_by(YEAR) %>%
    summarise(Establishments=sum(NESTAB,na.rm=TRUE),
              Confidential=sum(NESTAB_F=="D",na.rm=TRUE)) %>% 
    mutate(Confidential = ifelse(is.na(Confidential),0,Confidential),
           Confidential = paste0(Confidential,
                                 " confidential observation(s) suppressed in year ",
                                 YEAR,
                                 ". Census Bureau Nonemployer Statistics data",
                                 " for Fish and seafood markets, wholesalers and product preparation.", 
                                 sep="")) %>% ungroup()
  Nonemployer <- rbind.data.frame(Nonemployer,TEMP)
}
for (y in 2012:2016) {
  TEMP <- getCensus(
    name = "nonemp",
    vintage = y,
    vars = c("STATE","NAICS2012","NESTAB","NESTAB_F","YEAR"),
    region = "state:10,24,36,34,42,37,51",
    key="1cd45e48504e0ede8cd652b3ab227e1dc3aa21e4",
    show_call=TRUE) %>% filter(NAICS2012 %in%c(3117,42446,44522)) %>%
    mutate(NESTAB=as.numeric(NESTAB)) %>%
    group_by(YEAR) %>%
    summarise(Establishments=sum(NESTAB,na.rm=TRUE),
              Confidential=sum(NESTAB_F=="D",na.rm=TRUE)) %>% 
    mutate(Confidential = ifelse(is.na(Confidential),0,Confidential),
           Confidential = paste0(Confidential,
                                 " confidential observation(s) suppressed in year ",
                                 YEAR,
                                 ". Census Bureau Nonemployer Statistics data",
                                 " for Fish and seafood markets, wholesalers and product preparation.", 
                                 sep="")) %>% ungroup()
  Nonemployer <- rbind.data.frame(Nonemployer,TEMP)
}

for (y in 2017:2021) {
  TEMP <- getCensus(
    name = "nonemp",
    vintage = y,
    vars = c("STATE","NAICS2017","NESTAB","NESTAB_F","YEAR"),
    region = "state:10,24,36,34,42,37,51",
    key="1cd45e48504e0ede8cd652b3ab227e1dc3aa21e4",
    show_call=TRUE) %>% filter(NAICS2017 %in%c(31171,424460,44522,424490)) %>%
    mutate(NESTAB=as.numeric(NESTAB)) %>%
    group_by(YEAR) %>%
    summarise(Establishments=sum(NESTAB,na.rm=TRUE),
              Confidential=sum(NESTAB_F=="D",na.rm=TRUE)) %>% 
    mutate(Confidential = ifelse(is.na(Confidential),0,Confidential),
           Confidential = paste0(Confidential,
                                 " confidential observation(s) suppressed in year ",
                                 YEAR,
                                 ". Census Bureau Nonemployer Statistics data",
                                 " for Fish and seafood markets, wholesalers and product preparation.", 
                                 sep="")) %>% ungroup()
    Nonemployer <- rbind.data.frame(Nonemployer,TEMP)
}

 for (y in 2022) {
   TEMP <- getCensus(
     name = "nonemp",
     vintage = y,
     vars = c("STATE","NAICS2022","NESTAB","NESTAB_F","YEAR"),
     region = "state:10,24,36,34,42,37,51",
     key="1cd45e48504e0ede8cd652b3ab227e1dc3aa21e4",
     show_call=TRUE) %>% filter(NAICS2022 %in%c(424490,31171,424460,44525)) %>%
     mutate(NESTAB=as.numeric(NESTAB)) %>%
     group_by(YEAR) %>%
     summarise(Establishments=sum(NESTAB,na.rm=TRUE),
               Confidential=sum(NESTAB_F=="D",na.rm=TRUE)) %>% 
     mutate(Confidential = ifelse(is.na(Confidential),0,Confidential),
            Confidential = paste0(Confidential,
                                  " confidential observation(s) suppressed in year ",
                                  YEAR,
                                  ". Census Bureau Nonemployer Statistics data",
                                  " for Fish and seafood markets, wholesalers and product preparation.", 
                                  sep="")) %>% ungroup()
   Nonemployer <- rbind.data.frame(Nonemployer,TEMP)
 }

names(Nonemployer) <- c('Time','Value','Source')
Nonemployer$Region <- "MA"
Nonemployer$Units <- 'Number of establishments'
Nonemployer$Var <- 'Shoreside Support Nonemployer Establishments'

Total <- rbind.data.frame(Nonemployer,Seafood_markets)

write.csv(Total,file='Shoreside_Support_2025.csv')