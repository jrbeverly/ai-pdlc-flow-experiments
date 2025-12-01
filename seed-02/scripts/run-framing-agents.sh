#!/usr/bin/env bash
set -euo pipefail

# Framing stage, step 1 of 2: three framing agents append their entries to
# the working artifact; their questions are collected into the questions
# file — the only file a human edits.

cd "$(dirname "$0")/.."

SEED="artifacts/raw-thought.md"
CONTEXT="context/organizational-context.md"
WORKING="artifacts/framing-working.md"
QUESTIONS="artifacts/framing-questions.md"

for f in "$SEED" "$CONTEXT"; do
  [ -f "$f" ] || { echo "missing input: $f" >&2; exit 1; }
done

if [ -f "$WORKING" ]; then
  echo "refusing: $WORKING already exists — remove it for a fresh run" >&2
  exit 1
fi

cat > "$WORKING" <<EOF
---
state: working
derived_from:
  - raw-thought
---

# Framing working artifact

Working material for Framing v2. Messy by design: entries may contradict the
seed and each other. The compaction step distills this into the authoritative
framing.

## Seed

EOF
cat "$SEED" >> "$WORKING"

cat > "$QUESTIONS" <<'EOF'
---
state: working
derived_from:
  - framing-working
---

# Framing questions

Collected from the framing agents. This file is the only human input the
stage requires: answer each question under its `**Answer:**` line, then run
the compaction step.

EOF

# prompt goes via stdin; --tools "" keeps the model from emitting tool calls;
# the <| filter drops any tool-call syntax that leaks through anyway
run_agent() {
  local name="$1" prompt="$2" resp qs
  echo "== framing agent: $name"
  resp="$(printf '%s' "$prompt" | timeout 300 claude -p --tools "" | awk '!/^<\|/')"
  {
    echo
    echo "## Agent entry — $name"
    echo
    printf '%s\n' "$resp"
  } >> "$WORKING"
  qs="$(printf '%s\n' "$resp" | awk '/^#+ Questions/{f=1;next} f&&/^#+ /{exit} f' | grep -E '^[[:space:]]*- ' || true)"
  if [ -n "$qs" ]; then
    {
      echo
      echo "## From: $name"
      echo
      printf '%s\n' "$qs"
      echo
      echo "**Answer:** _(edit this file — write your answer below this line)_"
      echo
    } >> "$QUESTIONS"
  fi
}

# --- Agent 1: outcome-and-users -------------------------------------------

PROMPT="$(cat <<EOF
You are a framing agent in an AI-guided product-framing pipeline. Framing
agents turn a raw thought into a clearer understanding of the problem. You do
not design or propose solutions. You have no tools; reply with plain
markdown only, never tool-call syntax.

Your perspective is outcomes and users. You are responsible for the
dimensions: desired outcomes, affected users, priorities. Apply the
organizational priority order when reasoning about trade-offs, and say
plainly where the seed is unclear about what success looks like or who is
affected.

Organizational context:
--- 8< ---
$(cat "$CONTEXT")
--- 8< ---

Seed raw thought:
--- 8< ---
$(cat "$SEED")
--- 8< ---

Write your entry in markdown with exactly these sections, in this order:

## Analysis

## Disagreements and tensions

## Questions

- Be specific to this seed; quote it where you build on or challenge it.
- Under "Disagreements and tensions", note where the seed's stated goals
  conflict with the priority order, or where its assumptions are untested.
  Later agents will read your entry and may disagree with you; do not soften
  your position for them.
- Under "Questions", list only questions whose answers would materially
  improve the framing, one per line, each starting with "- ". If you have
  none, write "None."
EOF
)"
run_agent "outcome-and-users" "$PROMPT"

# --- Agent 2: risk-and-constraints ----------------------------------------

PROMPT="$(cat <<EOF
You are a framing agent in an AI-guided product-framing pipeline. Framing
agents turn a raw thought into a clearer understanding of the problem. You do
not design or propose solutions. You have no tools; reply with plain
markdown only, never tool-call syntax.

Your perspective is risks and constraints. You are responsible for the
dimensions: risks, constraints, dependencies, assumptions. Stress-test every
assumption the seed states against the organizational constraints and the
priority order. Name the dependencies the seed does not mention. For each
risk you raise, say what makes it material.

Organizational context:
--- 8< ---
$(cat "$CONTEXT")
--- 8< ---

Seed raw thought:
--- 8< ---
$(cat "$SEED")
--- 8< ---

Entries written by agents before you:
--- 8< ---
$(cat "$WORKING")
--- 8< ---

Write your entry in markdown with exactly these sections, in this order:

## Analysis

## Disagreements and tensions

## Questions

- Be specific to this seed; quote it where you challenge it.
- Under "Disagreements and tensions", disagree plainly where the seed or an
  earlier agent understates a risk or leans on an unproven assumption.
- Under "Questions", list only questions whose answers would materially
  improve the framing, one per line, each starting with "- ". If you have
  none, write "None."
EOF
)"
run_agent "risk-and-constraints" "$PROMPT"

# --- Agent 3: ambiguity-and-decisions -------------------------------------

PROMPT="$(cat <<EOF
You are a framing agent in an AI-guided product-framing pipeline. Framing
agents turn a raw thought into a clearer understanding of the problem. You do
not design or propose solutions. You have no tools; reply with plain
markdown only, never tool-call syntax.

Your perspective is ambiguity and decisions. You are responsible for the
dimensions: ambiguity, unresolved decisions, alternative interpretations.
Name the alternative readings of the problem — including the ones the seed
itself floats (automate approvals, replace approval with policy, change the
deployment model) — and say what each reading would change about the
framing. Identify the decisions that are still open and who would need to
make them.

Organizational context:
--- 8< ---
$(cat "$CONTEXT")
--- 8< ---

Seed raw thought:
--- 8< ---
$(cat "$SEED")
--- 8< ---

Entries written by agents before you:
--- 8< ---
$(cat "$WORKING")
--- 8< ---

Write your entry in markdown with exactly these sections, in this order:

## Analysis

## Disagreements and tensions

## Questions

- Be specific to this seed; quote it where you build on or challenge it.
- Under "Disagreements and tensions", disagree where earlier entries pick one
  reading of the problem without argument.
- Under "Questions", list only questions whose answers would materially
  improve the framing, one per line, each starting with "- ". If you have
  none, write "None."
EOF
)"
run_agent "ambiguity-and-decisions" "$PROMPT"

echo
echo "working artifact: $WORKING"
echo "questions (answer these next): $QUESTIONS"
