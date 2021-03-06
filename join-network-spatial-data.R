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
library(ggplot2)
library(stringr)

library(dplyr)

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

write_sf(st_as_sf(mu), 'data/mu-with-cluster-membership.gpkg')

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
mu.simple.sf <- mu %>% 
  sf::st_as_sf() %>%
  dplyr::group_by(cluster) %>% 
  dplyr::summarise()

mu.simple.spdf <- as(mu.simple.sf, "Spatial")
mu.simple.spdf <- spTransform(mu.simple.spdf, CRS(st_crs(mu.simple.sf)$input))

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
e$check <- over(e, mu.simple.spdf)$ID
e <- as.data.frame(e)
e <- na.omit(e)
all(as.character(e$layer) == as.character(e$check))



## colors suck: pick a new palette, setup so that clusters are arranged via similarity

# simple plot in R, colors hard to see
png(file='graph-communities-mu-data.png', width=1600, height=1200)
levelplot(r, col.regions=levels(r)[[1]]$color, xlab="", ylab="", att='notes', maxpixels=1e5, colorkey=list(space='right', labels=list(cex=1.25)))
dev.off()

# Simple plot using sf, to try and debug where things go wrong
map_sf <- ggplot(data = mu.simple.sf) +
  geom_sf(aes(fill = as.factor(cluster)), colour = "gray30", lwd = 0.1) +
  scale_fill_manual(
    "",
    values = leg$color,
    labels = leg$notes
  ) + 
  theme_bw()

mu_parsed_leg <- mu.simple.sf %>%
  left_join(leg) %>% 
  mutate(
    leg = str_sub(notes, 4, str_length(notes)),
    landscape = str_split(leg, pattern = "\\|", simplify = TRUE)[,1],
    parent_material = str_split(leg, pattern = "\\|", simplify = TRUE)[,2],
    texture = str_split(leg, pattern = "\\|", simplify = TRUE)[,3],
    landscape = str_trim(landscape),
    parent_material = str_trim(parent_material),
    texture = str_trim(texture),
    landscape = tolower(landscape),
    parent_material = tolower(parent_material),
    texture = tolower(texture)
  )

map_landscape <- mu_parsed_leg %>% 
  group_by(landscape) %>% 
  summarise() %>% 
  ggplot() +
  geom_sf(data = mu.simple.sf, fill = "gray80", colour = "gray30", lwd = 0.05) +
  geom_sf(aes(fill = landscape), colour = "gray30", lwd = 0.1) +
  theme_bw() +
  facet_wrap(~landscape)

map_pm <- mu_parsed_leg %>% 
  group_by(parent_material) %>% 
  summarise() %>% 
  ggplot() +
  geom_sf(data = mu.simple.sf, fill = "gray80", colour = "gray30", lwd = 0.05) +
  geom_sf(aes(fill = parent_material), colour = "gray30", lwd = 0.1) +
  theme_bw() +
  facet_wrap(~parent_material)

map_texture <- mu_parsed_leg %>% 
  group_by(texture) %>% 
  summarise() %>% 
  ggplot() +
  geom_sf(data = mu.simple.sf, fill = "gray80", colour = "gray30", lwd = 0.05) +
  geom_sf(aes(fill = texture), colour = "gray30", lwd = 0.1) +
  theme_bw() +
  facet_wrap(~texture)

## only useful for a quick preview
# writeRaster(r, file='data/mu-polygons-graph-clusters.tif', datatype='INT1U', format='GTiff', options=c("COMPRESS=LZW"), overwrite=TRUE)

# save to external formats for map / figure making
sf::write_sf(mu.simple.sf, dsn = 'data', layer = 'graph-and-mu-polygons', driver = 'ESRI Shapefile') 
sf::write_sf(mu.simple.sf, 'data/graph-and-mu-polygons.gpkg')

