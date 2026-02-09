#!/usr/bin/env python3
"""
Test script to verify dashboard functionality
"""

import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'src'))

def test_imports():
    """Test that all dashboard modules can be imported"""
    try:
        from dashboard.pages import home, predictions, analytics, explanations
        from dashboard.components import sidebar, charts
        from dashboard.utils import cache
        print("✓ All dashboard imports successful")
        return True
    except ImportError as e:
        print(f"✗ Import error: {e}")
        return False

def test_config():
    """Test configuration loading"""
    try:
        from utils.config import config
        title = config.get('dashboard.title')
        print(f"✓ Config loaded: title = {title}")
        return True
    except Exception as e:
        print(f"✗ Config error: {e}")
        return False

def test_data_modules():
    """Test data processing modules"""
    try:
        from data.data_validator import DataValidator
        from data.preprocessor import DataPreprocessor
        print("✓ Data modules imported successfully")
        return True
    except ImportError as e:
        print(f"✗ Data module error: {e}")
        return False

def test_model_modules():
    """Test model modules"""
    try:
        from models.base_model import BaseModel
        from models.model_registry import ModelRegistry
        print("✓ Model modules imported successfully")
        return True
    except ImportError as e:
        print(f"✗ Model module error: {e}")
        return False

def main():
    print("Testing XAI Student Risk Dashboard...")
    print("=" * 50)

    tests = [
        test_imports,
        test_config,
        test_data_modules,
        test_model_modules
    ]

    passed = 0
    total = len(tests)

    for test in tests:
        if test():
            passed += 1
        print()

    print(f"Results: {passed}/{total} tests passed")

    if passed == total:
        print("🎉 All tests passed! Dashboard is ready.")
        return 0
    else:
        print("❌ Some tests failed. Check the errors above.")
        return 1

if __name__ == "__main__":
    sys.exit(main())
