## 2020 Soilscapes / Networks
## P. Roudier, D.E. Beaudette, Dion O'Neal


library(igraph)
library(RColorBrewer)
library(sharpshootR)
library(plyr)

library(rgdal)
library(rgeos)
library(sp)
library(raster)
library(rasterVis)


# load relevant data
load('data/component-data.rda')
load('data/spatial-data.rda')
load('data/cached-graph.rda')


## associate nodes with map units, two options:
## simple majority:
## membership by component percent:

# simple method: reduce musym--compname to 1:1 via majority rule
# assumption: there are never >1 components with the same name
# caveat: some map unit symbols will have NO association with graph, based on previous subsetting rules: NULL delineations on map
mu.agg.majority <- function(i) {
  # keep the largest component
  idx <- order(i$comppct_r, decreasing = TRUE)
  res <- i[idx, ][1, , drop=FALSE]
  return(res)
}


# create mu -> graph lookup table
mu.LUT <- ddply(x, 'mukey', mu.agg.majority)


# compnames in graph but not mu.LUT
setdiff(V(g)$name, unique(mu.LUT$compname))

# in mu.LUT but not in graph
setdiff(unique(mu.LUT$compname), V(g)$name)

# join musym -- graph via component name
d <- merge(mu.LUT, d, by='compname', sort=FALSE)

# join() / merge() do strange things in the presence of NA...
d.no.na <- d[which(!is.na(d$mukey)), ]

# samity-check: musym in map missing from graph--musym association
# none missing: good
setdiff(unique(x$musym), d.no.na$musym)

# sanity check: there should be a 1:1 relationship between
# OK
all(rowSums(as.matrix(table(d$mukey, d$cluster))) < 2)


## note: there are a couple clusters without corresponding polygons!
# this breaks in the presence of NA...
mu <- sp::merge(mu, d.no.na, by.x='mukey', by.y='mukey')

# filter-out polygons with no assigned cluster
mu <- mu[which(!is.na(mu$cluster)), ]

## TODO: investigate map units (musym) that aren't represented in the graph
# x[which(x$mukey %in% unique(mu[which(is.na(mu$cluster)), ]$mukey)), ]

# aggregate geometry based on cluster labels
mu.simple <- gUnionCascaded(mu, as.character(mu$cluster))
mu.simple.spdf <- SpatialPolygonsDataFrame(mu.simple, data=data.frame(ID=sapply(slot(mu.simple, 'polygons'), slot, 'ID')), match.ID = FALSE)



## viz using raster methods
# this assumes projected CRS
r <- rasterize(mu, raster(extent(mu), resolution=90), field='cluster')
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

# make a composite legend label
rat$legend <- paste0(rat$ID, ') ', rat$notes)

# pack RAT back into raster
levels(r) <- rat

# sanity-check: do the simplified polgons have the same IDs (cluster number) as raster?
# yes
e <- sampleRegular(r, 1000, sp=TRUE)
e$check <- over(e, mu.simple.spdf)$ID
e <- as.data.frame(e)
e <- na.omit(e)
all(as.character(e$layer) == as.character(e$check))




# simple plot in R, colors hard to see
png(file='graph-communities-mu-data.png', width=1600, height=1200, type='cairo', antialias = 'subpixel')
levelplot(r, col.regions=levels(r)[[1]]$color, xlab="", ylab="", att='legend', maxpixels=1e5, colorkey=list(space='right', labels=list(cex=1.25)))
dev.off()

# save to external formats for map / figure making
writeOGR(mu.simple.spdf, dsn='data', layer='graph-and-mu-polygons', driver='ESRI Shapefile', overwrite_layer = TRUE)
writeRaster(r, file='data/mu-polygons-graph-clusters.tif', datatype='INT1U', format='GTiff', options=c("COMPRESS=LZW"), overwrite=TRUE)



