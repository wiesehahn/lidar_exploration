##___________________________________________________
##
## Script name: create_lidr_images.R
##
## Purpose of script:
## create sample images of lidar data and processing possibilities in lidR package.
##
##
## Author: Jens Wiesehahn
## Copyright (c) Jens Wiesehahn, 2021
## Email: wiesehahn.jens@gmail.com
##
## Date Created: 2021-08-27
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

##___________________________________________________



# # clip and read area from file
# LASfile <- "K:/aktiver_datenbestand/ni/lverm/dgm_dom/dom1/stand_2018_0604/daten/punktwolke_laz/lasfilez_582000_5745000_laz.laz"
# las <- readLAS(LASfile)
# las = clip_rectangle(ctg, 582300, 5745000, 582800, 5745500)

# clip and read area from catalog (more efficient)
ctg = readLAScatalog("K:/aktiver_datenbestand/ni/lverm/dgm_dom/dom1/stand_2018_0604/daten/punktwolke_laz/")
las = clip_rectangle(ctg, 590000, 5727000, 590500, 5727500)


# # filter when reading e.g.
# readLAS(filter = "-help")
# las <-  readLAS(LASfile, filter = "-keep_first -drop_z_below 5 -drop_z_above 50")

# # select certain properties when reading e.g.
# las <- readLAS(LASfile, select = "xyzc")

# projections seems not to be read from xml, set manually
projection(las) <- 25832

las <- filter_poi(las, Classification != 7 & # noise
                    Classification != 15) # other points (mainly cars)

# # basic data checking
# print(las)
# summary(las)
# plot(las)
# las_check(las)


# clip data to crossection for demonstration
data_transect_4 <- clip_transect(las, c(min(las@data$X), mean(las@data$Y)), c(max(las@data$X), mean(las@data$Y)), 4)
data_transect_100 <- clip_transect(las, c(min(las@data$X), mean(las@data$Y)), c(max(las@data$X), mean(las@data$Y)), 100)


# plot pointcloud
plot(data_transect_100, bg = "white", colorPalette = viridis::plasma(100))
rgl::snapshot3d(here("results/figures", "pointcloud.png"), width= 1280, height= 360)



#### attributes

#topview by class
plot(data_transect_100, color = "Classification", size = 1, bg = "white", colorPalette = viridis::plasma(10)) 
rgl::snapshot3d(here("results/figures", "classification_topview.png"), width= 1280, height= 360)

# plot crossection with color by attribute 

ggplot(data_transect_4@data, aes(x=X, y=Z, color = gpstime)) + geom_point(size = 0.5) + coord_equal() + theme_void() + scale_color_viridis_c(option = "plasma") + theme(legend.position = "none")
ggsave(here("results/figures", "gpstime_sideview.png"), width= 1280, height= 360, units = "px")

ggplot(data_transect_4@data, aes(x=X, y=Z, color = Intensity)) + geom_point(size = 0.5) + coord_equal() + theme_void() + scale_color_viridis_c(option = "plasma") + theme(legend.position = "none")
ggsave(here("results/figures", "intensity_sideview.png"), width= 1280, height= 360, units = "px")

ggplot(data_transect_4@data, aes(x=X, y=Z, color = factor(Classification))) + geom_point(size = 0.5) + coord_equal() + theme_void() + scale_color_viridis_d(option = "plasma") + theme(legend.position = "none")
ggsave(here("results/figures", "classification_sideview.png"), width= 1280, height= 360, units = "px")

ggplot(data_transect_4@data, aes(x=X, y=Z, color = ReturnNumber)) + geom_point(size = 0.5) + coord_equal() + theme_void() + scale_color_viridis_c(option = "plasma") + theme(legend.position = "none")
ggsave(here("results/figures", "returnnumber_sideview.png"), width= 1280, height= 360, units = "px")

ggplot(data_transect_4@data, aes(x=X, y=Z, color = NumberOfReturns)) + geom_point(size = 0.5) + coord_equal() + theme_void() + scale_color_viridis_c(option = "plasma") + theme(legend.position = "none")
ggsave(here("results/figures", "numberofreturns_sideview.png"), width= 1280, height= 360, units = "px")

ggplot(data_transect_4@data, aes(x=X, y=Z, color = factor(PointSourceID))) + geom_point(size = 0.5) + coord_equal() + theme_void() + scale_color_viridis_d(option = "plasma") + theme(legend.position = "none")
ggsave(here("results/figures", "pointsourceid_sideview.png"), width= 1280, height= 360, units = "px")

