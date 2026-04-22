# RetailPulse Analytics Dashboard
# Streamlit in Snowflake — reads directly from Gold layer
# Role: REPORTER_ROLE | Warehouse: REPORTING_WH

import streamlit as st
import pandas as pd
import plotly.express as px
import plotly.graph_objects as go
from snowflake.snowpark.context import get_active_session

# ── Page config ──────────────────────────────────────────────────────────────
st.set_page_config(
    page_title="RetailPulse Analytics",
    page_icon="🛍️",
    layout="wide",
    initial_sidebar_state="expanded"
)

# ── Snowflake session (auto-injected by SiS — no credentials needed) ─────────
session = get_active_session()

# ── Custom CSS ───────────────────────────────────────────────────────────────
st.markdown("""
<style>
    .metric-card {
        background: linear-gradient(135deg, #1B3A5C, #0D6E8A);
        padding: 20px;
        border-radius: 10px;
        color: white;
        text-align: center;
    }
    .metric-value {
        font-size: 2rem;
        font-weight: bold;
        color: #00D4FF;
    }
    .metric-label {
        font-size: 0.9rem;
        color: #B0C4D8;
        margin-top: 4px;
    }
    .section-header {
        color: #1B3A5C;
        border-bottom: 3px solid #0D6E8A;
        padding-bottom: 8px;
        margin-bottom: 20px;
    }
</style>
""", unsafe_allow_html=True)

# ── Data loading functions ────────────────────────────────────────────────────
@st.cache_data(ttl=300)  # Cache for 5 minutes
def load_kpis():
    return session.sql("""
        SELECT
            COUNT(*)                                          AS total_orders,
            SUM(revenue)                                      AS total_revenue,
            AVG(revenue)                                      AS avg_order_value,
            ROUND(SUM(is_returned) / COUNT(*) * 100, 2)       AS return_rate_pct,
            SUM(quantity)                                     AS total_units_sold,
            COUNT(DISTINCT customer_sk)                       AS unique_customers
        FROM DEV_DB.GOLD.FCT_ORDERS
        WHERE order_status != 'PENDING'
    """).to_pandas()

@st.cache_data(ttl=300)
def load_revenue_trend():
    return session.sql("""
        SELECT
            order_year,
            order_month,
            MIN(order_date)   AS month_start,
            COUNT(*)          AS order_count,
            SUM(revenue)      AS total_revenue,
            AVG(revenue)      AS avg_order_value
        FROM DEV_DB.GOLD.FCT_ORDERS
        WHERE order_status != 'PENDING'
        GROUP BY order_year, order_month
        ORDER BY order_year, MIN(order_date)
    """).to_pandas()

@st.cache_data(ttl=300)
def load_segment_breakdown():
    return session.sql("""
        SELECT
            customer_segment,
            COUNT(*)          AS order_count,
            SUM(revenue)      AS total_revenue,
            AVG(revenue)      AS avg_order_value,
            SUM(is_returned)  AS return_count
        FROM DEV_DB.GOLD.FCT_ORDERS
        WHERE order_status != 'PENDING'
        GROUP BY customer_segment
        ORDER BY total_revenue DESC
    """).to_pandas()

@st.cache_data(ttl=300)
def load_product_performance():
    return session.sql("""
        SELECT
            product_category,
            product_subcategory,
            COUNT(*)          AS order_count,
            SUM(revenue)      AS total_revenue,
            SUM(quantity)     AS units_sold,
            AVG(revenue)      AS avg_order_value
        FROM DEV_DB.GOLD.FCT_ORDERS
        WHERE order_status != 'PENDING'
        GROUP BY product_category, product_subcategory
        ORDER BY total_revenue DESC
    """).to_pandas()

@st.cache_data(ttl=300)
def load_region_breakdown():
    return session.sql("""
        SELECT
            region,
            COUNT(*)     AS order_count,
            SUM(revenue) AS total_revenue
        FROM DEV_DB.GOLD.FCT_ORDERS
        WHERE order_status != 'PENDING'
        GROUP BY region
        ORDER BY total_revenue DESC
    """).to_pandas()

@st.cache_data(ttl=300)
def load_customer_value_tiers():
    return session.sql("""
        SELECT
            value_tier,
            COUNT(*)              AS customer_count,
            SUM(lifetime_value)   AS total_ltv,
            AVG(lifetime_value)   AS avg_ltv
        FROM DEV_DB.GOLD.DIM_CUSTOMERS
        GROUP BY value_tier
        ORDER BY avg_ltv DESC
    """).to_pandas()

