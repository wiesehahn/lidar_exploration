
### Single tree detection / segmentation

[@windrimDetectionSegmentationModel2020]
project attributes to 2D birds eye view (e.g. vertical density, max height, average return) and use a classification approach (e.g. R-CNN)

### Forest gaps
filter for points classified as ground which are first returns, then aggregate

```
ground_first <- filter_poi(las, Classification == 2 & ReturnNumber == 1L)
```

filter for points on ground and use intensity with threshold, e.g.:

```
thresh <- 500
ground <- filter_poi(nlas, Classification == 2 & Intensity > thresh)
```

### Structures between canopy and ground
filter for points which are no ground but represent the last return

```
noground <- filter_poi(las, Classification != 2)
noground_last <- filter_last(noground)
```

### Lying Deadwood
filter for points which are no ground but represent the last return and which are slightly above the ground. Use some filters to remove isolated points and detect line segments from the rest.

```
noground <- filter_poi(nlas, Classification != 2 &  Classification != 7 & Z > 0.1 & Z < 0.5)
noground <- filter_last(noground)
noground <- classify_noise(noground, sor(20,0.1))
noground <- filter_poi(noground, Classification != 18)
noground <- classify_noise(noground, ivf(res = 3, n = 15))
noground <- filter_poi(noground, Classification != 18)
noground <- segment_shapes(noground, shp_line(th1 = 4, k = 8), "linear")
noground <- filter_poi(noground, linear == TRUE)
```

### tree species
use intensity threshold on aboveground first-return-points (Winter-ALS should have higher intensity for needled trees)

```
thresh <- 350
deciduous <- filter_poi(nlas, Classification != 2 &  Classification != 7 & Z > 1.3 & ReturnNumber == 1L & Intensity > thresh)
```