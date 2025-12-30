#!/bin/bash

# Configuration
AUTOQ_BIN="/root/AutoQ/build/cli/autoq"
BENCHMARK_BASE="/root/AutoQ/benchmarks/TACAS25/RUS"
FIGURES=("Figure7" "Figure8" "Figure9" "Figure10a" "Figure10b" "Figure10c")

echo "Starting benchmarks execution..."
echo "================================="

for FIG in "${FIGURES[@]}"; do
    PRE_HSL="${BENCHMARK_BASE}/${FIG}/loop-invariant.hsl"
    POST_HSL="${BENCHMARK_BASE}/${FIG}/post.hsl"
    
    if [[ -f "$PRE_HSL" && -f "$POST_HSL" ]]; then
        # Run the command and extract the last meaningful line
        echo "$AUTOQ_BIN" ver "$PRE_HSL" _.qasm "$POST_HSL"
        RESULT=$("$AUTOQ_BIN" ver "$PRE_HSL" _.qasm "$POST_HSL" 2>/dev/null | tail -n 1)
        echo "${FIG} => ${RESULT}"
    else
        echo "${FIG} => Error: Missing hls files"
    fi
done

echo "Benchmarks execution completed."
