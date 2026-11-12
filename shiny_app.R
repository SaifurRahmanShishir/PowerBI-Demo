# OutdoorCo Sales Dashboard - R Shiny version
# Run:  install.packages(c("shiny", "bslib", "dplyr", "ggplot2", "readr", "scales"))
#       shiny::runApp("shiny_app.R")
# Expects the CSVs in ../data (sales, products, stores)

library(shiny)
library(bslib)
library(dplyr)
library(ggplot2)
library(readr)
library(scales)

# ---- 1. Load + join (Power BI: Get Data + relationships) ----
sales    <- read_csv("../data/sales.csv", show_col_types = FALSE)
products <- read_csv("../data/products.csv", show_col_types = FALSE)
stores   <- read_csv("../data/stores.csv", show_col_types = FALSE)

df <- sales |>
  inner_join(products, by = "ProductID") |>
  inner_join(stores, by = "StoreID") |>
  mutate(Year  = as.integer(format(OrderDate, "%Y")),
         Month = as.Date(format(OrderDate, "%Y-%m-01")))

# ---- 2. UI: filters (Power BI: slicers) + layout ----
ui <- page_sidebar(
  title = "OutdoorCo Sales Dashboard",
  sidebar = sidebar(
    checkboxGroupInput("year", "Year", sort(unique(df$Year)), selected = unique(df$Year)),
    checkboxGroupInput("region", "Region", sort(unique(df$Region)), selected = unique(df$Region)),
    checkboxGroupInput("cat", "Category", sort(unique(df$Category)), selected = unique(df$Category))
  ),
  layout_columns(
    value_box("Revenue", textOutput("rev")),
    value_box("Orders", textOutput("ord")),
    value_box("Avg Order Value", textOutput("aov")),
    value_box("Gross Margin %", textOutput("gm"))
  ),
  layout_columns(
    card(card_header("Monthly revenue"), plotOutput("trend")),
    card(card_header("Revenue by category"), plotOutput("bycat"))
  ),
  layout_columns(
    card(card_header("Revenue by region"), plotOutput("byregion")),
    card(card_header("Top 10 products"), tableOutput("top"))
  )
)

# ---- 3. Server: reactive filter, KPIs, charts ----
server <- function(input, output, session) {
  f <- reactive({
    df |> filter(Year %in% input$year, Region %in% input$region, Category %in% input$cat)
  })

  # KPIs (Power BI: DAX measures)
  output$rev <- renderText(dollar(sum(f()$Revenue)))
  output$ord <- renderText(comma(n_distinct(f()$OrderID)))
  output$aov <- renderText(dollar(sum(f()$Revenue) / max(1, n_distinct(f()$OrderID)), accuracy = 0.01))
  output$gm  <- renderText(percent(1 - sum(f()$Cost) / max(1, sum(f()$Revenue)), accuracy = 0.1))

  output$trend <- renderPlot({
    f() |> group_by(Month) |> summarise(Revenue = sum(Revenue)) |>
      ggplot(aes(Month, Revenue)) + geom_line(linewidth = 1) +
      scale_y_continuous(labels = dollar) + theme_minimal()
  })

  output$bycat <- renderPlot({
    f() |> group_by(Category) |> summarise(Revenue = sum(Revenue)) |>
      ggplot(aes(Revenue, reorder(Category, Revenue))) + geom_col() +
      scale_x_continuous(labels = dollar) + labs(y = NULL) + theme_minimal()
  })

  output$byregion <- renderPlot({
    f() |> group_by(Region) |> summarise(Revenue = sum(Revenue)) |>
      ggplot(aes(reorder(Region, -Revenue), Revenue)) + geom_col() +
      scale_y_continuous(labels = dollar) + labs(x = NULL) + theme_minimal()
  })

  output$top <- renderTable({
    f() |> group_by(ProductName) |> summarise(Revenue = sum(Revenue)) |>
      arrange(desc(Revenue)) |> head(10) |> mutate(Revenue = dollar(Revenue))
  })

  # Drill-down (Region -> State -> Store) would need click events,
  # a reactiveVal for the current level, and a "back" button.
  # In Power BI it is one toggle on the visual.
}

shinyApp(ui, server)
