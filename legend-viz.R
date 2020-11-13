library(data.tree)

x <- read.csv(file = 'expert-interp.csv', stringsAsFactors = FALSE)

x$path <- with(x, 
               paste(
                 'CA630',
                 MLRA.connotative,
                 STR,
                 pmkind,
                 pmorigin,
                 ES,
                 cluster,
                 sep = '#'
               )
)

x <- as.Node(x, pathName = 'path', pathDelimiter = '#')

sink('data.tree-legend.txt')
print(x)
sink()
