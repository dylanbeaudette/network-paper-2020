## 2020 Soilscapes / Networks
## P. Roudier, D.E. Beaudette, Dion O'Neal


library(igraph)
library(RColorBrewer)
library(sharpshootR)
library(aqp)

library(rgdal)
library(rgeos)
library(sp)
library(sf)
library(raster)
library(rasterVis)

source('local-functions.R')

# load relevant data
x <- readRDS('data/component-data.rda')
mu <- readRDS('data/spatial-data.rda')
g <- readRDS('data/graph.rda')
d <- readRDS('data/vertices_df.rda')
leg <- readRDS('data/legend.rda')

# list of records by cluster number
# used to search for map unit component names
clust.list <- split(d, d$cluster)


# compute cluster membership by map unit

# create mu (mukey)-> graph (cluster) look-up table
# also computes membership percentage and Shannon H
mu.LUT <- lapply(split(x, x$mukey), mu.agg.membership)
mu.LUT <- do.call('rbind', mu.LUT)

# check: OK
head(mu.LUT)

## sanity checks 

# all clusters should be allocated in the LUT
# OK
setdiff(unique(mu.LUT$cluster), V(g)$cluster)
 
# spatial data LEFT JOIN network cluster LUT
mu <- sp::merge(mu, mu.LUT, by.x='mukey', by.y='mukey', all.x = TRUE)

## TODO: eval via SDA
# investigate map units (mukey) that aren't represented in the graph
missing.mukey <- setdiff(mu$mukey, x$mukey)
saveRDS(missing.mukey, file = 'data/missing-mukey.rds')

# filter-out polygons with no assigned cluster
# 98% of polygons are assigned a cluster
idx <- which(!is.na(mu$cluster))
length(idx) / nrow(mu)
mu <- mu[idx, ]



# aggregate geometry based on cluster labels
# mu.simple <- gUnionCascaded(mu, as.character(mu$cluster))
# mu.simple.spdf <- SpatialPolygonsDataFrame(
#   mu.simple, 
#   data = data.frame(
#     ID = sapply(slot(mu.simple, 'polygons'), slot, 'ID')
#   ), 
#   match.ID = FALSE
# )

# aggregate geometry based on cluster labels
mu.simple.spdf <- mu %>% sf::st_as_sf() %>% dplyr::group_by(cluster) %>% dplyr::summarise()


## viz using raster methods
# this assumes projected CRS
r <- rasterize(mu, raster(extent(mu), resolution = 90), field = 'cluster')
projection(r) <- proj4string(mu)

## kludge for plotting categories
# convert to categorical raster
r <- as.factor(r)
rat <- levels(r)[[1]]

# use previously computed legend of unique cluster IDs and colors
# note that the raster legend is missing 3 clusters
rat$color <- leg$color[match(rat$ID, leg$cluster)]

# copy over associated legend entry
rat$notes <- leg$notes[match(rat$ID, leg$cluster)]

# pack RAT back into raster
levels(r) <- rat

# sanity-check: do the simplified polygons have the same IDs (cluster number) as raster?
# yes
e <- sampleRegular(r, 1000, sp = TRUE)
e$check <- over(e, as(mu.simple.spdf, "Spatial"))$ID
e <- as.data.frame(e)
e <- na.omit(e)
all(as.character(e$layer) == as.character(e$check))



## colors suck: pick a new palette, setup so that clusters are arranged via similarity

# simple plot in R, colors hard to see
png(file='graph-communities-mu-data.png', width=1600, height=1200)
levelplot(r, col.regions=levels(r)[[1]]$color, xlab="", ylab="", att='notes', maxpixels=1e5, colorkey=list(space='right', labels=list(cex=1.25)))
dev.off()

## only useful for a quick preview
# writeRaster(r, file='data/mu-polygons-graph-clusters.tif', datatype='INT1U', format='GTiff', options=c("COMPRESS=LZW"), overwrite=TRUE)

# save to external formats for map / figure making
sf::write_sf(mu.simple.spdf, dsn = 'data', layer = 'graph-and-mu-polygons', driver = 'ESRI Shapefile') 