ggplot(data_transect_4@data, aes(x=X, y=Z), color = "black") + geom_point(size = 0.5) + coord_equal() + theme_void() + scale_color_viridis_d(option = "plasma") + theme(legend.position = "none")
ggsave(here("results/figures", "pointcloud_sideview.png"), width= 1280, height= 360, units = "px")


#### DTM (DGM)

# plot pre-classified ground
gnd <- filter_ground(data_transect_4)
ggplot(gnd@data, aes(X,Z)) + geom_point(size = 0.5) + coord_equal() + theme_void()
ggsave(here("results/figures", "ground-preclassified_sideview.png"), width= 1280, height= 360, units = "px")


# classify ground points (progressive morphological filter)
ws <- seq(3, 12, 3)
th <- seq(0.1, 1.5, length.out = length(ws))
data_transect_4 <- classify_ground(data_transect_4, algorithm = pmf(ws = ws, th = th))

gnd <- filter_ground(data_transect_4)
ggplot(gnd@data, aes(X,Z)) + geom_point(size = 0.5) + coord_equal() + theme_void()
ggsave(here("results/figures", "ground-pmf_sideview.png"), width= 1280, height= 360, units = "px")

# classify ground points (Cloth Simulation Filter)
data_transect_4 <- classify_ground(data_transect_4, algorithm = csf())
gnd <- filter_ground(data_transect_4)
ggplot(gnd@data, aes(X,Z)) + geom_point(size = 0.5) + coord_equal() + theme_void()
ggsave(here("results/figures", "ground-csf_sideview.png"), width= 1280, height= 360, units = "px")


# use ground points (and water) to create a DTM
dtm <- grid_terrain(data_transect_100, res = 1, algorithm = knnidw(k = 10L, p = 2))
ggplot() +
  geom_raster(data = as.data.frame(as(dtm, "SpatialPixelsDataFrame")) , aes(x = x, y = y, fill = Z)) + 
  scale_fill_viridis_c(option = "plasma") + theme_void() + coord_fixed() + theme(legend.position = "none")
ggsave(here("results/figures", "dtm1_knnidw.png"), width= 1280, height= 360, units = "px")



####  DSM (DOM)

# points-to-raster method
dsm <- grid_canopy(data_transect_100, res = 0.5, p2r(0.2, na.fill = tin()))
#dsm <- grid_canopy(data_transect_100, res = 0.5, algorithm = p2r(subcircle = 0.15))
ggplot() +
  geom_raster(data = as.data.frame(as(dsm, "SpatialPixelsDataFrame")) , aes(x = x, y = y, fill = Z)) + 
  scale_fill_viridis_c(option = "plasma") + theme_void() + coord_fixed() + theme(legend.position = "none")
ggsave(here("results/figures", "dsm05_p2r.png"), width= 1280, height= 360, units = "px")


# Delaunay triangulation of first returns with a linear interpolation 
dsm <- grid_canopy(data_transect_100, res = 0.5, algorithm = dsmtin())
ggplot() +
  geom_raster(data = as.data.frame(as(dsm, "SpatialPixelsDataFrame")) , aes(x = x, y = y, fill = Z)) +
  theme_void()+ coord_fixed() + scale_fill_viridis_c(option = "plasma") + theme(legend.position = "none")
ggsave(here("results/figures", "dsm05_dstmin.png"), width= 1280, height= 360, units = "px")


# pit-free algorithm 
dsm <- grid_canopy(data_transect_100, res = 0.5, pitfree(subcircle = 0.15))
#dsm <- grid_canopy(data_transect_100, res = 0.5, pitfree(thresholds = c(0, 10, 20, 30), max_edge = c(0, 1.5), subcircle = 0.15))
ggplot() +
  geom_raster(data = as.data.frame(as(dsm, "SpatialPixelsDataFrame")) , aes(x = x, y = y, fill = Z)) +
  theme_void()+ coord_fixed() + scale_fill_viridis_c(option = "plasma") + theme(legend.position = "none")
ggsave(here("results/figures", "dsm05_pitfree.png"), width= 1280, height= 360, units = "px")



####  CHM (nDOM / nDSM)

# crown height model in sideview
dtm <- grid_terrain(data_transect_4, res = 1, algorithm = knnidw(k = 10L, p = 2))
nlas <- normalize_height(data_transect_4, dtm)
ggplot(nlas@data, aes(X,Z)) + geom_point(size = 0.5) + coord_equal() + theme_void()
ggsave(here("results/figures", "normalized-pointcloud_sideview.png"), width= 1280, height= 360, units = "px")

# crown height model in topview
dtm <- grid_terrain(data_transect_100, res = 1, algorithm = knnidw(k = 10L, p = 2))
nlas <- normalize_height(data_transect_100, dtm)

