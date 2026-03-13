#!/bin/bash
# =============================================================================
# AutoQ — Formal Verification of Quantum Programs
# Artifact evaluation entry point
#
# Usage:  bash run.sh
# Build:  make            (then re-run this script)
# Docker: see README_DOCKER.md
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AUTOQ_BIN="${SCRIPT_DIR}/build/cli/autoq"

BOLD='\033[1m'; GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'

echo -e "${BOLD}============================================================${NC}"
echo -e "${BOLD}  AutoQ: Formal Verification of Quantum Programs${NC}"
echo -e "${BOLD}  CAV'23 · PLDI'23 · POPL'25 · TACAS'25${NC}"
echo -e "${BOLD}============================================================${NC}"
echo ""

if [ ! -f "$AUTOQ_BIN" ]; then
    echo -e "${RED}[!] Binary not found. Please run: make${NC}"
    exit 1
fi
echo -e "${GREEN}[✓] $AUTOQ_BIN${NC}"
echo ""

echo "Select an option:"
echo "  1) Individual RUS circuits  — Figure 7–10, Table 1 (TACAS'25)"
echo "  2) Composed RUS circuits    — V_i → CX → V_j, Table 2 (TACAS'25)"
echo "  3) Both                     — run 1 then 2"
echo "  q) Quit"
echo ""
read -rp "Choice [1-3/q]: " CHOICE
echo ""

export AUTOQ_BIN

case "$CHOICE" in
    1)
        bash "${SCRIPT_DIR}/scripts/RUS_single.sh"
        ;;
    2)
        bash "${SCRIPT_DIR}/scripts/RUS_composed.sh"
        ;;
    3)
        bash "${SCRIPT_DIR}/scripts/RUS_single.sh"
        echo ""
        bash "${SCRIPT_DIR}/scripts/RUS_composed.sh"
        ;;
    q|Q)
        exit 0 ;;
    *)
        echo -e "${RED}Invalid choice.${NC}"; exit 1 ;;
esac

echo ""
echo -e "${BOLD}Done.${NC}"
