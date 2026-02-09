import streamlit as st
import pandas as pd
import requests
import json
from typing import Dict, Any
from src.utils.config import Config

def render():
    st.title("Risk Predictions")

    # Load configuration
    config = Config()
    api_base_url = config.get('api.base_url', 'http://localhost:8000')

    # Check API health
    try:
        health_response = requests.get(f"{api_base_url}/health", timeout=5)
        if health_response.status_code == 200:
            st.success("✅ API connection successful")
        else:
            st.error("❌ API connection failed")
            return
    except requests.exceptions.RequestException:
        st.error("❌ Cannot connect to API. Please ensure the backend is running.")
        st.info("Start the API with: `python -m uvicorn src.api.main:app --reload`")
        return

    # File upload
    uploaded_file = st.file_uploader("Upload student data (CSV)", type=['csv'])

    if uploaded_file:
        df = pd.read_csv(uploaded_file)

        st.subheader("Uploaded Data Preview")
        st.dataframe(df.head())

        # Model selection
        try:
            models_response = requests.get(f"{api_base_url}/models")
            if models_response.status_code == 200:
                models_data = models_response.json()
                available_models = [model['name'] for model in models_data['models']]
                selected_model = st.selectbox("Select Model", available_models)
            else:
                selected_model = "default"
                st.warning("Could not load available models, using default")
        except:
            selected_model = "default"
            st.warning("Could not load available models, using default")

        # Generate predictions
        if st.button("Generate Predictions", type="primary"):
            with st.spinner("Generating predictions..."):
                st.subheader("Prediction Results")

                progress_bar = st.progress(0)
                predictions_list = []

                # Process each row
                for i, (_, row) in enumerate(df.iterrows()):
                    try:
                        # Convert row to dict and handle NaN values
                        student_data = row.to_dict()
                        student_data = {k: (v if pd.notna(v) else None) for k, v in student_data.items()}

                        # Make API request
                        payload = {
                            "student_data": student_data,
                            "model_name": selected_model
                        }

                        response = requests.post(
                            f"{api_base_url}/predict",
                            json=payload,
                            timeout=30
                        )

                        if response.status_code == 200:
                            result = response.json()
                            predictions_list.append({
                                'prediction': result['prediction'],
                                'risk_level': result['risk_level'],
                                'confidence': result['confidence'],
                                'explanation': result.get('explanation', {})
                            })
                        else:
                            st.error(f"API Error for row {i+1}: {response.text}")
                            predictions_list.append({
                                'prediction': None,
                                'risk_level': 'error',
                                'confidence': 0.0,
                                'explanation': {}
                            })

                    except Exception as e:
                        st.error(f"Error processing row {i+1}: {str(e)}")
                        predictions_list.append({
                            'prediction': None,
                            'risk_level': 'error',
                            'confidence': 0.0,
                            'explanation': {}
                        })

                    # Update progress
                    progress_bar.progress((i + 1) / len(df))

                # Create results dataframe
                results_df = df.copy()
                results_df['risk_prediction'] = [p['prediction'] for p in predictions_list]
                results_df['risk_level'] = [p['risk_level'] for p in predictions_list]
                results_df['confidence'] = [p['confidence'] for p in predictions_list]

                # Display results
                st.dataframe(results_df)

                # Summary statistics
                col1, col2, col3 = st.columns(3)
                with col1:
                    high_risk_count = sum(1 for p in predictions_list if p['risk_level'] == 'high')
                    st.metric("High Risk Cases", high_risk_count)

                with col2:
                    medium_risk_count = sum(1 for p in predictions_list if p['risk_level'] == 'medium')
                    st.metric("Medium Risk Cases", medium_risk_count)

                with col3:
                    low_risk_count = sum(1 for p in predictions_list if p['risk_level'] == 'low')
                    st.metric("Low Risk Cases", low_risk_count)

                # Risk distribution chart
                risk_counts = pd.Series([p['risk_level'] for p in predictions_list]).value_counts()
                st.bar_chart(risk_counts)

                # Download results
                csv = results_df.to_csv(index=False)
                st.download_button(
                    label="📥 Download Results",
                    data=csv,
                    file_name="predictions.csv",
                    mime="text/csv"
                )

                st.success("✅ Predictions completed successfully!")
