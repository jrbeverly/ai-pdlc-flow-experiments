#!/usr/bin/env bash
set -euo pipefail

# Experimentation stage, step 1 of 3: state the hypothesis before the
# experiment runs. Selects E1 (A5 assumption) as the highest-value
# unresolved question from Proposed Design v1 and writes the hypothesis,
# experiment, success signal, and failure signal to the working material.

cd "$(dirname "$0")/.."

V1="artifacts/proposed-design-v1.md"
WORKING="artifacts/experiment-working.md"

[ -f "$V1" ] || { echo "missing input: $V1" >&2; exit 1; }
grep -q '^state: authoritative' "$V1" || {
  echo "refusing: $V1 is not authoritative — run Stage 2 first" >&2; exit 1
}

if [ -f "$WORKING" ]; then
  echo "refusing: $WORKING already exists — remove it for a fresh run" >&2
  exit 1
fi

cat > "$WORKING" <<'EOF'
---
state: working
derived_from:
  - proposed-design-v1
---

# Experiment working artifact

Working material for the experimentation stage. The hypothesis is stated
before the experiment runs; the experiment's outcome is appended after.

## Selected question

**E1** is selected as the highest-value unresolved question from Proposed
Design v1. The design's confidence section names A5 — "that attention quality
actually serves screening quality" — as the largest source of uncertainty and
states it is "unevidenced." A5 is load-bearing for the design's safety
increment and its success metric. If A5 fails the design retains "no worse
than unchanged" but forfeits its safety upside and the automation branch's
evidence picture changes; if A5 holds the design's safety case strengthens
with every measurement cycle.

Rationale for not selecting E2–E6: E2 changes only the batching investment,
not the direction; E3 changes one feature; E4–E5 are operational calibration;
E6 changes the on-ramp's label quality. E1 is the one question whose answer
changes what the organization should believe about the design's core claim.

## Hypothesis

**Claim:** Brief-assisted review at right-sized depth detects denials and
rework at least as well as undifferentiated review without a brief, per
change class. Equivalently: the A5 assumption is consistent with observable
review outcomes.

## Experiment

Run a mock review comparison against a synthetic dataset of twelve
deployments: six reviewed without a brief (no-brief group), six reviewed
with a tier assignment and brief (brief-assisted group). Compute
anchored-denial rate, subsequent-rework rate, and average review time for
each group. The data is hardcoded in `scripts/run-experiment.sh`; no
external systems or infrastructure are required.

## Success signal

Anchored-denial rate in the brief-assisted group is at least equal to the
rate in the no-brief group, while average review time in the brief-assisted
group is lower. This is consistent with A5: brief-assisted review detects
problems at least as well with less time.

## Failure signal

Anchored-denial rate in the brief-assisted group is below the rate in the
no-brief group. This would indicate that the time saved came at the cost of
accuracy — A5 fails its test and the automation branch's evidence picture
changes.
EOF

echo "hypothesis written: $WORKING"
echo "sections: $(grep -c '^## ' "$WORKING")"