# Delaunay triangulation of first returns with a linear interpolation 
ndsm <- grid_canopy(nlas, res = 0.5, algorithm = dsmtin())
ggplot() +
  geom_raster(data = as.data.frame(as(ndsm, "SpatialPixelsDataFrame")) , aes(x = x, y = y, fill = Z)) +
  theme_void()+ coord_fixed() + scale_fill_viridis_c(option = "plasma") + theme(legend.position = "none")
ggsave(here("results/figures", "ndsm05_dstmin.png"), width= 1280, height= 360, units = "px")



#### tree height detection

dtm <- grid_terrain(data_transect_4, res = 1, algorithm = knnidw(k = 10L, p = 2))
nlas <- normalize_height(data_transect_4, dtm)

# get the location of the trees (windowsize 5)
ttops <- find_trees(nlas, lmf(ws = 5))   
ttops_df <- data.frame(x=ttops@coords[,1],z=ttops@data$Z)

ggplot() + 
  geom_point(data= nlas@data, aes(x= X,y = Z), size = 0.1, color = "grey")  + 
  geom_point(data= ttops_df, aes(x= x, y= z), size = 2, color= "red") + 
  coord_equal() + 
  theme_void()
ggsave(here("results/figures", "treeheight_ws-5_sideview.png"), width= 1280, height= 360, units = "px")


# get the location of the trees (windowsize 10)
ttops <- find_trees(nlas, lmf(ws = 10))
ttops_df <- data.frame(x=ttops@coords[,1],z=ttops@data$Z)

ggplot() + 
  geom_point(data= nlas@data, aes(x= X,y = Z), size = 0.1, color = "grey")  + 
  geom_point(data= ttops_df, aes(x= x, y= z), size = 2, color= "red") + 
  coord_equal() + 
  theme_void()
ggsave(here("results/figures", "treeheight_ws-10_sideview.png"), width= 1280, height= 360, units = "px")


# get the location of the trees (with windowsize relative to height)
f <- function(x) {y <-x * 0.2 + 4
y[x < 5] <- 5
y[x > 30] <- 10
return(y)
}
#heights <- seq(0,35,1)
#ws <- f(heights)
#plot(heights, ws, type = "l", ylim = c(0,12))

ttops <- find_trees(nlas, lmf(ws= f))
ttops_df <- data.frame(x=ttops@coords[,1],z=ttops@data$Z)

ggplot() + 
  geom_point(data= nlas@data, aes(x= X,y = Z), size = 0.1, color = "grey")  + 
  geom_point(data= ttops_df, aes(x= x, y= z), size = 2, color= "red") + 
  coord_equal() + 
  theme_void()
ggsave(here("results/figures", "treeheight_ws-adaptive_sideview.png"), width= 1280, height= 360, units = "px")

ggplot() + 
  geom_point(data= nlas@data, aes(x= X,y = Z), size = 0.1, color = "grey")  + 
  geom_point(data= ttops_df, aes(x= x, y= z), size = 1.5, color= "black") + 
  coord_equal() + 
  theme_void()
ggsave(here("results/figures", "treeheight_ws-adapt_sideview.png"), width= 1280, height= 360, units = "px")


#### tree segmentation

dtm <- grid_terrain(data_transect_4, res = 1, algorithm = knnidw(k = 10L, p = 2))
nlas <- normalize_height(data_transect_4, dtm)

nlas <- filter_poi(nlas,  Z > 2)

f <- function(x) {y <-x * 0.2 + 3
y[x < 5] <- 5
y[x > 45] <- 12
return(y)
}
ttops <- find_trees(nlas, lmf(ws= f))
ttops_df <- data.frame(x=ttops@coords[,1],z=ttops@data$Z)

# Delaunay triangulation of first returns with a linear interpolation 
ndsm <- grid_canopy(nlas, res = 0.5, algorithm = dsmtin())

# segment point cloud
algo <- dalponte2016(ndsm, ttops, max_cr = 10, th_seed = 0.5, th_tree = 2)
treecloud <- segment_trees(nlas, algo, attribute = "IDdalponte") 

ggplot() + 
  geom_point(data= treecloud@data, aes(x= X,y = Z, color = factor(IDdalponte)), size = 0.1)  +  
  geom_point(data= ttops_df, aes(x= x, y= z), size = 2, color= "red") +
  coord_equal() + 
  theme_void()  +
  theme(legend.position = "none")


# segment point cloud
algo <- li2012(dt1 = 1.5, dt2 = 2, R = 2, Zu = 15, hmin = 2, speed_up = 15)
treecloud <- segment_trees(nlas, algo, attribute = "IDli") 

