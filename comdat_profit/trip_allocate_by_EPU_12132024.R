#R Program used to allocate trips to EPU areas
# John Walden, NEFSC
#Sept. 11, 2024
##############################################################################
rm(list = ls())
##############################################################################
load(here::here("output/trip_cost_spatial.RData"))
pkgs_to_use <- c(
  "sf",
  "ncdf4",
  "raster",
  "rasterVis",
  "RColorBrewer",
  "chron",
  "lattice",
  "RColorBrewer",
  "rlist",
  "data.table",
  "rlang",
  "foreign",
  "tidyverse",
  "sp",
  "sf",
  "here",
  "scales",
  "raster",
  "stringi",
  "ggplot2",
  "tigris",
  "dplyr",
  "writexl",
  "readxl",
  "mapview",
  "geosphere",
  "sf",
  "terra",
  "maps",
  "spatialEco",
  "ggspatial",
  "ggrepel",
  "marmap"
)

lapply(pkgs_to_use, library, character.only = TRUE, quietly = TRUE)
library(readxl)
library(writexl)
library(geosphere)
library(ecodata)
library(dplyr)
#################################################################################
sf::sf_use_s2(F)
regions <- ecodata::epu_sf
#First, Georges Bank

GB_reg <- regions %>%
  dplyr::filter(EPU == "GB")

plot(GB_reg['EPU'])

sp_points = st_as_sf(trip_data, coords = c('LON_DD', 'LAT_DD')) #make points spatial
st_crs(sp_points) = 4326

GB_reg = st_transform(GB_reg, st_crs(sp_points))

GB_points2 <- sf::st_join(sp_points, GB_reg)

VTR_GB_points2_inside <- GB_points2 %>%
  dplyr::filter(!is.na(EPU)) ###THIS IS THE DATA SET OF INTEREST: only data within GB

#############################################################################################
#St_cast spatial points in order to confirm allocations by plotting
VTR_GB_points2_inside_plot = data.frame(st_coordinates(st_cast(
  VTR_GB_points2_inside$geometry,
  "POINT"
)))
VTR_GB_points2_inside_plot <- VTR_GB_points2_inside_plot %>%
  dplyr::rename(LON = X, LAT = Y)

GB_costs <- VTR_GB_points2_inside
plot(VTR_GB_points2_inside_plot)
save(GB_costs, file = here::here("output/GB_cost.RData"))
#############################################################################################
#Now Gulf of Maine
GOM_reg <- regions %>%
  dplyr::filter(EPU == "GOM")

plot(GOM_reg['EPU'])

GOM_reg = st_transform(GOM_reg, st_crs(sp_points))

GOM_points2 <- sf::st_join(sp_points, GOM_reg)

VTR_GOM_points2_inside <- GOM_points2 %>%
  dplyr::filter(!is.na(EPU)) ###THIS IS THE DATA SET OF INTEREST: only data within GOM
#############################################################################################
#St_cast spatial points in order to confirm allocations by plotting
VTR_GOM_points2_inside_plot = data.frame(st_coordinates(st_cast(
  VTR_GOM_points2_inside$geometry,
  "POINT"
)))
VTR_GOM_points2_inside_plot <- VTR_GOM_points2_inside_plot %>%
  dplyr::rename(LON = X, LAT = Y)

GOMdata <- sf::st_as_sf(VTR_GOM_points2_inside_plot, coords = c('LON', 'LAT'))
sf::st_crs(GOMdata) = 4326
ggplot2::ggplot() +
  ggplot2::geom_sf(data = GOMdata, size = 1, alpha = 0.2) +
  ggplot2::geom_sf(data = GOM_reg, color = "Blue", alpha = .5)

#plot(VTR_GOM_points2_inside_plot)
GOM_costs <- VTR_GOM_points2_inside
save(GOM_costs, file = here::here("output/GOM_cost.RData"))
##############################################################################################
#Now MAB
MAB_reg <- regions %>%
  dplyr::filter(EPU == "MAB")

plot(MAB_reg['EPU'])

MAB_reg = st_transform(MAB_reg, st_crs(sp_points))

MAB_points2 <- sf::st_join(sp_points, MAB_reg)

VTR_MAB_points2_inside <- MAB_points2 %>%
  dplyr::filter(!is.na(EPU)) ###THIS IS THE DATA SET OF INTEREST: only data within GOM
#############################################################################################
#St_cast spatial points in order to confirm allocations by plotting
VTR_MAB_points2_inside_plot = data.frame(st_coordinates(st_cast(
  VTR_MAB_points2_inside$geometry,
  "POINT"
)))
VTR_MAB_points2_inside_plot <- VTR_MAB_points2_inside_plot %>%
  dplyr::rename(LON = X, LAT = Y)

plot(VTR_MAB_points2_inside_plot)
MAB_costs <- VTR_MAB_points2_inside
save(MAB_costs, file = here::here("output/MAB_cost.RData"))
#############################################################################################
