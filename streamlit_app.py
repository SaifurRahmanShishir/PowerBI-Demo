# OutdoorCo Sales Dashboard - Streamlit version
# Run:  pip install streamlit pandas plotly
#       streamlit run streamlit_app.py
# Expects the CSVs in ../data (sales, products, stores)

import pandas as pd
import plotly.express as px
import streamlit as st

st.set_page_config(page_title="OutdoorCo Sales", layout="wide")

# Full-width charts/tables: Streamlit 1.51+ uses width="stretch",
# older versions (e.g. on Python 3.8) use use_container_width=True
NEW_API = tuple(int(x) for x in st.__version__.split(".")[:2]) >= (1, 51)
FULL = {"width": "stretch"} if NEW_API else {"use_container_width": True}

# ---- 1. Load + join (Power BI: Get Data + relationships) ----
@st.cache_data
def load():
    sales = pd.read_csv("../data/sales.csv", parse_dates=["OrderDate"])
    products = pd.read_csv("../data/products.csv")
    stores = pd.read_csv("../data/stores.csv")
    df = sales.merge(products, on="ProductID").merge(stores, on="StoreID")
    df["Year"] = df.OrderDate.dt.year
    df["Month"] = df.OrderDate.dt.to_period("M").dt.to_timestamp()
    return df

df = load()

# ---- 2. Filters (Power BI: slicers) ----
st.sidebar.header("Filters")
years = st.sidebar.multiselect("Year", sorted(df.Year.unique()), default=sorted(df.Year.unique()))
regions = st.sidebar.multiselect("Region", sorted(df.Region.unique()), default=sorted(df.Region.unique()))
cats = st.sidebar.multiselect("Category", sorted(df.Category.unique()), default=sorted(df.Category.unique()))
f = df[df.Year.isin(years) & df.Region.isin(regions) & df.Category.isin(cats)]

# ---- 3. KPIs (Power BI: DAX measures + card visuals) ----
revenue = f.Revenue.sum()
orders = f.OrderID.nunique()
aov = revenue / orders if orders else 0
gm = 1 - f.Cost.sum() / revenue if revenue else 0

st.title("OutdoorCo Sales Dashboard")
k1, k2, k3, k4 = st.columns(4)
k1.metric("Revenue", f"${revenue:,.0f}")
k2.metric("Orders", f"{orders:,}")
k3.metric("Avg Order Value", f"${aov:,.2f}")
k4.metric("Gross Margin %", f"{gm:.1%}")

# ---- 4. Charts (Power BI: drag fields onto visuals) ----
c1, c2 = st.columns(2)
monthly = f.groupby("Month", as_index=False).Revenue.sum()
c1.plotly_chart(px.line(monthly, x="Month", y="Revenue", title="Monthly revenue"), **FULL)
by_cat = f.groupby("Category", as_index=False).Revenue.sum().sort_values("Revenue")
c2.plotly_chart(px.bar(by_cat, x="Revenue", y="Category", orientation="h", title="Revenue by category"),
                **FULL)

c3, c4 = st.columns(2)
by_region = f.groupby("Region", as_index=False).Revenue.sum().sort_values("Revenue", ascending=False)
c3.plotly_chart(px.bar(by_region, x="Region", y="Revenue", title="Revenue by region"), **FULL)

# ---- 5. Table ----
top = (f.groupby("ProductName", as_index=False).Revenue.sum()
         .sort_values("Revenue", ascending=False).head(10))
c4.subheader("Top 10 products")
c4.dataframe(top, hide_index=True, **FULL)

# Drill-down (Region -> State -> Store) would need extra state + click handling here.
# In Power BI it is one toggle on the visual.