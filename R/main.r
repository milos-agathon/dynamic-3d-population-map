# 1. PACKAGES

libs <- c(
    "sf", "R.utils",
    "scales", "deckgl",
    "htmlwidgets"
)

installed_libraries <- libs %in% rownames(
    installed.packages()
)

if (any(installed_libraries == F)) {
    install.packages(
        libs[!installed_libraries]
    )
}

invisible(
    lapply(
        libs,
        library,
        character.only = T
    )
)

# 2. KONTUR POPULATION DATA

options(timeout = 300)
url <- "https://geodata-eu-central-1-kontur-public.s3.amazonaws.com/kontur_datasets/kontur_population_CH_20231101.gpkg.gz"
filename <- basename(url)

download.file(
    url = url,
    destfile = filename,
    mode = "wb"
)

R.utils::gunzip(
    filename,
    remove = F
)

# 3. LOAD DATA

pop_df <- sf::st_read(
    dsn = gsub(
        pattern = ".gz",
        replacement = "",
        x = filename
    )
) |>
    sf::st_transform(
        crs = "EPSG:4326"
    )

# 4. PALETTE

pal <- scales::col_quantile(
    "viridis",
    pop_df$population,
    n = 6
)

pop_df$color <- pal(
    pop_df$population
)

# 5. INTERACTIVE 3D MAP

properties <- list(
    stroked = T,
    filled = T,
    extruded = T,
    wireframe = F,
    elevationScale = 1,
    getFillColor = ~color,
    getLineColor = ~color,
    getElevation = ~population,
    getPolygon = deckgl::JS(
        "d => d.geom.coordinates"
    ),
    tooltip = "Population: {{population}}",
    opacity = .25
)

# 46.801111, 8.226667

map <- deckgl::deckgl(
    latitude = 46.801111,
    longitude = 8.226667,
    zoom = 6, pitch = 45
) |>
    deckgl::add_polygon_layer(
        data = pop_df,
        properties = properties
    ) |>
    deckgl::add_basemap(
        deckgl::use_carto_style()
    )

# 6. EXPORT AS HTML

htmlwidgets::saveWidget(
    map, file = "map.html",
    selfcontained = F
)

