##___________________________________________________
##
## Script name: tree_height.R
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


# filter valid and noground and above DBH
noground <- filter_poi(nlas, Classification != 2 &  Classification != 7 & Z >= 1.3 & Z < 60)

# calculate highest
highest <- grid_metrics(noground, ~max(Z), 1) 



#### tree detection

# get the location of the trees (with windowsize relative to height)

f <- function(x) {y <-x * 0.2 + 4
y[x < 5] <- 5
y[x > 30] <- 10
return(y)
}
ttops <- find_trees(noground, lmf(ws = f))


# plot locations on top of height model
ttops_df <- data.frame(x=ttops@coords[,1], y=ttops@coords[,2], z=ttops@data$Z)

ggplot() +
  geom_raster(data = as.data.frame(as(highest, "SpatialPixelsDataFrame")) , aes(x = x, y = y, fill = V1)) + 
  geom_point(data= ttops_df, aes(x= x, y= y), size = 1, color="black") + 
  scale_fill_viridis_c(option = "plasma") +
  theme_void() + 
  coord_fixed() + 
  theme(legend.position = "none")


# height information
summary(ttops_df$z)
#plot height distribution
ggplot(ttops_df, aes(z)) +
  geom_density()
