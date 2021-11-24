##___________________________________________________
##
## Script name: tree_segmentation.R
##
## Purpose of script:
##
##
## Author: Jens Wiesehahn
## Copyright (c) Jens Wiesehahn, 2021
## Email: wiesehahn.jens@gmail.com
##
## Date Created: 2021-11-03
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

# # plot first returns above ground
# noground <- filter_poi(nlas, 
#                        Classification != 2 &  Classification != 7 & Z > 0.1 & 
#                        ReturnNumber == 1L)#NumberOfReturns)
# plot(noground, color = "Intensity")


# filter valid and noground and above DBH
noground <- filter_poi(nlas, Classification != 2 &  Classification != 7 & Z >= 1.3 & Z < 60)

# calculate highest
highest <- grid_metrics(noground, ~max(Z), 1) 
# calculate density
density <- grid_metrics(noground, ~length(Z),  1) 
# calculate summed intensity
imap <- grid_metrics(noground, ~sum(Intensity), 1) # mapping average intensity
# combine statistics in image
hdi <- raster::stack(c(scale(highest, center = F), scale(density, center=F), scale(imap, center=F)))


# plot
plot(hdi, col= viridis(256))
plotRGB(hdi,r=3,g=2,b=1, stretch = "lin")

combined <- highest * density

plot(highest, col= viridis(256))
plot(density, col= viridis(256))
plot(combined, col= viridis(256))




#### tree detection

# get the location of the trees (with windowsize relative to height)

f <- function(x) {y <-x * 0.2 + 4
y[x < 5] <- 5
y[x > 30] <- 10
return(y)
}
ttops <- find_trees(noground, lmf(ws = f))

ttops_df <- data.frame(x=ttops@coords[,1], y=ttops@coords[,2], z=ttops@data$Z)


#### tree segmentation

# Delaunay triangulation of first returns with a linear interpolation 
ndsm <- grid_canopy(noground, res = 0.5, algorithm = dsmtin())

# segment point cloud
algo <- dalponte2016(ndsm, ttops, max_cr = 10, th_seed = 0.5, th_tree = 2)
treecloud <- segment_trees(noground, algo, attribute = "IDdalponte") 

plot(treecloud, color= "IDdalponte")

# segment point cloud
algo <- li2012(dt1 = 1.5, dt2 = 2, R = 2, Zu = 15, hmin = 2, speed_up = 15)
treecloud <- segment_trees(noground, algo, attribute = "IDli") 

plot(treecloud, color= "IDli")

# single tree
tree <- filter_poi(treecloud, IDli == 5)
plot(tree, size = 2, color = "Intensity", colorPalette = viridis::plasma(5), bg = "white")



#### Crown delineation
crowns <- delineate_crowns(treecloud, attribute = "IDli", type = "concave")
crowns <- sf::st_as_sf(crowns)

# plot crown on top of ndsm
ggplot() +
  geom_raster(data = as.data.frame(as(ndsm, "SpatialPixelsDataFrame")) , aes(x = x, y = y, fill = Z)) +
  geom_sf(data = crowns, colour="white", fill=NA) +
  theme_void() + 
  coord_fixed() + 
  scale_fill_viridis_c(option = "plasma") + 
  theme(legend.position = "none") + coord_sf()

