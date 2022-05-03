##___________________________________________________
##
## Script name: visualize_catalog.R
##
## Purpose of script:
## show lidar information by tile
##
## Author: Jens Wiesehahn
## Copyright (c) Jens Wiesehahn, 2022
## Email: wiesehahn.jens@gmail.com
##
## Date Created: 2022-05-02
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
library(here)
library(lidR)
library(mapview)
library(ggplot2)
library(sf)

##___________________________________________________

## load functions into memory
# source("code/functions/some_script.R")

##___________________________________________________

# load catalog 
load(here("data/interim/lidr-catalog.RData"))

mapview::mapview(ctg@data, zcol= "Data.Year")
mapview::mapview(ctg@data, zcol= "Data.Month")


ggplot2::ggplot(ctg@data) +
  geom_sf(aes(fill = as.factor(Data.Year)), colour = NA) +
  viridis::scale_fill_viridis(option="magma", discrete=TRUE, name = "Year") + theme_void()

ggsave(here("results/figures", "data_year.png"), width= 1280, units = "px")


ggplot2::ggplot(ctg@data) +
  geom_sf(aes(fill = as.factor(Data.Month)), colour = NA) +
  viridis::scale_fill_viridis(option="magma", discrete=TRUE, name = "Month") + theme_void()

ggsave(here("results/figures", "data_month.png"), width= 1280, units = "px")
