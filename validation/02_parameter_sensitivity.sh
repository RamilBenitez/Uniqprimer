#!/bin/bash
# ============================================================
# TEST 2: Parameter Sensitivity Test
# ============================================================
# Purpose: Evaluate how changing key parameters affects
#          primer candidate count and pipeline runtime.
#          Tests two parameters:
#            (A) Product Size Range (PSR)
#            (B) Optimal Primer Length
#
# Fixed dataset: X11-5A (include) vs Xoo_KACC_10331 (exclude)
# ============================================================

DOCKER_IMAGE="volture2721/uniqprimer:0.5.0"
BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
RESULTS_DIR="$BASE_DIR/validation/parameter_sensitivity"
RESULTS_FILE="$BASE_DIR/validation/results/parameter_sensitivity_results.tsv"

INCLUDE="/app/uniqprimer-0.5.0/data/X11-5Agenome.fasta"
EXCLUDE="/app/uniqprimer-0.5.0/data/Xoo_KACC_10331.fasta"
CROSSVALIDATE="Yes"

echo "============================================================"
echo " UniqPrimer Parameter Sensitivity Test"
echo " Fixed Dataset: X11-5A (include) vs Xoo_KACC_10331 (exclude)"
echo "============================================================"
echo ""

# Write TSV header
echo -e "Test_ID\tParameter\tValue\tPrimers_Count\tRuntime_Seconds\tNotes" > "$RESULTS_FILE"

# --------------------------------------------------------
# PART A: Product Size Range (PSR) Sensitivity
# --------------------------------------------------------
# Rationale: PSR controls the expected amplicon size.
# A narrow range yields fewer but more size-uniform primers.
# A wide range yields more candidates but varied amplicons.
# Fixed: osize=20, minsize=10, maxsize=35
# --------------------------------------------------------

echo "--- Part A: Product Size Range (PSR) Sensitivity ---"
echo "    Fixed: primer_size=20, min=10, max=35"
echo ""

declare -A PSR_LABELS
PSR_LABELS["100-300"]="Narrow"
PSR_LABELS["100-600"]="Default"
PSR_LABELS["100-1000"]="Wide"

for PRANGE in "100-300" "100-600" "100-1000"; do
    LABEL="${PSR_LABELS[$PRANGE]}"
    TEST_ID="PSR_${PRANGE//-/_}"
    OUT_DIR="$RESULTS_DIR/${TEST_ID}"
    mkdir -p "$OUT_DIR"

    echo "  Testing PSR=${PRANGE} (${LABEL})..."
    START=$(date +%s)

    docker run --rm \
        -v "$OUT_DIR":/outputs \
        "$DOCKER_IMAGE" \
        /app/uniqprimer.sh \
        "$INCLUDE" "$EXCLUDE" \
        "$PRANGE" "20" "10" "35" \
        "$CROSSVALIDATE" \
        /outputs/primers.txt \
        /outputs/log.txt \
        /outputs/output.fasta

    END=$(date +%s)
    ELAPSED=$((END - START))
    PRIMER_COUNT=$(wc -l < "$OUT_DIR/primers.txt" 2>/dev/null || echo "0")

    echo "    Result: ${PRIMER_COUNT} primer pairs | ${ELAPSED}s runtime"
    echo -e "${TEST_ID}\tProduct_Size_Range\t${PRANGE} (${LABEL})\t${PRIMER_COUNT}\t${ELAPSED}\tFixed: osize=20 min=10 max=35" >> "$RESULTS_FILE"
    echo ""
done

# --------------------------------------------------------
# PART B: Optimal Primer Length Sensitivity
# --------------------------------------------------------
# Rationale: Primer length directly affects melting temperature (Tm).
# Longer primers have higher Tm (more stable binding).
# Wallace Rule approximation: Tm ≈ 2(A+T) + 4(G+C)
# A 20-mer primer typically has Tm of 55-65°C (standard range).
# A 22-mer primer will have a higher predicted Tm (~+4°C per 2bp).
# Fixed: prange=100-600
# --------------------------------------------------------

echo "--- Part B: Optimal Primer Length (affects Tm) Sensitivity ---"
echo "    Fixed: prange=100-600"
echo ""

declare -A SIZE_LABELS
SIZE_LABELS["18"]="Short (lower Tm)"
SIZE_LABELS["20"]="Standard (default Tm)"
SIZE_LABELS["22"]="Long (higher Tm)"

for OSIZE in "18" "20" "22"; do
    LABEL="${SIZE_LABELS[$OSIZE]}"
    TEST_ID="OSIZE_${OSIZE}"
    OUT_DIR="$RESULTS_DIR/${TEST_ID}"
    mkdir -p "$OUT_DIR"

    # Adjust min/max around optimal size
    MINSIZE=$((OSIZE - 2))
    MAXSIZE=$((OSIZE + 8))

    echo "  Testing osize=${OSIZE} (${LABEL})..."
    echo "    Min=${MINSIZE}, Max=${MAXSIZE}"
    START=$(date +%s)

    docker run --rm \
        -v "$OUT_DIR":/outputs \
        "$DOCKER_IMAGE" \
        /app/uniqprimer.sh \
        "$INCLUDE" "$EXCLUDE" \
        "100-600" "$OSIZE" "$MINSIZE" "$MAXSIZE" \
        "$CROSSVALIDATE" \
        /outputs/primers.txt \
        /outputs/log.txt \
        /outputs/output.fasta

    END=$(date +%s)
    ELAPSED=$((END - START))
    PRIMER_COUNT=$(wc -l < "$OUT_DIR/primers.txt" 2>/dev/null || echo "0")

    echo "    Result: ${PRIMER_COUNT} primer pairs | ${ELAPSED}s runtime"
    echo -e "${TEST_ID}\tOptimal_Primer_Size\t${OSIZE}bp (${LABEL})\t${PRIMER_COUNT}\t${ELAPSED}\tMin=${MINSIZE} Max=${MAXSIZE} prange=100-600" >> "$RESULTS_FILE"
    echo ""
done

echo "============================================================"
echo " Parameter Sensitivity Test Complete"
echo " Results saved to: $RESULTS_FILE"
echo "============================================================"
