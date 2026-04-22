# nlp_query_engine_local.py
# Claude AI NLP Query Engine — Local Streamlit version
# Runs on your Mac, connects to Snowflake and Claude API directly

import os
import json
import streamlit as st
import pandas as pd
import plotly.express as px
import anthropic
import snowflake.connector
from dotenv import load_dotenv
from schema_context import GOLD_SCHEMA_CONTEXT, EXAMPLE_QUESTIONS

# ── Load environment variables ────────────────────────────────────────────────
load_dotenv()

# ── Page config ───────────────────────────────────────────────────────────────
st.set_page_config(
    page_title="RetailPulse AI Query",
    page_icon="✦",
    layout="wide"
)

# ── Snowflake connection ──────────────────────────────────────────────────────
@st.cache_resource
def get_snowflake_connection():
    return snowflake.connector.connect(
        account   = os.getenv("SNOWFLAKE_ACCOUNT"),
        user      = os.getenv("SNOWFLAKE_USER"),
        password  = os.getenv("SNOWFLAKE_PASSWORD"),
        role      = os.getenv("SNOWFLAKE_ROLE"),
        warehouse = os.getenv("SNOWFLAKE_WAREHOUSE"),
        database  = os.getenv("SNOWFLAKE_DATABASE"),
        schema    = os.getenv("SNOWFLAKE_SCHEMA"),
    )

# ── Claude client ─────────────────────────────────────────────────────────────
@st.cache_resource
def get_claude_client():
    return anthropic.Anthropic(
        api_key=os.getenv("ANTHROPIC_API_KEY")
    )

# ── Run SQL against Snowflake ─────────────────────────────────────────────────
def run_query(sql: str) -> pd.DataFrame:
    try:
        conn   = get_snowflake_connection()
        cursor = conn.cursor()
        cursor.execute(sql)
        cols = [desc[0] for desc in cursor.description]
        rows = cursor.fetchall()
        return pd.DataFrame(rows, columns=cols)
    except Exception as e:
        st.error(f"SQL execution failed: {e}")
        with st.expander("Failed SQL"):
            st.code(sql, language="sql")
        return pd.DataFrame()

# ── Call Claude API ───────────────────────────────────────────────────────────
def call_claude(question: str) -> dict:
    client = get_claude_client()

    try:
        message = client.messages.create(
            model      = "claude-sonnet-4-20250514",
            max_tokens = 1000,
            system     = GOLD_SCHEMA_CONTEXT,
            messages   = [
                {
                    "role":    "user",
                    "content": f"Answer this business question using SQL: {question}"
                }
            ]
        )

        raw_text = message.content[0].text.strip()

        # Strip markdown code fences if present
        if raw_text.startswith("```"):
            raw_text = raw_text.split("```")[1]
            if raw_text.startswith("json"):
                raw_text = raw_text[4:]
        raw_text = raw_text.strip()

        return json.loads(raw_text)

    except json.JSONDecodeError:
        return {
            "sql":         None,
            "explanation": "Claude returned an unexpected format. Try rephrasing.",
            "chart_type":  "table",
            "x_column":    None,
            "y_column":    None,
            "chart_title": "Error"
        }
    except Exception as e:
        return {
            "sql":         None,
            "explanation": f"API error: {str(e)}",
            "chart_type":  "table",
            "x_column":    None,
            "y_column":    None,
            "chart_title": "Error"
        }

# ── Auto-chart renderer ───────────────────────────────────────────────────────
def render_chart(df: pd.DataFrame, response: dict):
    chart_type = response.get("chart_type", "table")
    x_col      = response.get("x_column")
    y_col      = response.get("y_column")
    title      = response.get("chart_title", "Results")

    cols      = [c.upper() for c in df.columns]
    x_valid   = x_col and x_col.upper() in cols
    y_valid   = y_col and y_col.upper() in cols

    if chart_type == "bar" and x_valid and y_valid:
        fig = px.bar(
            df, x=x_col, y=y_col, title=title,
            color=x_col,
            color_discrete_sequence=px.colors.sequential.Blues_r
        )
        fig.update_layout(showlegend=False,
                          plot_bgcolor="rgba(0,0,0,0)",
                          paper_bgcolor="rgba(0,0,0,0)")
        st.plotly_chart(fig, use_container_width=True)

    elif chart_type == "line" and x_valid and y_valid:
        fig = px.line(df, x=x_col, y=y_col, title=title, markers=True)
        fig.update_traces(line_color="#0D6E8A", line_width=3)
        fig.update_layout(plot_bgcolor="rgba(0,0,0,0)",
                          paper_bgcolor="rgba(0,0,0,0)")
        st.plotly_chart(fig, use_container_width=True)

    elif chart_type == "pie" and x_valid and y_valid:
        fig = px.pie(
            df, names=x_col, values=y_col, title=title,
            color_discrete_sequence=["#1B3A5C","#0D6E8A","#C8941A","#1A6B3C"]
        )
        fig.update_layout(plot_bgcolor="rgba(0,0,0,0)",
                          paper_bgcolor="rgba(0,0,0,0)")
        st.plotly_chart(fig, use_container_width=True)

    # Always show the data table
    st.dataframe(df, hide_index=True, use_container_width=True)

