#!/usr/bin/env bash
# One-shot: run only the delivery-review agent (operational impact, implementation risk)
# and append findings to the existing review-working artifact.
# Used to resume from a partial run of run-review-agents.sh.
set -euo pipefail

cd "$(dirname "$0")/.."

V2="artifacts/proposed-design-v2.md"
CONTEXT="context/organizational-context.md"
WORKING="artifacts/review-working.md"

[ -f "$V2" ]      || { echo "missing: $V2" >&2; exit 1; }
[ -f "$CONTEXT" ] || { echo "missing: $CONTEXT" >&2; exit 1; }
[ -f "$WORKING" ] || { echo "missing: $WORKING — run-review-agents.sh must have run partially" >&2; exit 1; }

grep -q "Agent review — delivery-review" "$WORKING" && {
  echo "delivery-review section already present; nothing to do"
  exit 0
}

PROMPT="$(cat <<EOF
You are a review agent in an AI-guided product-development pipeline. The
design stage is complete and Proposed Design v2 is ready for promotion review.
You have no tools; reply with plain markdown only, never tool-call syntax.

Score Proposed Design v2 for fitness as a delivery artifact across your two
assigned dimensions: operational impact, implementation risk.

For each dimension produce exactly one finding in this format:

### Finding: <dimension>

**Severity:** significant | trivial
**Description:** <two to four sentences: what the finding is, quoting the
design where relevant, and why it matters for delivery readiness>

Rules:
- Produce exactly one finding per dimension, using the dimension name exactly
  as listed (lowercase, exact spelling). No other section headers.
- A finding is significant if it identifies a gap that, if unaddressed, would
  weaken the workstream as a delivery artifact: a missing constraint, an
  unstated prerequisite, an ambiguous gate.
- A finding is trivial if the design already handles the concern or if the
  concern does not change delivery outcomes.
- At least one of your two findings must be significant.
- Quote the design directly when you challenge it. Do not invent claims.

Organizational context:
--- 8< ---
$(cat "$CONTEXT")
--- 8< ---

Proposed Design v2:
--- 8< ---
$(cat "$V2")
--- 8< ---

Agent reviews written before you (for context):
--- 8< ---
$(cat "$WORKING")
--- 8< ---
EOF
)"

echo "== review agent: delivery-review"
RESP="$(printf '%s' "$PROMPT" | timeout 900 claude -p --tools "" | awk '!/^<\|/')"

{
  echo
  echo "## Agent review — delivery-review"
  echo
  printf '%s\n' "$RESP"
} >> "$WORKING"

# Validate all eight dimensions are now present
MISSING=""
for dim in robustness simplicity "strategic alignment" "technical feasibility" \
           security "customer value" "operational impact" "implementation risk"; do
  grep -qiE "Finding:.*${dim}" "$WORKING" || MISSING="$MISSING dim:${dim// /_}"
done
if [ -n "$MISSING" ]; then
  echo "review working artifact still missing:$MISSING" >&2
  exit 1
fi

echo
echo "review complete: $(grep -c '^### Finding:' "$WORKING") findings in $WORKING"
