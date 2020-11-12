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


