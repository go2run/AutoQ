#!/bin/bash

# Configuration
AUTOQ_BIN="/root/AutoQ/build/cli/autoq"
BENCHMARK_BASE="/root/AutoQ/benchmarks/TACAS25/RUS"
FIGURES=("Figure7" "Figure8" "Figure9" "Figure10a" "Figure10b" "Figure10c")

echo "Starting benchmarks execution..."
echo "================================="

for FIG in "${FIGURES[@]}"; do
    PRE="${BENCHMARK_BASE}/${FIG}/pre_.lsta"
    POST="${BENCHMARK_BASE}/${FIG}/post_.lsta"
    CIRCUIT="${BENCHMARK_BASE}/${FIG}/circuit_.qasm"
    
    if [[ -f "$PRE" && -f "$POST" ]]; then
        # Run the command and extract the last meaningful line
        # echo "$AUTOQ_BIN" ver "$PRE" "$CIRCUIT" "$POST"
        RESULT=$("$AUTOQ_BIN" ver "$PRE" "$CIRCUIT" "$POST" 2>/dev/null | tail -n 1)
        echo "${FIG} => ${RESULT}"
        if [ -f "${BENCHMARK_BASE}/${FIG}/post_corrected.lsta" ]; then
            POST="${BENCHMARK_BASE}/${FIG}/post_corrected.lsta"
            RESULT=$("$AUTOQ_BIN" ver "$PRE" "$CIRCUIT" "$POST" 2>/dev/null | tail -n 1)
            echo "${FIG} => ${RESULT}"
        fi
    else
        echo "${FIG} => Error: Missing hls files"
    fi
done

echo "Benchmarks execution completed."
