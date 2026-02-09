import streamlit as st

def render():
    """Render sidebar navigation"""
    st.sidebar.title("Navigation")

    pages = {
        "Home": "🏠",
        "Predictions": "🔮",
        "Analytics": "📊",
        "Explanations": "🔍"
    }

    selected_page = st.sidebar.radio(
        "Go to",
        list(pages.keys()),
        format_func=lambda x: f"{pages[x]} {x}"
    )

    return selected_page
