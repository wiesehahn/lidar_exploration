##___________________________________________________
##
## Script name: lidar_basics.R
##
## Purpose of script:
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

# function to plot raster
plot_raster <- function(ras){
  ggplot() +
    geom_raster(data = as.data.frame(as(ras, "SpatialPixelsDataFrame")) , aes(x = x, y = y, fill = Z)) + 
    scale_fill_viridis_c(option = "plasma") + theme_void() + coord_fixed() + theme(legend.position = "none")
}

##___________________________________________________



# # clip and read area from file
LASfile <- here("data/external/sample.laz")
las <- readLAS(LASfile, 
               #select = "xyz", 
               filter = "-keep_xy 556900 5700400 557400 5700800") #readLAS(filter = "-help")

# projections seems not to be read from xml, set manually
projection(las) <- 25832





#### DTM (DGM)
# use ground points (and water) to create a DTM
dtm <- grid_terrain(las, res = 1, algorithm = knnidw(k = 10L, p = 2))
plot_raster(dtm)
#ggsave(here("results/figures", "dtm1_knnidw.png"), width= 1280, height= 360, units = "px")




####  DSM (DOM)

# points-to-raster method
dsm <- grid_canopy(las, res = 0.5, p2r(0.2, na.fill = tin()))
#dsm <- grid_canopy(las, res = 0.5, algorithm = p2r(subcircle = 0.15))
plot_raster(dsm)
#ggsave(here("results/figures", "dsm05_p2r.png"), width= 1280, height= 360, units = "px")


# Delaunay triangulation of first returns with a linear interpolation 
dsm <- grid_canopy(las, res = 0.5, algorithm = dsmtin())
plot_raster(dsm)
#ggsave(here("results/figures", "dsm05_dstmin.png"), width= 1280, height= 360, units = "px")


# pit-free algorithm 
dsm <- grid_canopy(las, res = 0.5, pitfree(subcircle = 0.15))
#dsm <- grid_canopy(las, res = 0.5, pitfree(thresholds = c(0, 10, 20, 30), max_edge = c(0, 1.5), subcircle = 0.15))
plot_raster(dsm)
#ggsave(here("results/figures", "dsm05_pitfree.png"), width= 1280, height= 360, units = "px")



####  CHM (nDOM / nDSM)

# crown height model in sideview
dtm <- grid_terrain(las, res = 1, algorithm = knnidw(k = 10L, p = 2))
nlas <- normalize_height(las, dtm)
ggplot(nlas@data, aes(X,Z)) + geom_point(size = 0.5) + coord_equal() + theme_void()
#ggsave(here("results/figures", "normalized-pointcloud_sideview.png"), width= 1280, height= 360, units = "px")


# Delaunay triangulation of first returns with a linear interpolation 
ndsm <- grid_canopy(nlas, res = 0.5, algorithm = dsmtin())
plot_raster(ndsm)
#ggsave(here("results/figures", "ndsm05_dstmin.png"), width= 1280, height= 360, units = "px")



