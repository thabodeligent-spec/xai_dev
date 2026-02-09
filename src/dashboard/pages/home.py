import streamlit as st

def render():
    st.title("XAI Student Risk Dashboard")
    st.markdown("---")

    st.header("Welcome")
    st.write("""
    This dashboard provides explainable AI (XAI) tools for predicting student suicide risk
    based on behavioral, academic, and engagement data.
    """)

    col1, col2, col3 = st.columns(3)

    with col1:
        st.subheader("📊 Predictions")
        st.write("Upload student data and get risk predictions with explanations.")

    with col2:
        st.subheader("📈 Analytics")
        st.write("Explore and analyze student data patterns and correlations.")

    with col3:
        st.subheader("🔍 Explanations")
        st.write("Understand how the model makes decisions using XAI techniques.")

    st.markdown("---")

    st.header("Quick Start")
    st.markdown("""
    1. **Upload Data**: Go to Analytics to explore your data
    2. **Train Model**: Use the training scripts to build a model
    3. **Make Predictions**: Upload new data for risk assessment
    4. **Get Explanations**: Understand model decisions
    """)

    if st.button("Get Started"):
        st.success("Navigate to the Predictions page to begin!")
