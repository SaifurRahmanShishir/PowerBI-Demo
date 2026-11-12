# Power BI for Shiny Users – talk pack

## What's here

| Path | What it is | Used in |
|---|---|---|
| `data/OutdoorCo_Sales.xlsx` | Clean star schema: Sales (61,183 rows), Products, Stores, Regions, Calendar, Targets | Parts 2, 3, 4, 5 |
| `data/*.csv` | The same tables as CSVs (the Shiny and Streamlit apps read these) | Part 2 |
| `data/raw_client_export_Q4_2025.csv` | Deliberately messy client file (junk header lines, blanks, duplicates, 10 region spellings, 3 date formats, "$1,234.56" text) | Part 4 |
| `data/client_drops/sales_2026_08/09/10.csv` | Monthly client drops | Part 6 |
| `data/client_drops/NEW_sales_2026_11.csv` | The "new file" you drop in live (671 orders, Nov 1–10) | Part 6 |
| `code/shiny_app.R` | The dashboard in R Shiny | Part 2 |
| `code/streamlit_app.py` | The same dashboard in Streamlit | Part 2 |
| `code/dax_measures.dax` | All DAX measures, plus a DAX query for the web query view | Parts 2, 4, 5 |
| `code/power_query_steps.m` | M for cleaning the messy file, and for combining a SharePoint folder | Parts 4, 6 |

All data is synthetic. Planted story for the drill-down: tents ran out of stock in the three Southwest stores in Aug–Sep 2026.

## Run the code apps (from the `code` folder)

```
pip install streamlit pandas plotly
streamlit run streamlit_app.py
```

```r
install.packages(c("shiny", "bslib", "dplyr", "ggplot2", "readr", "scales"))
shiny::runApp("shiny_app.R")
```

## Before the talk (about 30 minutes, all in the browser)

1. Sign in at app.powerbi.com with your work/school account. Check that **Create › Get data** works and that a semantic model opens in **Edit** mode (some organizations turn web editing off).
2. **Main report (Parts 2–5):** Create › Get data › Excel workbook › `OutdoorCo_Sales.xlsx` (from OneDrive) › load all 6 tables. In the model view create relationships:
   Sales[ProductID] → Products, Sales[StoreID] → Stores, Stores[Region] → Regions, Sales[OrderDate] → Calendar[Date], Targets[MonthStart] → Calendar[Date], Targets[Region] → Regions.
   Mark Calendar as the date table. Add the measures from `dax_measures.dax`. Build the dashboard page from the "dashboard" slide and a matrix with Regions[Region] › Products[Category] › Products[SubCategory] for the drill-down.
3. **Refresh demo (Part 6):** upload the three monthly CSVs (not NEW_…) to a OneDrive/SharePoint folder named `client_drops`. Create › Get data › SharePoint folder › your site URL › filter Folder Path to `client_drops` › Combine › line chart of Revenue by OrderDate. In the semantic model's settings, sign in to the data source and set a scheduled refresh.
4. Run `streamlit run streamlit_app.py` once so the first load is cached.
5. Fallback: keep a second copy of each report already finished in another tab.

Speaker notes in the slide deck have the clock time, what to say, and demo steps for every slide.
