## 2020 Soilscapes / Networks
## P. Roudier, D.E. Beaudette, Dion O'Neal

library(igraph)
library(RColorBrewer)
library(sharpshootR)

# load cached data
load('data/component-data.rda')

# convert component data into adjacency matrix, weighted by component percentage
m <- component.adj.matrix(x, mu='mukey', co='compname', wt='comppct_r', method = 'community.matrix')

# quick eval
par(mar=c(0,0,0,0))
plotSoilRelationGraph(m, vertex.scaling.factor = 1.5, vertex.label.family='sans', vertex.label.cex=0.65)
plotSoilRelationGraph(m, edge.scaling.factor=5, vertex.scaling.factor = 1.5, spanning.tree=0.25, vertex.label.family='sans', vertex.label.cex=0.65)

## TODO: hand-make graph for more control
# make graph using defaults specified in sharpshootR::plotSoilRelationGraph()
g <- plotSoilRelationGraph(m)

# community / cluster labels are returned as of
# https://github.com/ncss-tech/sharpshootR/commit/5797803c46b1043f658d852624d09ca15df89f17
V(g)$cluster

## important note: the graph and associated communities / colors are stable between runs (set.seed used in plotSoilRelationGraph)
## this means we can rely on the cluster numbers as an index to expert interpretation


## only need to do this once to help with expert interpretation
remakeInterp <- FALSE
if(remakeInterp) {
  # extract vertex attributes for interpretation and linking to MU data
  d <- as_data_frame(g, what='vertices')
  names(d)[1] <- 'compname'
  
  d.l <- split(d, d$cluster)
  
  # make text file with component names within each cluster
  sink(file = 'cluster-correlation-notes.txt')
  nothing <- lapply(d.l, function(i) {
    cat(paste0('--------------', i$cluster[1], '---------------\n'))
    write.table(i[, c('compname')], row.names=FALSE, col.names = FALSE)
    })
  sink()
  
  rm(nothing)
}


## 
## DEB: I need to finish the expert interpretation !!!
##


# load expert interp and add to graph attributes
d.interp <- read.csv(file='expert-interp.csv', stringsAsFactors = FALSE)
V(g)$notes <- d.interp$notes[match(V(g)$cluster, d.interp$cluster)]

# extract vertex attributes for interpretation and linking to MU data
d <- as_data_frame(g, what='vertices')
names(d)[1] <- 'compname'




# nasty hack to get a reasonable legend
leg <- unique(data.frame(cluster=V(g)$cluster, color=V(g)$color, notes=V(g)$notes, stringsAsFactors = FALSE))
leg <- leg[order(leg$cluster), ]

# save a copy of the output for expert review
pdf(file='ca630-network.pdf', width=15, height=15)
par(mar=c(0,0,2,0))
plotSoilRelationGraph(m, vertex.scaling.factor=1.5, main='Calaveras/Tuolumne Co. Soil Survey', vertex.label.family='sans', vertex.label.cex=0.65)

legend('bottomleft', legend=paste0(leg$cluster, ') ', leg$notes), col=leg$color, pch=15, ncol = 4, cex=0.5)
dev.off()



# save
save(m, g, d, leg, file='data/graph-and-pals.rda')