# ════════════════════════════════════════════════════════════════════════════
# MAIN UI
# ════════════════════════════════════════════════════════════════════════════

# ── Header ────────────────────────────────────────────────────────────────────
st.title("✦ RetailPulse AI Query Engine")
st.caption(
    "Ask any question about your retail data in plain English · "
    "Powered by Claude AI · Source: DEV_DB.GOLD"
)
st.divider()

# ── Connection status ─────────────────────────────────────────────────────────
col_sf, col_ai, col_spacer = st.columns([1, 1, 4])

with col_sf:
    try:
        conn = get_snowflake_connection()
        st.success("✅ Snowflake connected")
    except Exception as e:
        st.error(f"❌ Snowflake: {e}")

with col_ai:
    if os.getenv("ANTHROPIC_API_KEY"):
        st.success("✅ Claude API ready")
    else:
        st.error("❌ API key missing")

st.divider()

# ── Sidebar — example questions ───────────────────────────────────────────────
with st.sidebar:
    st.markdown("### ✦ Example Questions")
    st.caption("Click any question to try it")

    for idx, q in enumerate(EXAMPLE_QUESTIONS):
        if st.button(q, use_container_width=True, key=f"ex_{idx}"):
            st.session_state["current_question"] = q

    st.divider()
    st.markdown("### 📋 Tables Available")
    st.code("FCT_ORDERS\nDIM_CUSTOMERS\nDIM_PRODUCTS\nDIM_DATE")

    st.divider()
    st.markdown("### ⚙️ Connection")
    st.caption(f"Account: {os.getenv('SNOWFLAKE_ACCOUNT')}")
    st.caption(f"Role: {os.getenv('SNOWFLAKE_ROLE')}")
    st.caption(f"Warehouse: {os.getenv('SNOWFLAKE_WAREHOUSE')}")

# ── Session state ─────────────────────────────────────────────────────────────
if "messages" not in st.session_state:
    st.session_state.messages = []

if "current_question" not in st.session_state:
    st.session_state.current_question = ""

# ── Display conversation history ──────────────────────────────────────────────
for msg in st.session_state.messages:
    with st.chat_message(msg["role"]):
        if msg["role"] == "user":
            st.write(msg["content"])
        else:
            st.write(f"**{msg.get('explanation', '')}**")
            if msg.get("sql"):
                with st.expander("View generated SQL"):
                    st.code(msg["sql"], language="sql")
            if msg.get("dataframe") is not None and not msg["dataframe"].empty:
                render_chart(msg["dataframe"], msg)

# ── Question input ────────────────────────────────────────────────────────────
question = st.chat_input("Ask a question about your retail data...")

if st.session_state.current_question and not question:
    question = st.session_state.current_question
    st.session_state.current_question = ""

# ── Process question ──────────────────────────────────────────────────────────
if question:
    st.session_state.messages.append({"role": "user", "content": question})

    with st.chat_message("user"):
        st.write(question)

    with st.chat_message("assistant"):
        with st.spinner("✦ Claude is thinking..."):
            response = call_claude(question)

        if response.get("sql"):
            st.write(f"**{response['explanation']}**")

            with st.expander("View generated SQL"):
                st.code(response["sql"], language="sql")

            with st.spinner("Running query on Snowflake..."):
                df = run_query(response["sql"])

            if not df.empty:
                st.caption(f"Returned {len(df):,} rows")
                render_chart(df, response)
                st.session_state.messages.append({
                    "role":        "assistant",
                    "explanation": response["explanation"],
                    "sql":         response["sql"],
                    "chart_type":  response.get("chart_type", "table"),
                    "x_column":    response.get("x_column"),
                    "y_column":    response.get("y_column"),
                    "chart_title": response.get("chart_title"),
                    "dataframe":   df
                })
            else:
                st.warning("Query returned no results.")
        else:
            st.warning(response.get("explanation", "Could not generate a query."))

# ── Clear conversation ────────────────────────────────────────────────────────
if st.session_state.messages:
    if st.button("🗑️ Clear conversation"):
        st.session_state.messages = []
        st.rerun()

# ── Footer ────────────────────────────────────────────────────────────────────
st.divider()
st.caption(
    "RetailPulse AI Query Engine · Claude AI · "
    "Snowflake Gold Layer · Built by Sivasai Valmiki"
)