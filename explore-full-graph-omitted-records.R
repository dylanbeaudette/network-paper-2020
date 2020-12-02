
library(igraph)
library(ape)
library(RColorBrewer)
library(sharpshootR)

# load filtered data
x <- readRDS('data/component-data.rda')

# load omitted data
y <- readRDS('data/omitted-copmonent-data.rda')

# re-make
z <- rbind(x, y)

# convert component data into adjacency matrix, weighted by component percentage
m <- component.adj.matrix(z, mu='mukey', co='compname', wt='comppct_r', method = 'community.matrix')

## this is the full network
# quick eval
pdf(file='ca630-network-full.pdf', width=15, height=15)
par(mar=c(0,0,0,0))
plotSoilRelationGraph(m, vertex.scaling.factor = 1.5, vertex.label.family='sans', vertex.label.cex=0.65)
dev.off()




## TODO: balance detail vs. noise in the network
## * filter by component name not component type:
## - ultic haploxeralfs
## - utlic haploxerolls


## TODO: consider making component names unique by finding collisions and then re-naming
