#!/bin/bash

# Configuration
OUTPUT_FILE="table3.csv"

echo "Starting combined CSV generation..."
echo "==================================="

# First, run table1.sh to generate table1.csv
if [ -f "scripts/RUS_benchmarks_table1.sh" ]; then
    echo "Generating table1.csv..."
    bash scripts/RUS_benchmarks_table1.sh > /dev/null 2>&1
else
    echo "Error: scripts/RUS_benchmarks_table1.sh not found"
    exit 1
fi

# Then, run table2.sh to generate table2.csv
if [ -f "scripts/RUS_benchmarks_table2.sh" ]; then
    echo "Generating table2.csv..."
    bash scripts/RUS_benchmarks_table2.sh > /dev/null 2>&1
else
    echo "Error: scripts/RUS_benchmarks_table2.sh not found"
    exit 1
fi

# Check if both CSV files exist
if [ ! -f "table1.csv" ]; then
    echo "Error: table1.csv not generated"
    exit 1
fi

if [ ! -f "table2.csv" ]; then
    echo "Error: table2.csv not generated"
    exit 1
fi

# Create combined CSV
echo "Creating combined CSV..."
echo "program,qubits,gates,result,time,memory" > "$OUTPUT_FILE"

# Add all rows from table1.csv (skip header)
tail -n +2 table1.csv >> "$OUTPUT_FILE"

# Add all rows from table2.csv (skip header)
tail -n +2 table2.csv >> "$OUTPUT_FILE"

echo "Combined CSV generation completed. Output saved to $OUTPUT_FILE"
echo "==============================================================="

# Display the combined CSV
cat "$OUTPUT_FILE"

# Optional: Clean up intermediate files if desired
# echo "Cleaning up intermediate files..."
# rm -f table1.csv table2.csv