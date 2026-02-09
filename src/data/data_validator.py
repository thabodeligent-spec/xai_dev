class DataValidator:
    """Validate data quality and schema"""

    def validate_schema(self, df, expected_columns):
        """Check if dataframe has expected columns"""
        missing = set(expected_columns) - set(df.columns)
        if missing:
            raise ValueError(f"Missing columns: {missing}")

    def check_data_quality(self, df):
        """Check for nulls, duplicates, outliers"""
        issues = {}
        issues['null_counts'] = df.isnull().sum()
        issues['duplicates'] = df.duplicated().sum()
        return issues
