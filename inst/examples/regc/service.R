library(sf)
library(tileR)

data <- st_read("data.gpkg")

#* @get /regc/<z:int>/<x:int>/<y:int>
#* @serializer contentType list(type="image/png")
function(z, x, y) {
  f <- make_tile(data, x, y, z, "regc", cache = "/home/cmhh/Work/rpkg/tileR/regc/cache")
  readBin(f, "raw", n = file.info(f)$size)
}
