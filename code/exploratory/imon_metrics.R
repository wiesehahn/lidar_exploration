##___________________________________________________
##
## Script name: imon_metrics.R
##
## Purpose of script:
## calculate metrics for level-2 sample plots which could be 
## related to precipitation interception.
##
##
## Author: Jens Wiesehahn
## Copyright (c) Jens Wiesehahn, 2021
## Email: wiesehahn.jens@gmail.com
##
## Date Created: 2021-11-24
##
## Notes:
##
##
##___________________________________________________

## use renv for reproducability

## run `renv::init()` at project start inside the project directory to initialze 
## run `renv::snapshot()` to save the project-local library's state (in renv.lock)
## run `renv::history()` to view the git history of the lockfile
## run `renv::revert(commit = "abc123")` to revert the lockfile
## run `renv::restore()` to restore the project-local library's state (download and re-install packages) 

## In short: use renv::init() to initialize your project library, and use
## renv::snapshot() / renv::restore() to save and load the state of your library.

##___________________________________________________

## install and load required packages

## to install packages use: (better than install.packages())
# renv::install("packagename") 

renv::restore()
library(lidR)
library(sf)
library(here)

##___________________________________________________

## load functions into memory
# source("code/functions/some_script.R")

##___________________________________________________


#### load data

# load catalog or create and save if not existent
file <- here("data/interim/lidr-catalog.RData")
if(!file.exists(file)){
  folder1 <- here("K:/aktiver_datenbestand/ni/lverm/las/stand_2021_0923/daten/3D_Punktwolke_Teil1")
  folder2 <- here("K:/aktiver_datenbestand/ni/lverm/las/stand_2021_0923/daten/3D_Punktwolke_Teil2")
  ctg = readLAScatalog(c(folder1, folder2))
  save(ctg, file = file)
} else {
  load(here("data/interim/lidr-catalog.RData"))
}

# set projection
projection(ctg) <- 25832


# load plots
plots <- st_read(here("data/external/versuchsflaechen_imon_ni.gpkg"))


#### functions

# plant area index function (modified)
plant_area_index <- function(number_of_returns, z) {
  # total number of returns with x echoes
  t1 = sum(number_of_returns == 1L) 
  t2 = sum(number_of_returns == 2L) 
  t3 = sum(number_of_returns == 3L) 
  t4 = sum(number_of_returns == 4L) 
  t5 = sum(number_of_returns == 5L) 
  t6 = sum(number_of_returns == 6L) 
  t7 = sum(number_of_returns == 7L) 
  # number of ground returns with x echoes
  g1 = sum(number_of_returns == 1L & z < 2) 
  g2 = sum(number_of_returns == 2L & z < 2) 
  g3 = sum(number_of_returns == 3L & z < 2) 
  g4 = sum(number_of_returns == 4L & z < 2) 
  g5 = sum(number_of_returns == 5L & z < 2) 
  g6 = sum(number_of_returns == 6L & z < 2)
  g7 = sum(number_of_returns == 7L & z < 2) 
  
  # calibration factor
  c = 1/2 # derived from first plot to scale from 0 to 1
  
  pai = c*log((t1 + 1/2*t2 + 1/3*t3 + 1/4*t4 + 1/5*t5 + 1/6*t6 + 1/7*t7) / (g1 + 1/2*g2 + 1/3*g3 + 1/4*g4 + 1/5*g5 + 1/6*g6 + 1/7*g7))
  
  return(pai)
}


#### pixel level per plot

for (i in i:length(plots$geom)) {

  plot <- plots[i,]
  las = clip_roi(ctg, plot)
  
  # remove invalid
  las <- filter_poi(las, Classification != 7)
  
  # normalize
  las <- normalize_height(las, knnidw())
  
  #calc metrics
  
  
  # plant area index
  pai <- grid_metrics(las, ~plant_area_index(NumberOfReturns, Z), 1)
  
  # percent of returns above dbh per m²
  above <- function(z) {
    above <- sum(z > 1.3)
    all <- sum(z >= 0)
    aboveperc <- above/all
    return(aboveperc)
  }
  
  above <- grid_metrics(las, ~above(Z), 1)

  
  # percent of first returns above 2m per m²
  firstabove <- function(return_number, z) {
    above <- sum(z > 1.3 & return_number == 1L)
    all <- sum(z >= 0 & return_number == 1L)
    aboveperc <- (above/all)
    return(aboveperc)
  }

  firstabove <- grid_metrics(las, ~firstabove(ReturnNumber, Z), 1)
  
  # combine layers
  rast <- raster::stack(c(above, firstabove, pai))
  names(rast) <- c("allreturns_above_dbh", "firstreturns_above_dbh", "plant_area_index")
  
  #save
  file <-here("data/processed/imon", paste0("EDVID_", plot$EDVID, ".tif"))
  raster::writeRaster(rast, file, overwrite=TRUE)

  }






#### cloud level per plot

plotlist <- split(plots, seq(nrow(plots)))


metrics <- lapply(plotlist, function(plot) {
  
  las = clip_roi(ctg, plot)
  
  # remove invalid
  las <- filter_poi(las, Classification != 7)
  
  # normalize
  las <- normalize_height(las, knnidw())
  
  
  # filter points above collectors (dbh)
  thresh <- 1.3 #DBH
  above <- filter_poi(las, Z > thresh)
  
  # point density per m²
  area <- area(las)
  
  # first returns
  # above 1.3
  density_above <- sum(above$ReturnNumber == 1L)/area
  # all
  density_all <- sum(las$ReturnNumber == 1L)/area
  # relation above/all
  relation_first <- density_above / density_all
  
  # all returns
  # above 1.3
  density_above <- sum(above$ReturnNumber >=1L)/area
  # all
  density_all <- sum(las$ReturnNumber >=1L)/area
  # relation above/all
  relation_all <- density_above / density_all
  
  pai <- cloud_metrics(las, ~plant_area_index(NumberOfReturns, Z))
  
  
  plotid <- plot$EDVID
  
  # combine layers
  metrics <- data.frame(plotid, relation_first, relation_all, pai)
  names(metrics) <- c("EDVID", "allreturns_above_dbh", "firstreturns_above_dbh", "plant_area_index")
  
  return(metrics)
  
})

metrics.df <- as.data.frame(do.call(rbind, metrics))

write.csv(metrics.df, here("data/processed/imon/versuchsflaechen_imon_ni_metrcis.csv"))
