#Program to create Indices for revenue, cost and profitability from EcoData and
#Cost Data
rm(list = ls())
library(data.table)
library(plyr)
library(ggplot2)
library(reshape2)
#############################################################################################
#############################################################################################
CI <- function(data, year, cost_ref) {
  #COST INDEX
  data <- data[, c("YEAR", "PERMIT", "CAMSID", "cost_real")]

  data$index = data$cost_real / cost_ref
  cost_index <- setDT(data)[, .(gmean = exp(mean(log(index)))), by = YEAR]
  cost_base = as.numeric(cost_index[(cost_index$YEAR == year), "gmean"])
  cost_index$cindex = round(cost_index$gmean / cost_base, 3)

  cost_index <- cost_index[, c("YEAR", "cindex")]

  return(cost_index)
}
RI <- function(data, base_rev, base_year) {
  #Revenue Index

  data <- data[(data$YEAR >= base_year), ]
  sum_rev <- setDT(data)[, .(trev = sum(SPPVALUE)), keyby = .(YEAR)]
  colnames(sum_rev)[1] <- "YEAR"

  sum_rev$index = round(sum_rev$trev / base_rev, 3)
  denom = as.numeric(sum_rev[(sum_rev$YEAR == base_year), "index"])
  sum_rev$rindex = round(sum_rev$index / denom, 3)
  sum_rev <- sum_rev[, c("YEAR", "rindex")]

  return(sum_rev)
}
PI <- function(REV_I, COST_I) {
  Index_fin <- join(REV_I, COST_I, by = "YEAR", type = "inner")
  Index_fin$prof_index = Index_fin$rindex / Index_fin$cindex
  Index_fin <- Index_fin[, c("YEAR", "rindex", "cindex", "prof_index")]

  return(Index_fin)
}
PLOTS <- function(PI, AREA, START, END) {
  Index_for_graph <- melt(PI, id = "YEAR")

  labels = c('Revenue Index', 'Cost Index', 'Profitability Index')
  title1 <- paste0(
    AREA,
    " Revenue, Cost and Profitability Indices ",
    START,
    " -",
    END
  )
  subtitle1 <- paste0("Base Year ", START)

  PI_PLOT <- ggplot(Index_for_graph, aes(x = YEAR, y = value)) +
    geom_line(aes(color = variable)) +
    labs(title = title1, subtitle = subtitle1, x = "Year", y = "Index Value") +
    theme(
      plot.title = element_text(hjust = 0.5),
      plot.subtitle = element_text(hjust = 0.5)
    ) +
    scale_color_discrete(labels = labels)
}

PI_PLOT <- function(PI, START, END) {
  Index_for_graph <- melt(PI, id = "YEAR")

  labels = c('GB', 'GOM', 'MAB')
  title1 <- paste0(" Profitability Indices by Year and Area ", START, "-", END)
  subtitle1 <- paste0("Base Year ", START)

  PI_PLOT <- ggplot(Index_for_graph, aes(x = YEAR, y = value)) +
    geom_line(aes(color = variable)) +
    labs(title = title1, subtitle = subtitle1, x = "Year", y = "Index Value") +
    theme(
      plot.title = element_text(hjust = 0.5),
      plot.subtitle = element_text(hjust = 0.5)
    ) +
    scale_color_discrete(labels = labels)
}
#############################################################################
#End of Functions
#############################################################################
#observation for cost denominator is average of all trips from region in 2000
load(here::here("output/trip_cost_spatial.RData"))

start = min(trip_data$YEAR)
terminal = max(trip_data$YEAR)
ref_year_all <- subset(trip_data, YEAR == start)
avg_cost_all = mean(ref_year_all$cost_real) #average trip cost in reference year
###############################################################################
comland <- readRDS(
  "\\\\nefscdata\\EDAB_Datasets\\Workflows\\commercial_bennet.rds"
)
comland.data <- comland$comland
#Only take U.S. landings where the value is greater than zero
comland.data <- subset(
  comland.data,
  US == 'TRUE' & YEAR >= start & SPPVALUE > 0
)
comland.data[, NESPP3 := as.numeric(NESPP3)]
#Note, Next Line is to take out Eastern Oysters from the 2024 Report.
#This may need to be revised once the problem with Eastern Oyster value
#can be determined. NESPP3=789
comland.data <- subset(comland.data, NESPP3 != 789)
###################################################################################
#observation for revenue denominator is average yearly revenue from all three areas
#during the base year
base_rev <- subset(comland.data, YEAR == start & SPPVALUE > 0)
base_rev <- subset(base_rev, EPU == "GB" | EPU == "GOM" | EPU == "MAB")
area_rev <- setDT(base_rev)[, .(trev = sum(SPPVALUE)), keyby = .(EPU)]
mean_rev = mean(area_rev$trev)
####################################################################################
###############################################################################
###GB#####################################################################
load(here::here("output/GB_cost.RData"))
#Cost Index
GB_CI <- CI(GB_costs, start, avg_cost_all)
GB <- subset(comland.data, EPU == "GB")

GB_RI <- RI(GB, mean_rev, start)
GB_PI <- PI(GB_RI, GB_CI)
GB_PLOTS <- PLOTS(GB_PI, "GB", start, terminal)
############################################################################
load(here::here("output/GOM_Cost.RData"))
#Cost Index
GOM_CI <- CI(GOM_costs, start, avg_cost_all)
GOM <- subset(comland.data, EPU == "GOM")
GOM_RI <- RI(GOM, mean_rev, start)
GOM_PI <- PI(GOM_RI, GOM_CI)
GOM_PLOTS <- PLOTS(GOM_PI, "GOM", start, terminal)
############################################################################
load(here::here("output/MAB_Cost.RData"))
#Cost Index
MAB_CI <- CI(MAB_costs, start, avg_cost_all)
MAB <- subset(comland.data, EPU == "MAB")
MAB_RI <- RI(MAB, mean_rev, start)
MAB_PI <- PI(MAB_RI, MAB_CI)
MAB_PLOTS <- PLOTS(MAB_PI, "MAB", start, terminal)
###########################################################################
PI_ALL <- cbind(
  GB_PI$YEAR,
  GB_PI$prof_index,
  GOM_PI$prof_index,
  MAB_PI$prof_index
)
PI_ALL <- as.data.frame(PI_ALL)
colnames(PI_ALL) <- c("YEAR", "GB", "GOM", "MAB")

write.csv(
  PI_ALL,
  file = here::here("output/profitability_indices_by_area.csv"),
  row.names = FALSE
)

output <- dplyr::bind_rows(
  GOM_PI |> dplyr::mutate(EPU = "GOM"),
  GB_PI |> dplyr::mutate(EPU = "GB"),
  MAB_PI |> dplyr::mutate(EPU = "MAB")
)

saveRDS(
  output,
  here::here("output/profitability_indices_by_area.RDS")
)

PI_ALL_AREAS <- PI_PLOT(PI_ALL, start, terminal)
