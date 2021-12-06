##___________________________________________________
##
## Script name: rayshade.R
##
## Purpose of script:
## create rayshaded images samples from ndsm and dtm 
##
## Author: Jens Wiesehahn
## Copyright (c) Jens Wiesehahn, 2021
## Email: wiesehahn.jens@gmail.com
##
## Date Created: 2021-11-07
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
library(rayshader)

##___________________________________________________

## load functions into memory
# source("code/functions/some_script.R")

# function to plot raster
plot_raster <- function(ras){
  ggplot() +
    geom_raster(data = as.data.frame(as(ras, "SpatialPixelsDataFrame")) , aes(x = x, y = y, fill = Z)) + 
    scale_fill_viridis_c(option = "plasma") + theme_void() + coord_fixed() + theme(legend.position = "none")
}

##___________________________________________________

#### load data
tile <- "566000_5737000" #Vogelbeck
# "608000_5734000" # königskrug
# "566000_5709000" # schillerwiesen
LASfile <- paste0("K:/aktiver_datenbestand/ni/lverm/las/stand_2021_0923/daten/3D_Punktwolke_Teil2/lasfilez_", tile, "_laz.laz")

las <-  readLAS(LASfile)
las <- filter_poi(las, Classification != 7 & # noise
                        Classification != 15) # other points (mainly cars)

#### calculate models
# DTM
dtm <- grid_terrain(las, res = 0.5, algorithm = knnidw(k = 10L, p = 2), full_raster =T)

# DSM
dsm <- grid_canopy(las, res = 0.5, algorithm = dsmtin())

# NDSM
nlas <- normalize_height(las, dtm)
ndsm <- grid_canopy(nlas, res = 0.5, algorithm = dsmtin())


noground <- filter_poi(las,
                       Classification != 2 & Z > 0.1 &
                       ReturnNumber == 1L)#NumberOfReturns)
plot(noground, color = "Intensity", colorPalette = viridis::plasma(50))

# # plot
 plot_raster(dtm)
 plot_raster(dsm)
 plot_raster(ndsm)

# # save
# raster::writeRaster(dtm, here(paste0("data/interim/", tile, "_dtm.tif")), format="GTiff")
# raster::writeRaster(dsm, here(paste0("data/interim/", tile, "_dsm.tif")), format="GTiff")
# raster::writeRaster(ndsm, here(paste0("data/interim/", tile, "_ndsm.tif")), format="GTiff")


# sub <- extent(566000, 566250, 5709000, 5709250)
# dsm_sub <- raster::crop(dsm, sub)
# ndsm_sub <- raster::crop(ndsm, sub)

#### render NDSM
elmat = raster_to_matrix(ndsm)

rgb <- RGB(ndsm, col= rainbow(255))
img_array = as.array(rgb)/255

# create 3d view
img_array %>%
  rayshader::plot_3d(elmat, 
                     #windowsize = c(1280, 720), 
                     zscale = 1, 
                     solid = FALSE,
                     zoom = 0.5,
                     theta = 0,
                     phi = 89 
  )

rayshader::render_highquality(
   lightdirection = c(0,80,315),
   lightintensity = c(200, 300, 400),
   lightaltitude= c(80, 45, 25),
   lightcolor= c("white","#ff4d4d","#ffff80"),
  samples = 100,
  sample_method = "sobol_blue",
  min_variance = 0.000025,
  parallel = TRUE,
  width = 2000,
  height = 2000,
  filename = here(paste0("results/figures/",tile, "_ndsm_rayshade.png")))


#### render DTM
elmat = raster_to_matrix(dtm)

rgb <- RGB(dtm, col= viridis(255))
img_array = as.array(rgb)/255


# create 3d view
img_array %>%
  rayshader::plot_3d(elmat, 
                     #windowsize = c(1280, 720), 
                     zscale = 1, 
                     solid = FALSE,
                     zoom = 0.5,
                     theta = 0,
                     phi = 89 
  )


rayshader::render_highquality(
  lightdirection = c(0,80,315),
  lightintensity = c(200, 300, 400),
  lightaltitude= c(80, 45, 25),
  lightcolor= c("white","#ff4d4d","#ffff80"),
  samples = 100,
  sample_method = "sobol_blue",
  min_variance = 0.000025,
  parallel = TRUE,
  width = 2000,
  height = 2000,
  filename = here(paste0("results/figures/",tile, "_dtm_rayshade.png")))


