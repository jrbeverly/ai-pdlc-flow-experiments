#!/usr/bin/env bash
set -euo pipefail

# Promotion stage, step 1 of 2: three review agents score Proposed Design v2
# across the eight promotion-review dimensions listed in VISION.md (robustness,
# simplicity, strategic alignment, technical feasibility, security, customer
# value, operational impact, implementation risk). Findings are recorded in the
# review working artifact. Dispositions are appended by the compaction step.

cd "$(dirname "$0")/.."

V2="artifacts/proposed-design-v2.md"
CONTEXT="context/organizational-context.md"
WORKING="artifacts/review-working.md"

for f in "$V2" "$CONTEXT"; do
  [ -f "$f" ] || { echo "missing input: $f" >&2; exit 1; }
done

grep -q '^state: authoritative' "$V2" || {
  echo "refusing: $V2 is not authoritative — run Stage 3 first" >&2; exit 1
}

if [ -f "$WORKING" ]; then
  echo "refusing: $WORKING already exists — remove it for a fresh run" >&2
  exit 1
fi

cat > "$WORKING" <<'EOF'
---
state: working
derived_from:
  - proposed-design-v2
---

# Review working artifact

Working material for the promotion stage. Three review agents score Proposed
Design v2 across the eight dimensions from VISION.md: robustness, simplicity,
strategic alignment, technical feasibility, security, customer value,
operational impact, and implementation risk. Dispositions are appended by the
compaction step after remediation.

Each finding uses this format:

    ### Finding: <dimension>
    **Severity:** significant | trivial
    **Description:** ...

EOF

# prompt goes via stdin; --tools "" keeps the model from emitting tool calls;
# the <| filter drops any tool-call syntax that leaks through anyway
run_agent() {
  local name="$1" prompt="$2" resp
  echo "== review agent: $name"
  resp="$(printf '%s' "$prompt" | timeout 900 claude -p --tools "" | awk '!/^<\|/')"
  {
    echo
    echo "## Agent review — $name"
    echo
    printf '%s\n' "$resp"
  } >> "$WORKING"
}

# --- Agent 1: structural-review (robustness, simplicity, strategic alignment) ---

PROMPT="$(cat <<EOF
You are a review agent in an AI-guided product-development pipeline. The
design stage is complete and Proposed Design v2 is ready for promotion review.
You have no tools; reply with plain markdown only, never tool-call syntax.

Score Proposed Design v2 for fitness as a delivery artifact across your three
assigned dimensions: robustness, simplicity, strategic alignment.

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
- At least one of your three findings must be significant.
- Quote the design directly when you challenge it. Do not invent claims.

Organizational context:
--- 8< ---
$(cat "$CONTEXT")
--- 8< ---

Proposed Design v2:
--- 8< ---
$(cat "$V2")
--- 8< ---
EOF
)"
run_agent "structural-review" "$PROMPT"

# --- Agent 2: technical-review (technical feasibility, security, customer value) ---

PROMPT="$(cat <<EOF
You are a review agent in an AI-guided product-development pipeline. The
design stage is complete and Proposed Design v2 is ready for promotion review.
You have no tools; reply with plain markdown only, never tool-call syntax.

Score Proposed Design v2 for fitness as a delivery artifact across your three
assigned dimensions: technical feasibility, security, customer value.

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
- At least one of your three findings must be significant.
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
run_agent "technical-review" "$PROMPT"

# --- Agent 3: delivery-review (operational impact, implementation risk) ---

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
run_agent "delivery-review" "$PROMPT"

# Validate all eight dimensions have a finding
MISSING=""
for dim in robustness simplicity "strategic alignment" "technical feasibility" \
           security "customer value" "operational impact" "implementation risk"; do
  grep -qiE "Finding:.*${dim}" "$WORKING" || MISSING="$MISSING dim:${dim// /_}"
done
if [ -n "$MISSING" ]; then
  echo "review working artifact failed validation — missing:$MISSING" >&2
  echo "agent output kept at $WORKING for inspection" >&2
  exit 1
fi

echo
echo "review working artifact: $WORKING"
echo "findings: $(grep -c '^### Finding:' "$WORKING")"