@st.cache_data(ttl=300)
def load_filtered_orders(start_date, end_date, segments, regions):
    segment_filter = "', '".join(segments) if segments else "Premium', 'Standard"
    region_filter  = "', '".join(regions)  if regions  else "North', 'South', 'East', 'West"

    return session.sql(f"""
        SELECT
            order_id,
            order_date,
            customer_segment,
            product_category,
            region,
            order_status,
            quantity,
            unit_price,
            discount,
            revenue
        FROM DEV_DB.GOLD.FCT_ORDERS
        WHERE order_date BETWEEN '{start_date}' AND '{end_date}'
          AND customer_segment IN ('{segment_filter}')
          AND region IN ('{region_filter}')
        ORDER BY order_date DESC
        LIMIT 500
    """).to_pandas()

# ── Sidebar filters ───────────────────────────────────────────────────────────
with st.sidebar:
    st.image("https://img.icons8.com/fluency/96/shopping-bag.png", width=60)
    st.title("RetailPulse")
    st.caption("Analytics Dashboard")
    st.divider()

    st.subheader("🔍 Filters")

    date_range = st.date_input(
        "Date Range",
        value=[pd.to_datetime("2024-01-01"), pd.to_datetime("2024-12-31")],
        min_value=pd.to_datetime("2023-01-01"),
        max_value=pd.to_datetime("2027-12-31")
    )

    segments = st.multiselect(
        "Customer Segment",
        options=["Premium", "Standard"],
        default=["Premium", "Standard"]
    )

    regions = st.multiselect(
        "Region",
        options=["North", "South", "East", "West"],
        default=["North", "South", "East", "West"]
    )

    st.divider()
    if st.button("🔄 Refresh Data", use_container_width=True):
        st.cache_data.clear()
        st.rerun()

    st.caption(f"Data refreshes every 5 minutes")
    st.caption(f"Source: DEV_DB.GOLD")

# ── Main dashboard ────────────────────────────────────────────────────────────
st.title("🛍️ RetailPulse Analytics Dashboard")
st.caption("Built on Snowflake · dbt Gold Layer · Powered by RetailPulse Platform")
st.divider()

# Load all data
with st.spinner("Loading data..."):
    kpis        = load_kpis()
    revenue     = load_revenue_trend()
    segments_df = load_segment_breakdown()
    products    = load_product_performance()
    regions_df  = load_region_breakdown()
    customers   = load_customer_value_tiers()

# ── KPI Row ───────────────────────────────────────────────────────────────────
st.markdown("### 📊 Key Performance Indicators")

k1, k2, k3, k4, k5, k6 = st.columns(6)

with k1:
    st.metric(
        label="💰 Total Revenue",
        value=f"${kpis['TOTAL_REVENUE'].iloc[0]:,.0f}"
    )
with k2:
    st.metric(
        label="📦 Total Orders",
        value=f"{kpis['TOTAL_ORDERS'].iloc[0]:,}"
    )
with k3:
    st.metric(
        label="🛒 Avg Order Value",
        value=f"${kpis['AVG_ORDER_VALUE'].iloc[0]:,.2f}"
    )
with k4:
    st.metric(
        label="↩️ Return Rate",
        value=f"{kpis['RETURN_RATE_PCT'].iloc[0]:.1f}%"
    )
with k5:
    st.metric(
        label="📫 Units Sold",
        value=f"{kpis['TOTAL_UNITS_SOLD'].iloc[0]:,}"
    )
with k6:
    st.metric(
        label="👥 Customers",
        value=f"{kpis['UNIQUE_CUSTOMERS'].iloc[0]:,}"
    )

st.divider()

# ── Revenue Trend ─────────────────────────────────────────────────────────────
st.markdown("### 📈 Revenue Trend")

col1, col2 = st.columns([2, 1])

with col1:
    if not revenue.empty:
        fig = px.bar(
            revenue,
            x="ORDER_MONTH",
            y="TOTAL_REVENUE",
            color="ORDER_MONTH",
            title="Monthly Revenue",
            labels={"TOTAL_REVENUE": "Revenue ($)", "ORDER_MONTH": "Month"},
            color_continuous_scale="Blues"
        )
        fig.update_layout(
            showlegend=False,
            plot_bgcolor="rgba(0,0,0,0)",
            paper_bgcolor="rgba(0,0,0,0)",
            font=dict(color="#1B3A5C")
        )
        st.plotly_chart(fig, use_container_width=True)

