library(sf)
library(tileR)

data <- st_read("data.gpkg")

#* @get /world/<z:int>/<x:int>/<y:int>
#* @serializer contentType list(type="image/png")
function(z, x, y) {
  f <- make_tile(data, x, y, z, "world", cache = "/home/cmhh/Work/rpkg/tileR/world/cache")
  readBin(f, "raw", n = file.info(f)$size)
}
