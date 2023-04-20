## `tileR`

This repository contains a simple package which let's users create a simple slippy tile service from an `sf` object.  It is intended for local testing with leaflet--particularly for relatively large `sf` objects.

## Example

Assume you have a local geopackage called `world.gpkg` containing country outlines.  We can make a basic WMS-like service by running:

```r
library(sf)
library(tileR)
library(plumber)

world <- st_read(system.file("examples/world/data.gpkg", package = "tileR"))

# optonal--add some basic styling
value <- world[, "name"] |> st_drop_geometry() |> unlist(use.names = FALSE)
cols  <- rainbow(10)[sample(10, nrow(world), replace = TRUE)]

pal <- function(x) {
 cols[which(x == value)]
}

options <- plotoptions(
  pal = pal, value = "name"
)

create_service(world, "world", "world", options)

service <- plumber::pr("world/service.R")
pr_run(service)
```

This will start a service on a random port, and the service can be used in `leaflet`'s `addTiles` function.  For example, if the port is 5086, the URL template would be:

    http://localhost:5086/world/{z}/{x}/{y}
    
We could display this in a leaflet map (in a different session) by running:

```r
library(leaflet)

leaflet() |> 
  addTiles() |> 
  addTiles(urlTemplate = "http://localhost:5086/world/{z}/{x}/{y}")

```

![](media/example.webp)
