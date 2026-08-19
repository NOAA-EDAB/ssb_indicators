#R Program to Read in Sam's Data and store in R data frame'
#Revised 09/08/2024 to include 2022 data
# rm(list = ls())
################################################################################
library(data.table)
library(tidyverse)
library(dplyr)
library(plyr)
library(readr)
library(readxl)
library(bea.R)
source("beakey.R")
################################################################################
#Retrieve Sam's data
data2 <- read_excel(here::here("input/2010_2024.xlsx"), 1) #2010-2015
data2 <- data2[, c(1, 2, 5:7)]
data2a <- read_excel(here::here("input/2010_2024.xlsx"), 2) #2016-2024
data2a <- data2a[, c(1, 2, 5:7)]
data2 <- rbind(data2, data2a)

#trip_data<-rbind(data1,data2)
trip_data_2010_2023 <- data2
save(trip_data_2010_2023, file = here::here("output/sam_trip_cost_v2.RData"))
################################################################################
#GDP Deflator
#calculate from BEA Data
#############################################################################
#Function to retrieve BEA GDP data a year at a time.
#Data will be written out to GDPD.RData for use in subsequent program
#############################################################################
fetchgdp <- function(year) {
  year <- as.character(year)

  SpecList <- list(
    'UserID' = beaKey,
    'Method' = 'GetData',
    'datasetname' = 'NIPA',
    'TableName' = 'T10109',
    'RowNumber' = '10',
    'Frequency' = 'A',
    'Year' = year
  )

  GDP <- beaGet(SpecList, asWide = FALSE)
  GDP <- GDP[(LineNumber == 1), c("TimePeriod", "DataValue")]
  colnames(GDP) <- c("YEAR", "GDP")
  GDP$GDPD = GDP$GDP / 100
  GDP[,] <- lapply(GDP, function(x) type.convert(as.character(x), as.is = TRUE))

  return(GDP)
}
###############################################################################
#End of Function
###############################################################################
#Main program
#Put in start and end dates below
start = 2000
end = 2024
#Set up data structure
GDP <- NULL
#load GDP data from BEA for time series into GDP
for (i in start:end) {
  year = i
  datagdp <- fetchgdp(year)
  GDP <- rbind(GDP, datagdp)
}

save(GDP, file = here::here("output/GDPD.RData"))