ggplot() + 
  geom_point(data= treecloud@data, aes(x= X,y = Z, color = factor(IDli)), size = 0.1)  +  
  scale_color_manual(values=c(rep(c(viridis::plasma(5, end = 0.8)),21))) +
  coord_equal() + 
  theme_void()  +
  theme(legend.position = "none")
ggsave(here("results/figures", "treesegmentation_li_sideview.png"), width= 1280, height= 360, units = "px")


# single tree
tree <- filter_poi(treecloud, IDli == 2)
plot(tree, size = 3, color = "Intensity", colorPalette = viridis::plasma(100) , trim = 150, bg = "white")
rgl::snapshot3d(here("results/figures", "single-tree_new.png"), width= 360, height= 720)


treecloud@data[Z=max(Z)]

#### Crown delineation

dtm <- grid_terrain(data_transect_100, res = 1, algorithm = knnidw(k = 10L, p = 2))
nlas <- normalize_height(data_transect_100, dtm)

nlas <- filter_poi(nlas,  Z > 2)

f <- function(x) {y <-x * 0.2 + 3
y[x < 5] <- 5
y[x > 45] <- 12
return(y)
}
ttops <- find_trees(nlas, lmf(ws= f))
ttops_df <- data.frame(x=ttops@coords[,1],z=ttops@data$Z)

# Delaunay triangulation of first returns with a linear interpolation 
ndsm <- grid_canopy(nlas, res = 0.5, algorithm = dsmtin())

# segment point cloud
algo <- li2012(dt1 = 1.5, dt2 = 2, R = 2, Zu = 15, hmin = 2, speed_up = 15)
treecloud <- segment_trees(nlas, algo, attribute = "IDli") 


plot(treecloud, color = "IDli", bg = "white", colorPalette = random.colors(200))
rgl::snapshot3d(here("results/figures", "treesegmentation_sideview.png"), width= 1280, height= 360)


crowns <- delineate_crowns(treecloud, attribute = "IDli", type = "concave")
crowns <- sf::st_as_sf(crowns)

# Delaunay triangulation of first returns with a linear interpolation 
ndsm <- grid_canopy(nlas, res = 0.5, algorithm = dsmtin())
ggplot() +
  geom_raster(data = as.data.frame(as(ndsm, "SpatialPixelsDataFrame")) , aes(x = x, y = y, fill = Z)) +
  geom_sf(data = crowns, colour="white", fill=NA) +
  theme_void() + 
  coord_fixed() + 
  scale_fill_viridis_c(option = "plasma") + 
  theme(legend.position = "none") + coord_sf()
ggsave(here("results/figures", "ndsm_crown-delineation.png"), width= 1280, height= 360, units = "px")


# multispectral data fusion

dtm <- grid_terrain(data_transect_100, res = 1, algorithm = knnidw(k = 10L, p = 2))
nlas <- normalize_height(data_transect_100, dtm)

img <- raster::stack("X:/ni/lverm/orthos_landesweit_stand_2018_0604/daten/dop20_590000_5726000_col.tif")

projection(img) <- 25832

nlas_rgb <- merge_spatial(nlas, img)
plot(nlas_rgb, color = "RGB", size = 1,bg = "white")

# plot pointcloud
plot(nlas_rgb, bg = "white", color = "RGB", nbits = 8, size = 1)
rgl::snapshot3d(here("results/figures", "pointcloud_rgb.png"), width= 1280, height= 360)


# calculate standard metrics
metrics<- pixel_metrics(data_transect_100, res= 1, func = .stdmetrics)

metricsdf <- as.data.frame(metrics, xy = TRUE) %>%
  na.omit()

ggplot() +
  geom_raster(data = metricsdf, aes(x = x, y = y, fill = zmax)) +
  theme_void()+ coord_fixed() + scale_fill_viridis_c(option = "plasma") + theme(legend.position = "none")
ggsave(here("results/figures", "metrics_zmax.png"), width= 1280, height= 360, units = "px")

ggplot() +
  geom_raster(data = metricsdf, aes(x = x, y = y, fill = zmean)) +
  theme_void()+ coord_fixed() + scale_fill_viridis_c(option = "plasma") + theme(legend.position = "none")
ggsave(here("results/figures", "metrics_zmean.png"), width= 1280, height= 360, units = "px")

ggplot() +
  geom_raster(data = metricsdf, aes(x = x, y = y, fill = zsd)) +
  theme_void()+ coord_fixed() + scale_fill_viridis_c(option = "plasma") + theme(legend.position = "none")
ggsave(here("results/figures", "metrics_zsd.png"), width= 1280, height= 360, units = "px")

