## does it make sense to put the sibling network into context via cousins?

library(soilDB)
library(sharpshootR)
library(igraph)

# takes a while to run, there will be duplicates in counsins here
s <- siblings('amador', component.data = TRUE, cousins = TRUE)

sib <- s$sib.data
cous <- s$cousin.data

## subset siblings
# series
sib <- sib[which(sib$compkind == 'Series'), ]

## subset cousins
# major components and series
cous <- cous[which(cous$majcompflag == 'Yes' & cous$compkind == 'Series'), ]

# combine sibling + cousin data, remove duplicates
d <- unique(rbind(sib, cous))

# keep track of cousins
cnames <- unique(cous$compname)
snames <- unique(sib$compname)

only.cousins <- setdiff(cnames, snames)

# convert into adjacency matrix
m <- component.adj.matrix(d, mu = 'mukey', co = 'compname', wt = 'comppct_r')

par(mar=c(1,1,1,1))

g <- plotSoilRelationGraph(m, s='Amador', vertex.scaling.factor=2,  edge.col=grey(0.5), edge.highlight.col='black', vertex.label.family='sans')

idx <- which(V(g)$label %in% only.cousins)
V(g)$color[idx] <- 'grey'

plot(g)



