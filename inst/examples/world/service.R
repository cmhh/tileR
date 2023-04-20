library(sf)

sf::sf_use_s2(FALSE)

data <- st_read("data.gpkg")
options <- readRDS("options.rds")

#* @get /world/<z:int>/<x:int>/<y:int>
#* @serializer contentType list(type="image/png")
function(z, x, y) {
  f <- make_tile(data, x, y, z, "world", options, cache = "cache")
  readBin(f, "raw", n = file.info(f)$size)
}

# service <- plumber::pr("service.R")
# pr_run(service)
    
