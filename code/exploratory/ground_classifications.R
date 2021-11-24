##___________________________________________________
##
## Script name: ground_classifications.R
##
## Purpose of script: test ground classifications
##
##
## Author: Jens Wiesehahn
## Copyright (c) Jens Wiesehahn, 2021
## Email: wiesehahn.jens@gmail.com
##
## Date Created: 2021-11-02
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

##___________________________________________________

## load functions into memory
# source("code/functions/some_script.R")

##___________________________________________________



# # clip and read area from file
LASfile <- here("data/external/sample.laz")
las <- readLAS(LASfile, 
               #select = "xyz", 
               filter = "-keep_xy 556900 5700400 557400 5700800") #readLAS(filter = "-help")


# projections seems not to be read from xml, set manually
projection(las) <- 25832



#classify grounds

# preclassified
ground <- filter_ground(las)
plot(ground)

# Progressive Morphological Filter
ground2 <- classify_ground(las, algorithm = pmf(ws = 5, th = 3))
ground2 <- filter_ground(ground2)
plot(ground2)

# Cloth Simulation Function
ground3 <- classify_ground(las, algorithm = csf())
ground3 <- filter_ground(ground3)
plot(ground3)

# plot grounds
plot_ground <- function(las){
  p1 <- c(min(las@data$X), mean(las@data$Y))
  p2 <- c(max(las@data$X), mean(las@data$Y))
  data_transect <- clip_transect(las, p1, p2, 4)
  ggplot(data_transect@data, aes(x=X, y=Z, color = Intensity)) + 
    geom_point(size = 0.5) + 
    coord_equal() + 
    theme_void() + 
    scale_color_viridis_c(option = "plasma") + 
    theme(legend.position = "none")
}
plot_ground(ground)
plot_ground(ground2)
plot_ground(ground3)
