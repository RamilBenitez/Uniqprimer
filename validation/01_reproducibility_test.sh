#!/bin/bash
# ============================================================
# TEST 1: Reproducibility Test (MD5 Checksum Comparison)
# ============================================================
# Purpose: Confirm that running the pipeline 3 times on the
#          SAME input produces byte-identical outputs.
#          This validates deterministic behavior.
#
# Dataset: X11-5Agenome.fasta (include) vs Xoo_KACC_10331.fasta (exclude)
# Same dataset as the original Run 1.
# ============================================================

DOCKER_IMAGE="volture2721/uniqprimer:0.5.0"
BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
RESULTS_DIR="$BASE_DIR/validation/reproducibility"
RESULTS_FILE="$BASE_DIR/validation/results/reproducibility_results.tsv"

# Parameters (same as original Run 1)
INCLUDE="/app/uniqprimer-0.5.0/data/X11-5Agenome.fasta"
EXCLUDE="/app/uniqprimer-0.5.0/data/Xoo_KACC_10331.fasta"
PRANGE="100-600"
OSIZE="20"
MINSIZE="10"
MAXSIZE="35"
CROSSVALIDATE="Yes"

echo "============================================================"
echo " UniqPrimer Reproducibility Test"
echo " Dataset: X11-5A (include) vs Xoo_KACC_10331 (exclude)"
echo " Repeats: 3 identical runs"
echo "============================================================"
echo ""

# Write TSV header for results
echo -e "Run\tPrimers_Count\tRuntime_Seconds\tMD5_primers\tMD5_fasta\tStatus" > "$RESULTS_FILE"

for RUN in 1 2 3; do
    OUT_DIR="$RESULTS_DIR/run_${RUN}"
    mkdir -p "$OUT_DIR"

    echo "--- Starting Reproducibility Run ${RUN}/3 ---"
    START=$(date +%s)

    docker run --rm \
        -v "$OUT_DIR":/outputs \
        "$DOCKER_IMAGE" \
        /app/uniqprimer.sh \
        "$INCLUDE" \
        "$EXCLUDE" \
        "$PRANGE" "$OSIZE" "$MINSIZE" "$MAXSIZE" \
        "$CROSSVALIDATE" \
        /outputs/primers.txt \
        /outputs/log.txt \
        /outputs/output.fasta

    END=$(date +%s)
    ELAPSED=$((END - START))

    # Count primer pairs (number of lines in primers.txt)
    PRIMER_COUNT=$(wc -l < "$OUT_DIR/primers.txt" 2>/dev/null || echo "ERROR")

    # Compute MD5 checksums
    MD5_PRIMERS=$(md5sum "$OUT_DIR/primers.txt" 2>/dev/null | awk '{print $1}' || echo "ERROR")
    MD5_FASTA=$(md5sum "$OUT_DIR/output.fasta" 2>/dev/null | awk '{print $1}' || echo "ERROR")

    STATUS="OK"
    if [[ "$PRIMER_COUNT" == "ERROR" || "$MD5_PRIMERS" == "ERROR" ]]; then
        STATUS="FAILED"
    fi

    echo "  Run ${RUN}: ${PRIMER_COUNT} primers | ${ELAPSED}s | MD5(primers)=${MD5_PRIMERS:0:12}..."
    echo -e "${RUN}\t${PRIMER_COUNT}\t${ELAPSED}\t${MD5_PRIMERS}\t${MD5_FASTA}\t${STATUS}" >> "$RESULTS_FILE"
    echo ""
done

echo "============================================================"
echo " Reproducibility Test Complete"
echo " Results saved to: $RESULTS_FILE"
echo ""

# Compare all 3 MD5 checksums
echo " MD5 Comparison:"
MD5_R1=$(sed -n '2p' "$RESULTS_FILE" | awk '{print $4}')
MD5_R2=$(sed -n '3p' "$RESULTS_FILE" | awk '{print $4}')
MD5_R3=$(sed -n '4p' "$RESULTS_FILE" | awk '{print $4}')

if [[ "$MD5_R1" == "$MD5_R2" && "$MD5_R2" == "$MD5_R3" ]]; then
    echo " RESULT: PASS - All 3 runs produced identical primers.txt (MD5 match)"
    echo "         CONFIRMED REPRODUCIBLE"
else
    echo " RESULT: WARN - MD5 checksums differ across runs"
    echo "         Run 1: $MD5_R1"
    echo "         Run 2: $MD5_R2"
    echo "         Run 3: $MD5_R3"
fi
echo "============================================================"
