import streamlit as st
import pandas as pd
import plotly.express as px

def render():
    st.title("Data Analytics")

    # File upload for analysis
    uploaded_file = st.file_uploader("Upload data for analysis (CSV)", type=['csv'])

    if uploaded_file:
        df = pd.read_csv(uploaded_file)

        st.subheader("Data Overview")
        col1, col2, col3 = st.columns(3)
        with col1:
            st.metric("Total Records", len(df))
        with col2:
            st.metric("Features", len(df.columns))
        with col3:
            st.metric("Missing Values", df.isnull().sum().sum())

        st.subheader("Data Preview")
        st.dataframe(df.head())

        # Basic statistics
        st.subheader("Statistical Summary")
        st.dataframe(df.describe())

        # Visualization section
        st.subheader("Visualizations")

        # Select column for histogram
        numeric_cols = df.select_dtypes(include=['float64', 'int64']).columns
        if len(numeric_cols) > 0:
            selected_col = st.selectbox("Select column for histogram", numeric_cols)
            fig = px.histogram(df, x=selected_col, title=f"Distribution of {selected_col}")
            st.plotly_chart(fig)

        # Correlation heatmap
        if len(numeric_cols) > 1:
            st.subheader("Correlation Matrix")
            corr = df[numeric_cols].corr()
            fig = px.imshow(corr, text_auto=True, title="Feature Correlations")
            st.plotly_chart(fig)
    else:
        st.info("Please upload a CSV file to begin analysis.")
