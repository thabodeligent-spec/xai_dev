import streamlit as st
from functools import wraps
import time

def cache_data(ttl_seconds=300):
    """Cache function results with TTL"""
    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            cache_key = f"{func.__name__}_{hash(str(args) + str(kwargs))}"

            if cache_key not in st.session_state:
                st.session_state[cache_key] = {
                    'data': None,
                    'timestamp': 0
                }

            current_time = time.time()
            cached = st.session_state[cache_key]

            if current_time - cached['timestamp'] > ttl_seconds:
                cached['data'] = func(*args, **kwargs)
                cached['timestamp'] = current_time

            return cached['data']
        return wrapper
    return decorator
