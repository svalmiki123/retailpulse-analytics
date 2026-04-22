#!/bin/bash
# Quick wrapper script to test Snowflake connection

set -e

echo "======================================================================"
echo "Snowflake Connection Test Script"
echo "======================================================================"
echo ""

# Check if snowflake-connector-python is installed
if ! python3 -c "import snowflake.connector" 2>/dev/null; then
    echo "📦 Installing snowflake-connector-python..."
    pip3 install snowflake-connector-python
    echo ""
fi

# Check if credentials are in environment
if [ -z "$SNOWFLAKE_ACCOUNT" ] || [ -z "$SNOWFLAKE_USERNAME" ] || [ -z "$SNOWFLAKE_PASSWORD" ]; then
    echo "💡 TIP: You can set environment variables to avoid typing credentials:"
    echo "   export SNOWFLAKE_ACCOUNT='your-account'"
    echo "   export SNOWFLAKE_USERNAME='your-username'"
    echo "   export SNOWFLAKE_PASSWORD='your-password'"
    echo ""
fi

# Run the Python script
python3 test_snowflake_connection.py

echo ""
echo "======================================================================"
echo "Script completed!"
echo "======================================================================"
