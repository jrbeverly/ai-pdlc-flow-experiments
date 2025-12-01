#!/usr/bin/env bash
set -euo pipefail

# Design stage, step 1 of 2: three design agents, each developing a
# different approach into a full design proposal in the working artifact.
# The proposals coexist and are expected to disagree; disagreement is
# recorded, not reconciled away. No human step — the stage consumes only
# Framing v2 and the organizational context.

cd "$(dirname "$0")/.."

FRAMING="artifacts/framing-v2.md"
CONTEXT="context/organizational-context.md"
WORKING="artifacts/design-working.md"

for f in "$FRAMING" "$CONTEXT"; do
  [ -f "$f" ] || { echo "missing input: $f" >&2; exit 1; }
done

grep -q '^state: authoritative' "$FRAMING" || {
  echo "refusing: $FRAMING is not authoritative — run Stage 1 first" >&2
  exit 1
}

if [ -f "$WORKING" ]; then
  echo "refusing: $WORKING already exists — remove it for a fresh run" >&2
  exit 1
fi

cat > "$WORKING" <<EOF
---
state: working
derived_from:
  - framing-v2
---

# Design working artifact

Working material for Proposed Design v1. Messy by design: the proposals
below develop different approaches into the solution space and are expected
to disagree with each other and with the framing. The compaction step
distills this into the authoritative proposed design; disagreement is
recorded here, not reconciled away.

## Input: Framing v2

EOF
cat "$FRAMING" >> "$WORKING"

# prompt goes via stdin; --tools "" keeps the model from emitting tool calls;
# the <| filter drops any tool-call syntax that leaks through anyway. Design
# prompts are several times the framing stage's size; the bound is set
# accordingly.
run_agent() {
  local name="$1" prompt="$2" resp
  echo "== design agent: $name"
  resp="$(printf '%s' "$prompt" | timeout 900 claude -p --tools "" | awk '!/^<\|/')"
  {
    echo
    echo "## Design proposal — $name"
    echo
    printf '%s\n' "$resp"
  } >> "$WORKING"
}

# --- Agent 1: classify-and-auto-approve -----------------------------------

PROMPT="$(cat <<EOF
You are a design agent in an AI-guided product-development pipeline. The
framing is complete; your job is to design, not to re-frame the problem. You
have no tools; reply with plain markdown only, never tool-call syntax.

Develop the following approach into a full design proposal:

**Classify changes by risk and automatically approve the low-risk ones.** A
machine classifier evaluates every deployment from pipeline evidence; changes
it classifies low-risk are approved automatically; everything else goes to a
human reviewer. The classifier runs in shadow mode alongside the human gate
until its false-negative performance on the rare dangerous class is
demonstrated, then cuts over.

You are the design owner for the dimensions: system primitives, architecture,
failure modes, and security implications — on those, be concrete and rigorous.
Later agents will read your proposal and may disagree with you; do not soften
your position for them.

Organizational context:
--- 8< ---
$(cat "$CONTEXT")
--- 8< ---

Authoritative framing:
--- 8< ---
$(cat "$FRAMING")
--- 8< ---

Write your proposal in markdown with exactly these sections, in this order,
each a "### " header:

### Approach

### System primitives

### Architecture

### User workflows

### Failure modes

### Operational complexity

### Security implications

### Implementation constraints

### Alternatives considered

- Be specific to this framing; quote it where you build on or challenge it.
- Do not restate the framing at length. Where the framing leaves a decision
  open, design against it or name it as a design assumption — never silently
  resolve it.
- Under "Alternatives considered", name the variant approaches inside your
  own direction that you rejected and why.
EOF
)"
run_agent "classify-and-auto-approve" "$PROMPT"

# --- Agent 2: policy-replaces-approval -------------------------------------

PROMPT="$(cat <<EOF
You are a design agent in an AI-guided product-development pipeline. The
framing is complete; your job is to design, not to re-frame the problem. You
have no tools; reply with plain markdown only, never tool-call syntax.

Develop the following approach into a full design proposal:

**Eliminate the approval concept for qualifying deployments and enforce the
guarantees entirely in automated policy.** A deployment that satisfies the
machine-checkable policy proceeds without any human decision; the policy
evaluation itself is the auditable deployment decision, with a named
accountable party recorded. Guarantees become policy rules.