with col2:
    if not revenue.empty:
        fig2 = px.line(
            revenue,
            x="ORDER_MONTH",
            y="AVG_ORDER_VALUE",
            title="Avg Order Value Trend",
            labels={"AVG_ORDER_VALUE": "Avg Order Value ($)", "ORDER_MONTH": "Month"},
            markers=True
        )
        fig2.update_traces(line_color="#0D6E8A", line_width=3)
        fig2.update_layout(
            plot_bgcolor="rgba(0,0,0,0)",
            paper_bgcolor="rgba(0,0,0,0)"
        )
        st.plotly_chart(fig2, use_container_width=True)

st.divider()

# ── Customer & Product Analysis ───────────────────────────────────────────────
st.markdown("### 👥 Customer & 🛍️ Product Analysis")

col3, col4 = st.columns(2)

with col3:
    st.subheader("Revenue by Customer Segment")
    if not segments_df.empty:
        fig3 = px.pie(
            segments_df,
            values="TOTAL_REVENUE",
            names="CUSTOMER_SEGMENT",
            color_discrete_sequence=["#1B3A5C", "#0D6E8A", "#C8941A"],
            hole=0.4
        )
        fig3.update_layout(
            plot_bgcolor="rgba(0,0,0,0)",
            paper_bgcolor="rgba(0,0,0,0)"
        )
        st.plotly_chart(fig3, use_container_width=True)

        st.dataframe(
            segments_df[["CUSTOMER_SEGMENT", "ORDER_COUNT",
                         "TOTAL_REVENUE", "AVG_ORDER_VALUE"]].rename(columns={
                "CUSTOMER_SEGMENT": "Segment",
                "ORDER_COUNT":      "Orders",
                "TOTAL_REVENUE":    "Revenue",
                "AVG_ORDER_VALUE":  "Avg Order"
            }),
            hide_index=True,
            use_container_width=True
        )

with col4:
    st.subheader("Revenue by Product Category")
    if not products.empty:
        fig4 = px.bar(
            products,
            x="TOTAL_REVENUE",
            y="PRODUCT_CATEGORY",
            orientation="h",
            color="TOTAL_REVENUE",
            color_continuous_scale="Blues",
            labels={"TOTAL_REVENUE": "Revenue ($)", "PRODUCT_CATEGORY": "Category"}
        )
        fig4.update_layout(
            showlegend=False,
            plot_bgcolor="rgba(0,0,0,0)",
            paper_bgcolor="rgba(0,0,0,0)"
        )
        st.plotly_chart(fig4, use_container_width=True)

st.divider()

# ── Customer Value Tiers & Regional Analysis ──────────────────────────────────
st.markdown("### 🏆 Customer Value & 🗺️ Regional Breakdown")

col5, col6 = st.columns(2)

with col5:
    st.subheader("Customer Value Tiers")
    if not customers.empty:
        fig5 = px.bar(
            customers,
            x="VALUE_TIER",
            y="CUSTOMER_COUNT",
            color="AVG_LTV",
            color_continuous_scale="Blues",
            title="Customers by Value Tier",
            labels={
                "VALUE_TIER":      "Tier",
                "CUSTOMER_COUNT":  "Customers",
                "AVG_LTV":         "Avg LTV"
            }
        )
        fig5.update_layout(
            plot_bgcolor="rgba(0,0,0,0)",
            paper_bgcolor="rgba(0,0,0,0)"
        )
        st.plotly_chart(fig5, use_container_width=True)

with col6:
    st.subheader("Revenue by Region")
    if not regions_df.empty:
        fig6 = px.pie(
            regions_df,
            values="TOTAL_REVENUE",
            names="REGION",
            color_discrete_sequence=["#1B3A5C","#0D6E8A","#C8941A","#1A6B3C"],
            title="Regional Revenue Split"
        )
        fig6.update_layout(
            plot_bgcolor="rgba(0,0,0,0)",
            paper_bgcolor="rgba(0,0,0,0)"
        )
        st.plotly_chart(fig6, use_container_width=True)

st.divider()

# ── Raw Data Explorer ─────────────────────────────────────────────────────────
st.markdown("### 🔎 Order Explorer")

with st.expander("Click to explore raw order data with filters applied"):
    if len(date_range) == 2:
        filtered = load_filtered_orders(
            date_range[0], date_range[1],
            segments, regions
        )
        st.caption(f"Showing {len(filtered):,} orders matching your filters")
        st.dataframe(
            filtered,
            hide_index=True,
            use_container_width=True
        )
    else:
        st.info("Select a date range in the sidebar to explore orders")

# ── Footer ────────────────────────────────────────────────────────────────────
st.divider()
st.caption(
    "RetailPulse Analytics Platform · "
    "Built with dbt + Snowflake + Streamlit · "
    "Data from DEV_DB.GOLD · "
    "Sivasai Valmiki"
)