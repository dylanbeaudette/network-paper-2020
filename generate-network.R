## 2020 Soilscapes / Networks
## P. Roudier, D.E. Beaudette, Dion O'Neal

library(igraph)
library(RColorBrewer)
library(sharpshootR)

# load cached data
x <- readRDS('data/component-data.rda')

# convert component data into adjacency matrix, weighted by component percentage
m <- component.adj.matrix(x, mu='mukey', co='compname', wt='comppct_r', method = 'community.matrix')

# quick eval
# par(mar=c(0,0,0,0))
# plotSoilRelationGraph(m, vertex.scaling.factor = 1.5, vertex.label.family='sans', vertex.label.cex=0.65)
# plotSoilRelationGraph(m, edge.scaling.factor=5, vertex.scaling.factor = 1.5, spanning.tree=0.25, vertex.label.family='sans', vertex.label.cex=0.65)

## TODO: hand-make graph for more control
# make graph using defaults specified in sharpshootR::plotSoilRelationGraph()
# g <- plotSoilRelationGraph(m)

# generate graph
g <- graph.adjacency(m, mode = "upper", weighted = TRUE)
weight <- E(g)$weight

# transfer names
V(g)$label <- V(g)$name 

# adjust edge width based on weight
edge.scaling.factor <- 1
E(g)$width <- sqrt(E(g)$weight) * edge.scaling.factor
# extract communities
set.seed(20201113)
g.com <- cluster_fast_greedy(g)
# community metrics
g.com.length <- length(g.com)
g.com.membership <- membership(g.com)
# save membership to original graph
# this is based on vertex order
V(g)$cluster <- g.com.membership

# colors for communities: choose color palette based on number of communities
if(g.com.length <= 9 & g.com.length > 2) cols <- brewer.pal(n=g.com.length, name = 'Set1') 
if(g.com.length < 3) cols <- brewer.pal(n = 3, name = 'Set1')
if(g.com.length > 9) cols <- colorRampPalette(brewer.pal(n=9, name = 'Set1'))(g.com.length)

# set colors based on community membership
vertex.alpha <- 0.65
cols.alpha <- scales::alpha(cols, vertex.alpha)
V(g)$color <- cols.alpha[g.com.membership]

# get an index to edges associated with series specified in 's'
el <- get.edgelist(g)
s <- '' # default behaviour
idx <- unique(c(which(el[, 1] == s), which(el[, 2] == s)))

# set default edge color
edge.col <- grey(0.5)
edge.transparency <- 1
edge.highlight.col <- 'royalblue'

E(g)$color <- scales::alpha(edge.col, edge.transparency)
# set edge colors based on optional series name to highlight
E(g)$color[idx] <- scales::alpha(edge.highlight.col, edge.transparency)





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


# load expert interpretation and add to graph attributes
d.interp <- read.csv(file = './expert-interp.csv', stringsAsFactors = FALSE)
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
# save(m, g, d, leg, file='./data/graph-and-pals.rda')

saveRDS(m, 'data/adj_mat.rda')
saveRDS(g, 'data/graph.rda')
saveRDS(d, 'data/vertices_df.rda')
saveRDS(leg, 'data/legend.rda')

