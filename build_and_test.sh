#!/bin/bash

# Script to build and test pyspark compatibility with Apache Spark 3.5

set -e  # Exit on error

echo "=========================================="
echo "Build and Test Script for PySpark 3.5.6"
echo "=========================================="

# Create a virtual environment
echo "Creating virtual environment..."
python3 -m venv venv

# Activate the virtual environment
echo "Activating virtual environment..."
source venv/bin/activate

# Upgrade pip
echo "Upgrading pip..."
pip install --upgrade pip

# Install requirements
echo "Installing requirements from requirements.txt..."
pip install -r requirements.txt

# Display installed packages
echo "Installed packages:"
pip list | grep pyspark

# Test PySpark installation
echo ""
echo "Testing PySpark installation..."
python3 << EOF
import pyspark
from pyspark.sql import SparkSession

print(f"PySpark version: {pyspark.__version__}")

# Create a Spark session
spark = SparkSession.builder \
    .appName("PySpark Compatibility Test") \
    .master("local[*]") \
    .getOrCreate()

print(f"Spark version: {spark.version}")

# Create a simple DataFrame to test functionality
data = [("Alice", 1), ("Bob", 2), ("Charlie", 3)]
df = spark.createDataFrame(data, ["name", "id"])

print("\nTest DataFrame:")
df.show()

# Verify the count
count = df.count()
print(f"\nDataFrame row count: {count}")

# Stop the Spark session
spark.stop()

print("\n✓ PySpark is working correctly!")
EOF

# Check if test was successful
if [ $? -eq 0 ]; then
    echo ""
    echo "=========================================="
    echo "✓ All tests passed successfully!"
    echo "✓ PySpark 3.5.6 is compatible with Apache Spark 3.5"
    echo "=========================================="
else
    echo ""
    echo "=========================================="
    echo "✗ Tests failed!"
    echo "=========================================="
    exit 1
fi

# Deactivate virtual environment
deactivate
