

# search cluster list element `cl` for component name `s`
searchCluster <- function(cl, s) {
  any(cl$compname == s)
}

mu.agg.membership <- function(i) {
  
  # rows are cluster indexes, columns are components
  mat <- sapply(1:nrow(i), function(m) {
    # current component name and percentage
    s.name <- i$compname[m]
    s.pct <- i$comppct_r[m]
    # trick to convert TRUE -> component percent
    sapply(clust.list, searchCluster, s = s.name) * s.pct
  })
  
  
  # tabulate membership percentages by cluster index
  rs <- rowSums(mat)
  # highest membership cluster index
  idx <- which.max(rs)
  # Shannon entropy from proportions [sum(component pct) / 100]
  H <- shannonEntropy(rs/100)
  
  res <- data.frame(
    mukey = i$mukey[1],
    cluster = idx,
    membership = rs[idx],
    maj.comp = i$compname[which.max(i$comppct_r)[1]], 
    H = H,
    stringsAsFactors = FALSE
  )
  
  return(res)
}
