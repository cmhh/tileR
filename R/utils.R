library(sf)

#' Convert lng/lat to xy grid position
#'
#' @export
#'
#' @param lng longitude
#' @param lat latitude
#' @param zoom zoom level
#' @return xy representing top-left corner of a slippy-map tile.
xy <- function(lng, lat, zoom) {
  n <- 2 ^ zoom
  lat_rad <- lat * pi / 180
  list(
    x = floor((lng + 180) / 360 * n),
    # y = floor((1 - log(tan(lat * pi / 180) + 1 / cos(lat * pi / 180)) / pi) / 2 * n)
    y = floor((1 - asinh(tan(lat * pi / 180)) / pi) / 2 * n)
  )
}

#' Convert xy to lnglat
#'
#' @export
#'
#' @param x x-position on grid
#' @param y y-position on grid
#' @param zoom zoom level
#' @return lng/lat representing top left corner of slippy-map tile
lnglat <- function(x, y, zoom) {
  n <- 2^zoom
  lng_deg <- x / n * 360 - 180
  lat_rad <- atan(sinh(pi * (1 - 2 * y / n)))
  lat_deg <- lat_rad * 180 / pi
  list(lng = lng_deg, lat = lat_deg)
}

#' Bounding box for xy position as lng/lat
#'
#' @export
#'
#' @param x x-position on grid
#' @param y y-position on grid
#' @param zoom zoom level
#' @return list representing bounding box--top left and bottom-right corners.
bbox <- function(x, y, zoom) {
  l <- list(
    tl = lnglat(x, y, zoom),
    tr = lnglat(x + 1, y, zoom),
    br = lnglat(x + 1, y + 1, zoom),
    bl = lnglat(x, y + 1, zoom)
  )

  xs <- sapply(l, \(x) x$lng)
  ys <- sapply(l, \(x) x$lat)

  st_polygon(list(matrix(c(xs, xs[1], ys, ys[1]), ncol = 2))) |>
    st_sfc(crs = 4326)
}

#' get pixel size in degrees
#'
#' @param bb bounding box created by `bbox` function
#' @return vector with width and height of a pixel in degrees
pixelsize <- function(bb) {
  coords <- st_coordinates(bb)
  w <- max(coords[,1]) - min(coords[,1])
  h <- max(coords[,2]) - min(coords[,2])
  c(w,h) / 256
}

#' buffer bounding box
#'
#' @param bb bounding box created by `bbox` function
#' @param pixels buffer size in pixels
#' @return buffered bounding box
buffer <- function(bb, pixels = 1) {
  wh <- pixelsize(bb)
  XY <- st_coordinates(bb)[, c(1,2)]
  xs <- XY[,1]
  ys <- XY[,2]
  xs[xs == min(xs)] <- min(xs) - wh[1] * pixels
  xs[xs == max(xs)] <- max(xs) + wh[1] * pixels
  ys[ys == min(ys)] <- min(ys) - wh[2] * pixels
  ys[ys == max(ys)] <- max(ys) + wh[2] * pixels

  st_polygon(list(matrix(c(xs, ys), ncol = 2))) |>
    st_sfc(crs = 4326)
}

#' create directory if it doesn't exist
#'
#' @param d directory name
#' @return boolean
createifnot <- function(d) {
  if (!dir.exists(d)) dir.create(d, recursive = TRUE)
  dir.exists(d)
}

#' empty tile
blank <- function() {
  plot(
    NULL,
    xlim = c(0,0),
    ylim = c(0, 0),
    xaxt = "n",
    yaxt = "n",
    axes = FALSE,
    xlab = "",
    ylab = ""
  )
}

#' Plotting options
#'
#' @export
#'
#' @param pal function which returns fill color
#' @param value column holding value for pal
#' @param col fill color, not used if `pal` and `value` provided
#' @param border border color
#' @param lwd line width
#' @param lty line type
plotoptions <- function(...) {
  args <- list(...)

  opts <- list(
    col = NA, lwd = 1, lty = 1, border = "#000000"
  )

  for (op in names(args)) {
    opts[[op]] <- args[[op]]
  }

  opts
}

#' styled plot
splot <- function(x, options, add = TRUE) {
  fill <-
    if (!is.null(options$pal) & !is.null(options$value)) {
      sapply(
        x[, options$value] |> st_drop_geometry() |> unlist(use.names = FALSE),
        options$pal,
        USE.NAMES = FALSE
      )
    } else if (!is.null(options$col)) {
      options$col
    } else NA

  plot(
    st_geometry(x) |> st_transform(3857),
    col = fill,
    border = options$border,
    lwd = options$lwd,
    lty = options$lty,
    add = add
  )
}

#' create tile image
#'
#' @export
#'
#' @param data an sf object
#' @param x x-grid
#' @param y y-grid
#' @param zoom zoom level
#' @param path name of tileset folder
#' @param style Not implemented.  Intended to support basic styling.
#' @param cache directory for cache
#' @return path to tile
make_tile <- function(data, x, y, zoom, path, options = plotoptions(), cache = tempdir()) {
  root <- sprintf("%s/%s/%s/%s", cache, path, zoom, x)
  if (!createifnot(root)) stop("Could not create folder.")

  f <- sprintf("%s/%s.png", root, y)

  if (!file.exists(f)) {
    bb0 <- bbox(x, y, zoom)
    bb1 <- buffer(bb0, pixels = 2)
    suppressWarnings(suppressMessages(clipped <- st_intersection(data, bb1)))
    border <- st_coordinates(bb0 |> st_transform(3857))[, c(1,2)]

    png(f, width = 256, height = 256, bg = "transparent")
    par(mar = c(0, 0, 0, 0), oma = c(0, 0, 0, 0), mai = c(0, 0, 0, 0))

    if (nrow(clipped) == 0) {
      blank()
    } else {
      plot(
        c(min(border[,1]), max(border[,1])),
        c(min(border[,2]), max(border[,2])),
        type = "n",
        xaxs = "i", yaxs = "i", xaxt = "n", yaxt = "n", axes = FALSE,
        xlab = NA, ylab = NA
      )

      splot(
        clipped, options, add = TRUE
      )
    }

    dev.off()
  }

  if (!file.exists(f)) stop("No image found.")

  f
}

#' Create a service.
#'
#' @export
#'
#' @param data an sf object
#' @param path service end-point name
#' @param dir service directory
create_service <- function(data, path, dir, options = plotoptions()) {
  dir.create(path, recursive = TRUE)

  st_write(
    data |> st_transform(4326),
    sprintf("%s/data.gpkg", path),
    append = FALSE
  )

  saveRDS(options, sprintf("%s/options.rds", path))

  service <- sprintf(
    'library(sf)
    |
    |sf::sf_use_s2(FALSE)
    |
    |data <- st_read("data.gpkg")
    |options <- readRDS("options.rds")
    |
    |#* @get /%s/<z:int>/<x:int>/<y:int>
    |#* @serializer contentType list(type="image/png")
    |function(z, x, y) {
    |  f <- make_tile(data, x, y, z, "%s", options, cache = "cache")
    |  readBin(f, "raw", n = file.info(f)$size)
    |}
    |
    |# service <- plumber::pr("service.R")
    |# pr_run(service)
    ',
    path, path
  )

  writeLines(gsub("( )+\\|", "", service), sprintf("%s/service.R", dir))
}
