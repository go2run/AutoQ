#!/bin/bash

# Configuration
AUTOQ_BIN="/workspaces/AutoQ/build/cli/autoq"
BENCHMARK_BASE="/workspaces/AutoQ/benchmarks/TACAS25/RUS"
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
        TARGET_FIG="RUS/${FIG}"
        TARGET_FIG="${TARGET_FIG//./_}"
        RESULT=$("$AUTOQ_BIN" ver "$PRE" "$CIRCUIT" "$POST" 2>/dev/null | tail -n 1)
        printf "%-23s => %s\n" "${TARGET_FIG}" "${RESULT}"
        POST_CORRECTED="${BENCHMARK_BASE}/${FIG}/post_corrected.lsta"
        if [[ -f "$POST_CORRECTED" ]]; then
            RESULT=$("$AUTOQ_BIN" ver "$PRE" "$CIRCUIT" "$POST_CORRECTED" 2>/dev/null | tail -n 1)
            printf "%-23s => %s\n" "${TARGET_FIG}_corrected" "${RESULT}"
        fi
    else
        echo "${FIG} => Error: Missing hls files"
    fi
done

echo "Benchmarks execution completed."
