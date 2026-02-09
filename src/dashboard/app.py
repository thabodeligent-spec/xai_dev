import streamlit as st
from .pages import home, predictions, analytics, explanations
from .components import sidebar
from .utils.session_state import init_session_state

def main():
    st.set_page_config(
        page_title="XAI Student Risk Dashboard",
        layout="wide"
    )

    # Initialize session state
    init_session_state()

    # Sidebar navigation
    page = sidebar.render()

    # Route to pages
    pages = {
        "Home": home.render,
        "Predictions": predictions.render,
        "Analytics": analytics.render,
        "Explanations": explanations.render
    }

    pages[page]()

if __name__ == "__main__":
    main()
