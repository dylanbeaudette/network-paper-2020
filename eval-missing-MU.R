library(aqp)
library(soilDB)

x <- readRDS('data/missing-mukey.rds')

IS <- format_SQL_in_statement(x)

## get component data from SDA
# select by survey area(s)
qq <- sprintf(
"SELECT 
muname,
component.mukey, comppct_r, LOWER(compname) AS compname, compkind, majcompflag
FROM legend
INNER JOIN mapunit ON mapunit.lkey = legend.lkey
LEFT OUTER JOIN component ON component.mukey = mapunit.mukey
WHERE mapunit.mukey IN %s ;",
IS
)

# run query, process results, and return as data.frame object
m <- SDA_query(qq)

head(m)

table(m$muname)

table(m$compkind)
sort(table(m$compname), decreasing = TRUE)
