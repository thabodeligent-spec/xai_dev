import plotly.graph_objects as go
import plotly.express as px

class Charts:
    """Reusable chart components"""

    @staticmethod
    def risk_distribution(predictions):
        fig = px.histogram(
            predictions,
            x='risk_probability',
            title='Risk Probability Distribution'
        )
        return fig

    @staticmethod
    def feature_importance(feature_names, importances):
        fig = go.Figure([go.Bar(
            x=importances,
            y=feature_names,
            orientation='h'
        )])
        fig.update_layout(title='Feature Importance')
        return fig