ggplot() +
  geom_raster(data = metricsdf, aes(x = x, y = y, fill = zskew)) +
  theme_void()+ coord_fixed() + scale_fill_viridis_c(option = "plasma") + theme(legend.position = "none")
ggsave(here("results/figures", "metrics_zskew.png"), width= 1280, height= 360, units = "px")

ggplot() +
  geom_raster(data = metricsdf, aes(x = x, y = y, fill = zkurt)) +
  theme_void()+ coord_fixed() + scale_fill_viridis_c(option = "plasma") + theme(legend.position = "none")
ggsave(here("results/figures", "metrics_zkurt.png"), width= 1280, height= 360, units = "px")

ggplot() +
  geom_raster(data = metricsdf, aes(x = x, y = y, fill = zentropy)) +
  theme_void()+ coord_fixed() + scale_fill_viridis_c(option = "plasma") + theme(legend.position = "none")
ggsave(here("results/figures", "metrics_zentropy.png"), width= 1280, height= 360, units = "px")

ggplot() +
  geom_raster(data = metricsdf, aes(x = x, y = y, fill = pzabovezmean)) +
  theme_void()+ coord_fixed() + scale_fill_viridis_c(option = "plasma") + theme(legend.position = "none")
ggsave(here("results/figures", "metrics_pzabovezmean.png"), width= 1280, height= 360, units = "px")

ggplot() +
  geom_raster(data = metricsdf, aes(x = x, y = y, fill = pzabove2)) +
  theme_void()+ coord_fixed() + scale_fill_viridis_c(option = "plasma") + theme(legend.position = "none")
ggsave(here("results/figures", "metrics_pzabove2.png"), width= 1280, height= 360, units = "px")

ggplot() +
  geom_raster(data = metricsdf, aes(x = x, y = y, fill = zq5)) +
  theme_void()+ coord_fixed() + scale_fill_viridis_c(option = "plasma") + theme(legend.position = "none")
ggsave(here("results/figures", "metrics_zq5.png"), width= 1280, height= 360, units = "px")

ggplot() +
  geom_raster(data = metricsdf, aes(x = x, y = y, fill = zq10)) +
  theme_void()+ coord_fixed() + scale_fill_viridis_c(option = "plasma") + theme(legend.position = "none")
ggsave(here("results/figures", "metrics_zq10.png"), width= 1280, height= 360, units = "px")

ggplot() +
  geom_raster(data = metricsdf, aes(x = x, y = y, fill = zq15)) +
  theme_void()+ coord_fixed() + scale_fill_viridis_c(option = "plasma") + theme(legend.position = "none")
ggsave(here("results/figures", "metrics_zq15.png"), width= 1280, height= 360, units = "px")

ggplot() +
  geom_raster(data = metricsdf, aes(x = x, y = y, fill = zq20)) +
  theme_void()+ coord_fixed() + scale_fill_viridis_c(option = "plasma") + theme(legend.position = "none")
ggsave(here("results/figures", "metrics_zq20.png"), width= 1280, height= 360, units = "px")

ggplot() +
  geom_raster(data = metricsdf, aes(x = x, y = y, fill = zq25)) +
  theme_void()+ coord_fixed() + scale_fill_viridis_c(option = "plasma") + theme(legend.position = "none")
ggsave(here("results/figures", "metrics_zq25.png"), width= 1280, height= 360, units = "px")

ggplot() +
  geom_raster(data = metricsdf, aes(x = x, y = y, fill = zq30)) +
  theme_void()+ coord_fixed() + scale_fill_viridis_c(option = "plasma") + theme(legend.position = "none")
ggsave(here("results/figures", "metrics_zq30.png"), width= 1280, height= 360, units = "px")

ggplot() +
  geom_raster(data = metricsdf, aes(x = x, y = y, fill = zq35)) +
  theme_void()+ coord_fixed() + scale_fill_viridis_c(option = "plasma") + theme(legend.position = "none")
ggsave(here("results/figures", "metrics_zq35.png"), width= 1280, height= 360, units = "px")

ggplot() +
  geom_raster(data = metricsdf, aes(x = x, y = y, fill = zq40)) +
  theme_void()+ coord_fixed() + scale_fill_viridis_c(option = "plasma") + theme(legend.position = "none")
ggsave(here("results/figures", "metrics_zq40.png"), width= 1280, height= 360, units = "px")

ggplot() +
  geom_raster(data = metricsdf, aes(x = x, y = y, fill = zq45)) +
  theme_void()+ coord_fixed() + scale_fill_viridis_c(option = "plasma") + theme(legend.position = "none")
ggsave(here("results/figures", "metrics_zq45.png"), width= 1280, height= 360, units = "px")

