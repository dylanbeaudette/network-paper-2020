## 2020 Soilscapes / Networks
## P. Roudier, D.E. Beaudette, Dion O'Neal

library(sharpshootR)
library(soilDB)
library(rgdal)
library(sp)


## get component data from SDA
# select by survey area(s)
q <- "SELECT 
component.mukey, component.cokey, comppct_r, LOWER(compname) AS compname, compkind, majcompflag
FROM legend
INNER JOIN mapunit ON mapunit.lkey = legend.lkey
LEFT OUTER JOIN component ON component.mukey = mapunit.mukey
WHERE legend.areasymbol IN ('CA630')
AND compkind != 'Miscellaneous Area' ;"

# run query, process results, and return as data.frame object
x <- SDA_query(q)

# save a copy pre-filtering, 
# it will be helpful to know which mu / components are excluded by the filtering step below
x.all <- x

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

# 3. consider removing family level components:
#    con: lose riparian zones and similar low-area components
#    pro: leaving network is too dense because family level component names collide
x <- x[x$compkind != 'Family', ]

## MAYBE:
# 4. need to exclude family level components by name: there are some (table mountain) that we need to keep


## we are left with Major / Minor components
## Series and Taxadjunct component kinds
table(x$compkind)
table(x$majcompflag)


## keep track of records that have been filtered
filtered.cokey <- setdiff(
  unique(x.all$cokey),
  unique(x$cokey)
)

# these are the component records we have left out
x.left.out <- x.all[x.all$cokey %in% filtered.cokey, ]
sort(table(x.left.out$compname), decreasing = TRUE)

## get / filter spatial data
# CA630 too large to request in single query to SDA
# ~ 7 minutes on home network connection
mu <- fetchSDA_spatial(x = unique(x$mukey), by.col = 'mukey', add.fields = 'mapunit.muname', chunk.size = 2)


## convert to locally-appropriate projected CRS
mu <- spTransform(mu, CRS('+proj=utm +zone=10 +datum=NAD83'))

# save for later
# two files, in case we need to re-make one or the other
if(!dir.exists('data')) {
  dir.create('data')
}

# these are the records which will carry-forward into the network and spatial data
saveRDS(x, file='data/component-data.rda')
saveRDS(mu, file='data/spatial-data.rda')

# records which have been removed by filtering on component name, component type
saveRDS(x.left.out, file = 'data/omitted-copmonent-data.rda')


