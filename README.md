## `tileR`

This repository contains a simple package which let's users create a simple slippy tile service from an `sf` object.  It is intended for local testing with leaflet--particularly for relatively large `sf` objects.

## Example

Assume you have a local geopackage called `world.gpkg` containing country outlines.  We can make a basic WMS-like service by running:

```r
library(sf)
library(tileR)
library(plumber)

rc <- st_read("world.gpkg")

create_service(rc, "world", "world")

service <- plumber::pr("world/service.R")
pr_run(service)
```

This will start a service on a random port, and the service can be used in `leaflet`'s `addTiles` function.  For example, if the port is 9772, the URL template would be:

    http://localhost:9772/world/{z}/{x}/{y}
    
We could display this in a leaflet map (in a different session) by running:

```r
library(leaflet)

leaflet() |> 
  addTiles() |> 
  addTiles(urlTemplate = "http://localhost:9772/world/{z}/{x}/{y}")

```

![](media/example.webp)

It's pretty under-cooked for now--just a rough PoC I put together one afternoon.  But I'll probably add some basic styling functionality soon, like the ability to fill polygons etc.