ggplot() +
  geom_raster(data = metricsdf, aes(x = x, y = y, fill = zq50)) +
  theme_void()+ coord_fixed() + scale_fill_viridis_c(option = "plasma") + theme(legend.position = "none")
ggsave(here("results/figures", "metrics_zq50.png"), width= 1280, height= 360, units = "px")

ggplot() +
  geom_raster(data = metricsdf, aes(x = x, y = y, fill = zq55)) +
  theme_void()+ coord_fixed() + scale_fill_viridis_c(option = "plasma") + theme(legend.position = "none")
ggsave(here("results/figures", "metrics_zq55.png"), width= 1280, height= 360, units = "px")

ggplot() +
  geom_raster(data = metricsdf, aes(x = x, y = y, fill = zq60)) +
  theme_void()+ coord_fixed() + scale_fill_viridis_c(option = "plasma") + theme(legend.position = "none")
ggsave(here("results/figures", "metrics_zq60.png"), width= 1280, height= 360, units = "px")

ggplot() +
  geom_raster(data = metricsdf, aes(x = x, y = y, fill = zq65)) +
  theme_void()+ coord_fixed() + scale_fill_viridis_c(option = "plasma") + theme(legend.position = "none")
ggsave(here("results/figures", "metrics_zq65.png"), width= 1280, height= 360, units = "px")

ggplot() +
  geom_raster(data = metricsdf, aes(x = x, y = y, fill = zq70)) +
  theme_void()+ coord_fixed() + scale_fill_viridis_c(option = "plasma") + theme(legend.position = "none")
ggsave(here("results/figures", "metrics_zq70.png"), width= 1280, height= 360, units = "px")

ggplot() +
  geom_raster(data = metricsdf, aes(x = x, y = y, fill = zq75)) +
  theme_void()+ coord_fixed() + scale_fill_viridis_c(option = "plasma") + theme(legend.position = "none")
ggsave(here("results/figures", "metrics_zq75.png"), width= 1280, height= 360, units = "px")

ggplot() +
  geom_raster(data = metricsdf, aes(x = x, y = y, fill = zq80)) +
  theme_void()+ coord_fixed() + scale_fill_viridis_c(option = "plasma") + theme(legend.position = "none")
ggsave(here("results/figures", "metrics_zq80.png"), width= 1280, height= 360, units = "px")

ggplot() +
  geom_raster(data = metricsdf, aes(x = x, y = y, fill = zq85)) +
  theme_void()+ coord_fixed() + scale_fill_viridis_c(option = "plasma") + theme(legend.position = "none")
ggsave(here("results/figures", "metrics_zq85.png"), width= 1280, height= 360, units = "px")

ggplot() +
  geom_raster(data = metricsdf, aes(x = x, y = y, fill = zq90)) +
  theme_void()+ coord_fixed() + scale_fill_viridis_c(option = "plasma") + theme(legend.position = "none")
ggsave(here("results/figures", "metrics_zq90.png"), width= 1280, height= 360, units = "px")

ggplot() +
  geom_raster(data = metricsdf, aes(x = x, y = y, fill = zq95)) +
  theme_void()+ coord_fixed() + scale_fill_viridis_c(option = "plasma") + theme(legend.position = "none")
ggsave(here("results/figures", "metrics_zq95.png"), width= 1280, height= 360, units = "px")

ggplot() +
  geom_raster(data = metricsdf, aes(x = x, y = y, fill = zpcum1)) +
  theme_void()+ coord_fixed() + scale_fill_viridis_c(option = "plasma") + theme(legend.position = "none")
ggsave(here("results/figures", "metrics_zpcum1.png"), width= 1280, height= 360, units = "px")

ggplot() +
  geom_raster(data = metricsdf, aes(x = x, y = y, fill = zpcum2)) +
  theme_void()+ coord_fixed() + scale_fill_viridis_c(option = "plasma") + theme(legend.position = "none")
ggsave(here("results/figures", "metrics_zpcum2.png"), width= 1280, height= 360, units = "px")


ggplot() +
  geom_raster(data = metricsdf, aes(x = x, y = y, fill = zpcum3)) +
  theme_void()+ coord_fixed() + scale_fill_viridis_c(option = "plasma") + theme(legend.position = "none")
ggsave(here("results/figures", "metrics_zpcum3.png"), width= 1280, height= 360, units = "px")


ggplot() +
  geom_raster(data = metricsdf, aes(x = x, y = y, fill = zpcum4)) +
  theme_void()+ coord_fixed() + scale_fill_viridis_c(option = "plasma") + theme(legend.position = "none")
ggsave(here("results/figures", "metrics_zpcum4.png"), width= 1280, height= 360, units = "px")


