##___________________________________________________
##
## Script name: forest_structure.R
##
## Purpose of script:
## check possibilities to explore forest structure with lidar
##
##
## Author: Jens Wiesehahn
## Copyright (c) Jens Wiesehahn, 2021
## Email: wiesehahn.jens@gmail.com
##
## Date Created: 2021-11-05
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
library(here)
library(ggplot2)
library(viridis)
library(raster)

##___________________________________________________

## load functions into memory

##___________________________________________________



# # clip and read area from file
LASfile <- here("data/external/sample.laz")
las <- readLAS(LASfile, 
               #select = "xyz", 
               filter = "-keep_xy 556900 5700400 557400 5700800") #readLAS(filter = "-help")

# projections seems not to be read from xml, set manually
projection(las) <- 25832

# normalize
nlas <- normalize_height(las, knnidw())



# regrowth (0 - 1.3m)
noground <- filter_poi(nlas, Classification != 2 &  Classification != 7 & Z >= 0.1 & Z <= 1.3)
density <- grid_metrics(noground, ~length(Z), 1) 
plot(density, col = viridis(256)) 

# young (1.3 - 5m)
noground <- filter_poi(nlas, Classification != 2 &  Classification != 7 & Z >= 0.1 & Z > 1.3 & Z <=5)
density <- grid_metrics(noground, ~length(Z), 1) 
plot(density, col = viridis(256)) 

# medium (5 - 10m)
noground <- filter_poi(nlas, Classification != 2 &  Classification != 7 & Z > 5 & Z <= 10)
density <- grid_metrics(noground, ~length(Z), 1) 
plot(density, col = viridis(256)) 


# voxelisation by height (1x1x3)
noground <- filter_poi(nlas, Classification != 2 &  Classification != 7 & Z > 0.1)
vox_met <- voxel_metrics(noground, ~list(N = length(Z)), res = c(0.5,10))

plot(vox_met, color="N", colorPalette = viridis(256), size = 2, bg = "white", voxel = T)


