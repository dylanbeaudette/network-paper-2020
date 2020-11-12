## 2020 Soilscapes / Networks
## P. Roudier, D.E. Beaudette, Dion O'Neale

## data sources:
## 1. SSURGO/SDA components: component names / percentages, map unit keys
## 2. SSURGO/SDA linework: polygons, map unit keys
## 3. "expert interpretation"


## re-cache spatial / tabular data
source('compile-data.R')

## re-make adj. matrix and graph
# interpret clusters part-way through
source('generate-network.R')

## combine with spatial data
source('join-network-spatial-data.R')


