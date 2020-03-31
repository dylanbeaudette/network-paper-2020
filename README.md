## Mapping soilscapes using soil co-occurence networks

P. Roudier, D.E. Beaudette, D.R.J. O'Neale

Soils are arguably the most complex material on Earth, and present an important spatial variability. Across the landscape, different soils types will often be spatially intermingled. This is reflected by soil mapping units (SMU) being often composed of more than one soil taxa. The notion of soilscape reflects the fact that a landscape can be delineated into different such spatial units "including a limited number of soil classes that are geographically distributed according to an identifiable pattern" (Lagacherie et al., 2001).

The research field of network science offers new mathematical tools to visualize and analyze existing soil survey data, and explore its complex relational interactions. In this paper, we extract and visualize pedological information by analyzing the co-occurrence of soil taxa using a network approach. 

For any level of a given hierarchical soil classification system, the co-occurence of soil taxa within and between neighbouring SMUs can be described as a network graph. The structural properties of the resulting graphs can be analyzed, and tools such as community structure detection are used to classify their different nodes. Soilscapes are then delineated by mapping the identified communities back in geographical space. This approach also gives a method for quantifying the pedological complexity of different regions based on their constituent soil types, using metrics such as graph connectivity. Different levels of granularity for both the regional data and the soil classification data allow for views at different scales.

Network science offers the opportunity of new insights from looking at existing data in a new way. Soil survey data from S-Map (NZ) and USDA-NRCS (USA) are used to illustrate the value and originality of these new approaches.


![](https://github.com/dylanbeaudette/2017Pedometrics/raw/master/static-figures/soil-profile-distance-MDS-graphs.png)


### Previous Work

   * Hole, F.D. and J.B. Campbell. 1985. Soil Landscape Analysis (book).
   
   * [Phillips, J. D. (2013), Evaluating taxonomic adjacency as a source of soil map uncertainty. Eur J Soil Sci, 64: 391–400. doi:10.1111/ejss.12049](http://onlinelibrary.wiley.com/doi/10.1111/ejss.12049/abstract)
   
   * [Phillips, J. D. (2016) Landforms as extended composite phenotypes. Earth Surf. Process. Landforms, 41: 16–26. doi: 10.1002/esp.3764](http://onlinelibrary.wiley.com/doi/10.1002/esp.3764/abstract)
   
   * others?


### Notes

  1. different ways in which you can create the adjacency matrix, and
their relationship to "reality"

  2. interpretation of min vs. max spanning trees: correlation to reality

  3. conditional pruning of edges based on quantiles of edge weight

  4. max.spanning tree + edges with weight >= specified quantile. Some of these ideas are explored here: http://ncss-tech.github.io/AQP/sharpshootR/component-relation-graph.html

  5. networks / graphs as "efficient" representation of the "most important" pair-wise distances computed from soil profile data

  6. spatial adjacency networks, or some kind of hybrid between spatial + tabular adjacency information. This is a tough one, as the weight calculation is non-trivial and (of course) method-dependent. some ideas (not many!) here: http://ncss-tech.github.io/AQP/sharpshootR/common-soil-lines.html

  7. integration of "real" geomorphological observations into the process

  8. use of adj. matrix / graph to show transition probability sequence for soil color or horizon designation

  9. use of adj. matrix / graph to show correlation decisions for horizon designations or soil series


### More notes

Just read through the Phillips (2013) paper. I noticed a couple of things:

  * indicator vs. weighted adj. matrix development based on "touching" polygons

  * relatively tiny study areas with a small "chunk" of all possible occurrence of the named soils


... Thinking about ways in which we can answer questions such as "how
is this any different than Phillips (2013, 2016) ...


So far, we have developed a robust (I think..!) method of generating
weighted adjacency matrices using occurrence probability (component
percentage) within map units and a distance-via-community-matrix
analogue. A slide describing the theory and rationale would be wise. I
can do this, but the details are in:

`sharpshootR::component.adj.matrix(method == 'community.matrix')`

The basic idea is that:

  1. Arrange occurrence frequency (component percent) with components as rows, map units as columns. This is similar to the "community matrix from the ecology world: rows are sites and columns are species, cells are percent cover. In this case rows are soil series concepts and columns are "observations" (various map units), and cells are occurrence probability.

  2. compute distance matrix (pair-wise distances by row) for series concepts using a distance metric designed for community matrix analysis

  3. convert distance matrix into similarity matrix, the similarity
  matrix _is now the adjacency matrix_.

*restated*
mapunit / component records --> reshape into "community matrix" --> standardize and compute distance matrix (methods from numerical ecology) --> convert distance matrix into similarity matrix,  this is the adjacency matrix

check out the demo file in R for details and examples

  * the community matrix: rows are the soil series / components / siblings, and columns represent observational units or evidence
  * the cells in the matrix are proportions / probabilities, and analogous to the "percent cover" in a community matrix

Why go through all this trouble? Because co-occurrence probability
(weight) matters! Both in terms of co-occurrence weight within a map
units and weights associated with spatial connectivity (length of
shared perimeter, area, etc.).


### More notes

Integration of geomorphic signature would be nice way to link the "empirical" (graph-based) vs. "theoretical" (block diagrams / soil system diagrams) soilscapes.

Initialization of the network is important: by hypothetical region, collection of named soils, taxonomic information, climate, ...

Integration of spatial connectivity (first neighbor) would help span "gaps" (missing linkages that would otherwise be added by an expert) or harmonize data at survey area boundaries (e.g. incompatible map units due to survey vintage). For example, here is the max spanning tree of "1st-neighbor, unweighted adjacency" associated with the map units of CA630:

![](https://github.com/dylanbeaudette/2017Pedometrics/raw/master/static-figures/ca630-spatial-first-neighbor-max-spanning-tree.png)

For future work: compare the map representation of these "communities / clusters" to the map representation of the tabular-data based adjacency data.


## Organize This

From Hole and Campbell, 1985 (pp. 88-89):

![](https://github.com/dylanbeaudette/2017Pedometrics/raw/master/static-figures/table_5_2_soil-landscape-analysis.png)




### In the CA630 example:

  1. the identified communities / clusters are largely a product of consistent and (I would argue) carefully constructed soil-landscape models

  2. therefore, the resulting map of communities is a fairly reasonable "general soils map" for the area

  3. the results are obvious to me, as I had a hand in crafting many of these map units--but not obvious to someone who hasn't worked in the area

  4. the graph / communities + a reasonable amount of "reading" should be enough to re-construct the major groupings of soils / landforms / lithology / climate (soil-forming factors / mental models / etc.) originally developed by the soil survey team, but usually not well preserved

  5. nodes (soil series / components) that link communities are usually common soils that occur in multiple suites of map units. this special place in the graph is probably worth investigating