ggplot() +
  geom_raster(data = metricsdf, aes(x = x, y = y, fill = zpcum5)) +
  theme_void()+ coord_fixed() + scale_fill_viridis_c(option = "plasma") + theme(legend.position = "none")
ggsave(here("results/figures", "metrics_zpcum5.png"), width= 1280, height= 360, units = "px")


ggplot() +
  geom_raster(data = metricsdf, aes(x = x, y = y, fill = zpcum6)) +
  theme_void()+ coord_fixed() + scale_fill_viridis_c(option = "plasma") + theme(legend.position = "none")
ggsave(here("results/figures", "metrics_zpcum6.png"), width= 1280, height= 360, units = "px")


ggplot() +
  geom_raster(data = metricsdf, aes(x = x, y = y, fill = zpcum7)) +
  theme_void()+ coord_fixed() + scale_fill_viridis_c(option = "plasma") + theme(legend.position = "none")
ggsave(here("results/figures", "metrics_zpcum7.png"), width= 1280, height= 360, units = "px")


ggplot() +
  geom_raster(data = metricsdf, aes(x = x, y = y, fill = zpcum8)) +
  theme_void()+ coord_fixed() + scale_fill_viridis_c(option = "plasma") + theme(legend.position = "none")
ggsave(here("results/figures", "metrics_zpcum8.png"), width= 1280, height= 360, units = "px")


ggplot() +
  geom_raster(data = metricsdf, aes(x = x, y = y, fill = zpcum9)) +
  theme_void()+ coord_fixed() + scale_fill_viridis_c(option = "plasma") + theme(legend.position = "none")
ggsave(here("results/figures", "metrics_zpcum9.png"), width= 1280, height= 360, units = "px")


ggplot() +
  geom_raster(data = metricsdf, aes(x = x, y = y, fill = itot)) +
  theme_void()+ coord_fixed() + scale_fill_viridis_c(option = "plasma") + theme(legend.position = "none")
ggsave(here("results/figures", "metrics_itot.png"), width= 1280, height= 360, units = "px")


ggplot() +
  geom_raster(data = metricsdf, aes(x = x, y = y, fill = imax)) +
  theme_void()+ coord_fixed() + scale_fill_viridis_c(option = "plasma") + theme(legend.position = "none")
ggsave(here("results/figures", "metrics_imax.png"), width= 1280, height= 360, units = "px")


ggplot() +
  geom_raster(data = metricsdf, aes(x = x, y = y, fill = imean)) +
  theme_void()+ coord_fixed() + scale_fill_viridis_c(option = "plasma") + theme(legend.position = "none")
ggsave(here("results/figures", "metrics_imean.png"), width= 1280, height= 360, units = "px")


ggplot() +
  geom_raster(data = metricsdf, aes(x = x, y = y, fill = isd)) +
  theme_void()+ coord_fixed() + scale_fill_viridis_c(option = "plasma") + theme(legend.position = "none")
ggsave(here("results/figures", "metrics_isd.png"), width= 1280, height= 360, units = "px")


ggplot() +
  geom_raster(data = metricsdf, aes(x = x, y = y, fill = iskew)) +
  theme_void()+ coord_fixed() + scale_fill_viridis_c(option = "plasma") + theme(legend.position = "none")
ggsave(here("results/figures", "metrics_iskew.png"), width= 1280, height= 360, units = "px")


ggplot() +
  geom_raster(data = metricsdf, aes(x = x, y = y, fill = ikurt)) +
  theme_void()+ coord_fixed() + scale_fill_viridis_c(option = "plasma") + theme(legend.position = "none")
ggsave(here("results/figures", "metrics_ikurt.png"), width= 1280, height= 360, units = "px")


ggplot() +
  geom_raster(data = metricsdf, aes(x = x, y = y, fill = ipground)) +
  theme_void()+ coord_fixed() + scale_fill_viridis_c(option = "plasma") + theme(legend.position = "none")
ggsave(here("results/figures", "metrics_ipground.png"), width= 1280, height= 360, units = "px")


ggplot() +
  geom_raster(data = metricsdf, aes(x = x, y = y, fill = ipcumzq10)) +
  theme_void()+ coord_fixed() + scale_fill_viridis_c(option = "plasma") + theme(legend.position = "none")
ggsave(here("results/figures", "metrics_ipcumzq10.png"), width= 1280, height= 360, units = "px")


ggplot() +
  geom_raster(data = metricsdf, aes(x = x, y = y, fill = ipcumzq30)) +
  theme_void()+ coord_fixed() + scale_fill_viridis_c(option = "plasma") + theme(legend.position = "none")
ggsave(here("results/figures", "metrics_ipcumzq30.png"), width= 1280, height= 360, units = "px")


