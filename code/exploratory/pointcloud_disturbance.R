##___________________________________________________
##
## Script name: pointcloud_disturbance.R
##
## Purpose of script:
## create iamge with different coloring for disturbed areas
##
## Author: Jens Wiesehahn
## Copyright (c) Jens Wiesehahn, 2021
## Email: wiesehahn.jens@gmail.com
##
## Date Created: 2021-12-02
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
library(sf)
library(dplyr)

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

projection(las) <- 25832


# merge dirsturbance data
ref_fnews <- st_read(here("C:/Users/jwiesehahn/arbeit/projects/fnews/workpackage-3/reference-data/data/processed/referenzdaten_32unc.gpkg"), layer = "schadpolygone")
ref <- st_transform(ref_fnews, st_crs(las))

las <- merge_spatial(las, ref, attribute = "DNutz")


# calculate normalized height and add as attribute
dtm <- grid_terrain(las, res = 0.5, algorithm = knnidw(k = 10L, p = 2), full_raster =T)

nlas <- normalize_height(las, dtm, add_lasattribute=TRUE)

las <- add_lasattribute(las, nlas@data$Z, "height", "narmalized point height")



# plot disturbed and undisturbed
nondist <- filter_poi(las, is.na(DNutz) | Classification ==2)
dist <- filter_poi(las, !is.na(DNutz) & Classification !=2)

palette_col <- viridis::plasma(100)
palette_desat <- colorspace::lighten(palette_col, 0.7)
palette_desat <- colorspace::desaturate(palette_desat, 0.5)

x <- plot(nondist, color = "height", bg = "black",colorPalette = palette_desat, size = 1)
plot(dist, color = "height", bg = "white",colorPalette = palette_col, size = 1, add = x)

rgl::snapshot3d(here("results/figures", "pointcloud_disturbance.png"), width= 1280, height= 1280)

