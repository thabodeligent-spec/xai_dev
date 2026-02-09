class DataPreprocessor:
    """Handle data preprocessing tasks"""

    def preprocess(self, df):
        """Basic preprocessing pipeline"""
        # Remove duplicates
        df = df.drop_duplicates()

        # Handle missing values (example)
        df = df.fillna(df.mean(numeric_only=True))

        # Normalize or scale if needed
        # Add more preprocessing steps as required

        return df
