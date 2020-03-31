## 2020 Soilscapes / Networks
## P. Roudier, D.E. Beaudette, Dion O'Neal

library(sharpshootR)
library(soilDB)
library(rgdal)
library(sp)


## get component data from SDA
# select by survey area(s)
q <- "SELECT 
component.mukey, comppct_r, LOWER(compname) AS compname, compkind, majcompflag
FROM legend
INNER JOIN mapunit ON mapunit.lkey = legend.lkey
LEFT OUTER JOIN component ON component.mukey = mapunit.mukey
WHERE legend.areasymbol IN ('CA630')
AND compkind != 'Miscellaneous Area' ;"

# run query, process results, and return as data.frame object
x <- SDA_query(q)

# quick eval: OK
table(x$compkind)
table(x$majcompflag)

sort(table(x$compname), decreasing = TRUE)

# hmm..
x$compname[x$compkind == 'Taxon above family']
x$compname[x$compkind == 'Family']

## prepare / filter component data

# 1. keeping major + minor components, most structure is lost without minors

# 2. consider removing taxa above family
x <- x[x$compkind != 'Taxon above family', ]

# 3. removing family level components likely too harsh, as we lose riparian zones and similar low-area components


## check: OK
head(x)


## get / filter spatial data
# CA630 too large to request in single query to SDA
# ~ 7 minutes on home network connection
mu <- fetchSDA_spatial(x=unique(x$mukey), by.col='mukey', add.fields='mapunit.muname', chunk.size = 2)


## convert to locally-appropriate projected CRS
mu <- spTransform(mu, CRS('+proj=utm +zone=10 +datum=NAD83'))

# save for later
# two files, in case we need to re-make one or the other
save(x, file='data/component-data.rda')
save(mu, file='data/spatial-data.rda')

