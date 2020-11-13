library(aqp)
library(soilDB)
library(sharpshootR)

d <- readRDS('data/vertices_df.rda')

# list of records by cluster number
# used to search for map unit component names
clust.list <- split(d, d$cluster)


x <- lapply(clust.list, function(i) {
  o <- fetchOSD(i$compname)
  site(o)$cluster <- i$cluster[1]
  
  return(o)
})

z <- combine(x)

sapply(clust.list, nrow)

plotSPC(x[[7]])

SoilTaxonomyDendrogram(x[[7]], width = 0.3)

lapply(x, function(i) {
  table(i$subgroup)
})

lapply(x, function(i) {
  sdc <- getSoilDepthClass(i)
  round(prop.table(table(sdc$depth.class)), 2)
})

sapply(x, function(i) {
  round(prop.table(table(i$tax_partsize)), 2)
})

sapply(x, function(i) {
  round(prop.table(table(i$tax_minclass)), 2)
})

sapply(x, function(i) {
  round(prop.table(table(i$greatgroup)), 2)
})


lapply(x, function(i) {
  sdc <- getSoilDepthClass(i)
  quantile(sdc$depth)
})


## soil color by cluster
a <- aggregateColor(z, groups = 'cluster', k = 8)

par(mar = c(4, 1, 1, 1))
aggregateColorPlot(a, print.label = FALSE)



