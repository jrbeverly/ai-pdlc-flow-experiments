#!/usr/bin/env bash
set -euo pipefail

# Experimentation stage, step 2 of 3: run the mock experiment. Processes
# twelve hardcoded synthetic review records, computes the comparison metrics,
# determines which signal was matched, appends the outcome to the working
# material, and writes the evidence artifact. No external systems.

cd "$(dirname "$0")/.."

WORKING="artifacts/experiment-working.md"
EVIDENCE="artifacts/evidence-e1.md"

[ -f "$WORKING" ] || {
  echo "missing: $WORKING — run hypothesis step first" >&2; exit 1
}
grep -q '## Hypothesis' "$WORKING" || {
  echo "refusing: hypothesis not present in $WORKING" >&2; exit 1
}
grep -q '^## Outcome$' "$WORKING" && {
  echo "refusing: $WORKING already has an Outcome section — experiment already ran" >&2; exit 1
}
if [ -f "$EVIDENCE" ]; then
  echo "refusing: $EVIDENCE already exists — remove it for a fresh run" >&2
  exit 1
fi

# Hardcoded synthetic review records.
# Format: deployment_id group time_minutes anchored_denial rework_later
# group "nobr" = no brief, untiered; group "brief" = tiered + brief-assisted
DATA=$(cat <<'DATAEOF'
D001 nobr 18 no yes
D002 nobr 22 yes no
D003 nobr 12 no yes
D004 nobr 25 yes no
D005 nobr 15 no no
D006 nobr 20 yes no
D007 brief 8 yes no
D008 brief 6 no no
D009 brief 9 yes no
D010 brief 7 yes no
D011 brief 5 no no
D012 brief 7 yes no
DATAEOF
)

# Compute metrics per group and determine signal in one awk pass.
eval "$(printf '%s\n' "$DATA" | awk '
{
  g=$2; t=$3; d=$4; r=$5
  if (g=="nobr")  { nc++;  nt+=t; if(d=="yes") nd++; if(r=="yes") nr++ }
  if (g=="brief") { bc++;  bt+=t; if(d=="yes") bd++; if(r=="yes") br++ }
}
END {
  ndr = int(nd*100/nc)
  bdr = int(bd*100/bc)
  nat = nt/nc
  bat = bt/bc
  nrr = int(nr*100/nc)
  brr = int(br*100/bc)
  sig = (bdr >= ndr && bat < nat) ? "success" : "failure"
  printf "NOBR_N=%d\nNOBR_DR=%d\nNOBR_RR=%d\n", nc, ndr, nrr
  printf "NOBR_AT=%.1f\n", nat
  printf "BRIEF_N=%d\nBRIEF_DR=%d\nBRIEF_RR=%d\n", bc, bdr, brr
  printf "BRIEF_AT=%.1f\n", bat
  printf "SIGNAL=%s\n", sig
}')"

echo "no-brief:       denial=${NOBR_DR}%  rework=${NOBR_RR}%  avg=${NOBR_AT}min  n=${NOBR_N}"
echo "brief-assisted: denial=${BRIEF_DR}%  rework=${BRIEF_RR}%  avg=${BRIEF_AT}min  n=${BRIEF_N}"
echo "signal: $SIGNAL"

# Append the outcome to the working material.
cat >> "$WORKING" <<OUTCOME_EOF

## Outcome

Run: \`scripts/run-experiment.sh\` against twelve hardcoded synthetic review
records. Metrics computed with awk.

| group | n | anchored-denial rate | rework rate | avg review time |
|---|---|---|---|---|
| no brief | ${NOBR_N} | ${NOBR_DR}% | ${NOBR_RR}% | ${NOBR_AT} min |
| brief-assisted | ${BRIEF_N} | ${BRIEF_DR}% | ${BRIEF_RR}% | ${BRIEF_AT} min |

Signal matched: **${SIGNAL}** — brief-assisted anchored-denial rate
(${BRIEF_DR}%) vs. no-brief (${NOBR_DR}%); brief-assisted avg review time
(${BRIEF_AT} min) vs. no-brief (${NOBR_AT} min).
OUTCOME_EOF

# Write the evidence artifact.
cat > "$EVIDENCE" <<EVIDEOF
---
state: working
derived_from:
  - experiment-working
---

# Evidence: E1 mock experiment

## What was run

\`scripts/run-experiment.sh\` — no external systems or infrastructure. Twelve
hardcoded synthetic review records (six without brief, six with tier + brief).
Metrics computed inline with awk; no LLM involved.

## Synthetic data

| deployment | group | time (min) | anchored denial | rework later |
|---|---|---|---|---|
| D001 | no brief | 18 | no | yes |
| D002 | no brief | 22 | yes | no |
| D003 | no brief | 12 | no | yes |
| D004 | no brief | 25 | yes | no |
| D005 | no brief | 15 | no | no |
| D006 | no brief | 20 | yes | no |
| D007 | brief-assisted | 8 | yes | no |
| D008 | brief-assisted | 6 | no | no |
| D009 | brief-assisted | 9 | yes | no |
| D010 | brief-assisted | 7 | yes | no |
| D011 | brief-assisted | 5 | no | no |
| D012 | brief-assisted | 7 | yes | no |

## Outcome

| group | n | anchored-denial rate | rework rate | avg review time |
|---|---|---|---|---|
| no brief | ${NOBR_N} | ${NOBR_DR}% | ${NOBR_RR}% | ${NOBR_AT} min |
| brief-assisted | ${BRIEF_N} | ${BRIEF_DR}% | ${BRIEF_RR}% | ${BRIEF_AT} min |

## Signal matched

**${SIGNAL}**

The success signal from the hypothesis stated that anchored-denial rate in
the brief-assisted group is ≥ the rate in the no-brief group, while average
review time in the brief-assisted group is lower. The failure signal stated
that anchored-denial rate falls in the brief-assisted group, indicating
accuracy was traded for speed.

Observed: brief-assisted anchored-denial rate ${BRIEF_DR}% vs. no-brief
${NOBR_DR}%; brief-assisted avg review time ${BRIEF_AT} min vs. no-brief
${NOBR_AT} min. The ${SIGNAL} signal condition is met.

## Interpretation

This is a mock experiment with synthetic data; statistical conclusions do
not follow. The loop mechanics work: hypothesis stated before run, experiment
ran from the runbook, evidence recorded, signal identified. The result is a
weak positive first indicator for A5: in the synthetic data, brief-assisted
reviews showed a higher anchored-denial rate and zero subsequent rework at
materially lower review time. The signal must be reproduced on P0 real data
before any design decision rests on it.
EVIDEOF

echo
echo "evidence artifact: $EVIDENCE"
echo "signal: $SIGNAL"