You are the design owner for the dimensions: security implications,
operational complexity, and implementation constraints — on those, be
concrete and rigorous. Later agents will read your proposal and may disagree
with you; do not soften your position for them.

Organizational context:
--- 8< ---
$(cat "$CONTEXT")
--- 8< ---

Working artifact so far — the authoritative framing plus proposals written
by agents before you:
--- 8< ---
$(cat "$WORKING")
--- 8< ---

Write your proposal in markdown with exactly these sections, in this order,
each a "### " header:

### Approach

### System primitives

### Architecture

### User workflows

### Failure modes

### Operational complexity

### Security implications

### Implementation constraints

### Alternatives considered

### Disagreements with earlier proposals

- Be specific to this framing; quote it where you build on or challenge it.
- Do not restate the framing at length. Where the framing leaves a decision
  open, design against it or name it as a design assumption — never silently
  resolve it.
- Under "Alternatives considered", name the variant approaches inside your
  own direction that you rejected and why.
- Under "Disagreements with earlier proposals", disagree plainly where an
  earlier proposal makes a choice you would not make or leans on an
  unproven assumption. Record the disagreement; do not converge.
EOF
)"
run_agent "policy-replaces-approval" "$PROMPT"

# --- Agent 3: differentiated-human-review ----------------------------------

PROMPT="$(cat <<EOF
You are a design agent in an AI-guided product-development pipeline. The
framing is complete; your job is to design, not to re-frame the problem. You
have no tools; reply with plain markdown only, never tool-call syntax.

Develop the following approach into a full design proposal:

**Keep approval as a human decision and re-engineer the attention around
it.** No deployment decision is automated. Changes are tiered, routed, and
batched by risk so reviewer attention lands where it matters; reviewers get
classification and policy assistance as pre-review evidence, and a named
accountable human still signs off every deployment.

You are the design owner for the dimensions: user workflows, operational
complexity, and alternatives — on those, be concrete and rigorous. You may
disagree with earlier proposals; do not soften your position for them.

Organizational context:
--- 8< ---
$(cat "$CONTEXT")
--- 8< ---

Working artifact so far — the authoritative framing plus proposals written
by agents before you:
--- 8< ---
$(cat "$WORKING")
--- 8< ---

Write your proposal in markdown with exactly these sections, in this order,
each a "### " header:

### Approach

### System primitives

### Architecture

### User workflows

### Failure modes

### Operational complexity

### Security implications

### Implementation constraints

### Alternatives considered

### Disagreements with earlier proposals

- Be specific to this framing; quote it where you build on or challenge it.
- Do not restate the framing at length. Where the framing leaves a decision
  open, design against it or name it as a design assumption — never silently
  resolve it.
- Under "Alternatives considered", name the variant approaches inside your
  own direction that you rejected and why — including the advisory-only
  recommendation and the default-approve-with-a-window variants, if you
  reject them.
- Under "Disagreements with earlier proposals", disagree plainly where an
  earlier proposal makes a choice you would not make or leans on an
  unproven assumption. Record the disagreement; do not converge.
EOF
)"
run_agent "differentiated-human-review" "$PROMPT"

# Verify the working artifact before finishing: at least two proposals, each
# covering the design perspectives the stage must cover together.
PROPOSALS="$(grep -c '^## Design proposal' "$WORKING")"
MISSING=""
[ "$PROPOSALS" -ge 2 ] || MISSING="$MISSING proposals:$PROPOSALS"
for section in "Approach" "System primitives" "Architecture" "User workflows" \
               "Failure modes" "Operational complexity" "Security implications" \
               "Implementation constraints" "Alternatives considered"; do
  n="$(grep -c "^### ${section}\$" "$WORKING")"
  [ "$n" -ge "$PROPOSALS" ] || MISSING="$MISSING section:$section:$n"
done
if [ -n "$MISSING" ]; then
  echo "design working artifact failed verification — missing:$MISSING" >&2
  echo "agent output kept at $WORKING for inspection" >&2
  exit 1
fi

echo
echo "working artifact: $WORKING"
echo "proposals: $PROPOSALS"
