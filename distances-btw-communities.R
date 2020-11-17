library(sf)
library(magrittr)
library(dplyr)
library(cluster)

mm <- st_read('data/mu-with-cluster-membership.gpkg')
x <- readRDS('data/component-data.rda')
  
mu_mb <- mm %>% 
  st_set_geometry(NULL) %>% 
  dplyr::select(mukey, cluster, membership, H) %>% 
  dplyr::group_by(mukey) %>% 
  dplyr::summarise(
    cluster =  unique(cluster), 
    membership = unique(membership), 
    H = unique(H)
  )

xx <- dplyr::left_join(x, mu_mb)

comps <- unique(xx$compname)

.tabulate_comps <- function(cl) {
  cur_data <- dplyr::filter(xx, cluster == !!cl)
  cur_tbl <- table(factor(cur_data$compname, levels = comps))
  cur_tbl
}

mat_com <- lapply(
  1:12,
  .tabulate_comps
) %>% 
  do.call(rbind, .)

dd <- dist(mat_com)

dd %>% 
  agnes(method = "gaverage") %>% 
  as.dendrogram() %>% 
  plot()
  