ggplot() +
  geom_raster(data = metricsdf, aes(x = x, y = y, fill = ipcumzq50)) +
  theme_void()+ coord_fixed() + scale_fill_viridis_c(option = "plasma") + theme(legend.position = "none")
ggsave(here("results/figures", "metrics_ipcumzq50.png"), width= 1280, height= 360, units = "px")


ggplot() +
  geom_raster(data = metricsdf, aes(x = x, y = y, fill = ipcumzq70)) +
  theme_void()+ coord_fixed() + scale_fill_viridis_c(option = "plasma") + theme(legend.position = "none")
ggsave(here("results/figures", "metrics_ipcumzq70.png"), width= 1280, height= 360, units = "px")


ggplot() +
  geom_raster(data = metricsdf, aes(x = x, y = y, fill = ipcumzq90)) +
  theme_void()+ coord_fixed() + scale_fill_viridis_c(option = "plasma") + theme(legend.position = "none")
ggsave(here("results/figures", "metrics_ipcumzq90.png"), width= 1280, height= 360, units = "px")


ggplot() +
  geom_raster(data = metricsdf, aes(x = x, y = y, fill = p1th)) +
  theme_void()+ coord_fixed() + scale_fill_viridis_c(option = "plasma") + theme(legend.position = "none")
ggsave(here("results/figures", "metrics_p1th.png"), width= 1280, height= 360, units = "px")


ggplot() +
  geom_raster(data = metricsdf, aes(x = x, y = y, fill = p2th)) +
  theme_void()+ coord_fixed() + scale_fill_viridis_c(option = "plasma") + theme(legend.position = "none")
ggsave(here("results/figures", "metrics_p2th.png"), width= 1280, height= 360, units = "px")


ggplot() +
  geom_raster(data = metricsdf, aes(x = x, y = y, fill = p3th)) +
  theme_void()+ coord_fixed() + scale_fill_viridis_c(option = "plasma") + theme(legend.position = "none")
ggsave(here("results/figures", "metrics_p3th.png"), width= 1280, height= 360, units = "px")


ggplot() +
  geom_raster(data = metricsdf, aes(x = x, y = y, fill = p4th)) +
  theme_void()+ coord_fixed() + scale_fill_viridis_c(option = "plasma") + theme(legend.position = "none")
ggsave(here("results/figures", "metrics_p4th.png"), width= 1280, height= 360, units = "px")


ggplot() +
  geom_raster(data = metricsdf, aes(x = x, y = y, fill = p5th)) +
  theme_void()+ coord_fixed() + scale_fill_viridis_c(option = "plasma") + theme(legend.position = "none")
ggsave(here("results/figures", "metrics_p5th.png"), width= 1280, height= 360, units = "px")


ggplot() +
  geom_raster(data = metricsdf, aes(x = x, y = y, fill = pground)) +
  theme_void()+ coord_fixed() + scale_fill_viridis_c(option = "plasma") + theme(legend.position = "none")
ggsave(here("results/figures", "metrics_pground.png"), width= 1280, height= 360, units = "px")


ggplot() +
  geom_raster(data = metricsdf, aes(x = x, y = y, fill = n)) +
  theme_void()+ coord_fixed() + scale_fill_viridis_c(option = "plasma") + theme(legend.position = "none")
ggsave(here("results/figures", "metrics_n.png"), width= 1280, height= 360, units = "px")


ggplot() +
  geom_raster(data = metricsdf, aes(x = x, y = y, fill = area)) +
  theme_void()+ coord_fixed() + scale_fill_viridis_c(option = "plasma") + theme(legend.position = "none")
ggsave(here("results/figures", "metrics_area.png"), width= 1280, height= 360, units = "px")



# calculate own metrics
myMetrics<-function(i, z){
  
  q75=quantile(z,probs=c(0.75))         
  aboveq75= z>q75
  zq75 = i[aboveq75]
  
  imeanq75=mean(zq75, na.rm=TRUE)
  
  return(imeanq75)}

nlas <- normalize_height(data_transect_100, tin())
noground <- filter_poi(nlas, Classification != 2, Z >0.5)
m <- pixel_metrics(noground, ~myMetrics(Intensity, Z), res = 1)

metricsdf <- as.data.frame(m, xy = TRUE) %>%
  na.omit()

ggplot() +
  geom_raster(data = metricsdf, aes(x = x, y = y, fill = V1)) +
  theme_void()+ coord_fixed() + scale_fill_viridis_c(limits = c(0, 100),option = "plasma") + theme(legend.position = "none")
ggsave(here("results/figures", "metrics_imeanupper25.png"), width= 1280, height= 360, units = "px")
