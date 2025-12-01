#!/usr/bin/env bash
set -euo pipefail

# Framing stage, step 2 of 2: compaction. Merges the answered questions into
# the working artifact, runs the compaction agent to produce Framing v2 (the
# new authoritative artifact), verifies it, and marks the working material
# superseded.

cd "$(dirname "$0")/.."

CONTEXT="context/organizational-context.md"
WORKING="artifacts/framing-working.md"
QUESTIONS="artifacts/framing-questions.md"
V2="artifacts/framing-v2.md"

for f in "$CONTEXT" "$WORKING" "$QUESTIONS"; do
  [ -f "$f" ] || { echo "missing input: $f" >&2; exit 1; }
done

if [ -f "$V2" ]; then
  echo "refusing: $V2 already exists — remove it for a fresh run" >&2
  exit 1
fi

# every question must have a non-empty answer before compaction
UNANSWERED="$(awk '
  /^\*\*Answer:\*\*/ { need=1; next }
  need && /^[[:space:]]*$/ { next }
  need { need=0 }
  END { if (need) print "unanswered question: last **Answer:** marker has no answer" }
' "$QUESTIONS")"
if [ -n "$UNANSWERED" ]; then
  echo "$UNANSWERED in $QUESTIONS" >&2
  exit 1
fi

echo "answer slots in $QUESTIONS: $(grep -c '^\*\*Answer:\*\*' "$QUESTIONS")"

# The answers are part of the working artifact.
if ! grep -q '^## Human answers' "$WORKING"; then
  {
    echo
    echo "## Human answers"
    echo
    awk 'NR==1 && $0=="---"{fm=1; next} fm && $0=="---"{fm=0; next} !fm{print}' "$QUESTIONS"
  } >> "$WORKING"
fi

PROMPT="$(cat <<EOF
You are the compaction agent for the framing stage of an AI-guided
product-development pipeline. Below is the complete working material: the
seed, the framing agents' entries with their disagreements, and the human's
answers to the agents' questions. You have no tools; reply with plain
markdown only, never tool-call syntax.

Compaction is not summarization. Produce the next generation of the
authoritative artifact: a clean document representing what is currently
believed to be true about the problem.

Output the artifact and nothing else. Start with this provenance frontmatter
(verbatim, except replace the confidence number with your honest assessment
of the framing, 0 to 1):

---
state: authoritative
generation: 2
supersedes: framing-working
derived_from:
  - raw-thought
  - framing-working
  - framing-questions
confidence: 0.8
---

Then the title "# Framing v2", then exactly these sections with "## " headers,
in this order:

## Problem statement
## Desired outcome
## Relevant context
## Core primitives
## Priorities
## Constraints
## Assumptions
## Decisions made
## Alternatives considered
## Unresolved questions
## Confidence

Rules:
- Every section must be specific to this seed. No boilerplate.
- No contradiction or disagreement present in the working material may be
  carried forward unresolved. For each: resolve it where the material or the
  organizational context supports a resolution, and say why; otherwise list
  it under Unresolved questions.
- Priorities must reflect the organizational priority order applied to this
  problem; state where the ordering of lower priorities is unknown.
- Decisions made holds what the human actually decided in the answers;
  Assumptions holds what remains assumed, including assumptions the human did
  not confirm or deny.
- Confidence states the confidence in the framing overall and names the
  largest source of uncertainty.

Organizational context:
--- 8< ---
$(cat "$CONTEXT")
--- 8< ---

Working material:
--- 8< ---
$(cat "$WORKING")
--- 8< ---
EOF
)"

echo "== compaction agent"
V2_CONTENT="$(printf '%s' "$PROMPT" | timeout 300 claude -p --tools "" | awk '!/^<\|/')"
printf '%s\n' "$V2_CONTENT" > "$V2"

# Verify the authoritative artifact before touching anything else.
MISSING=""
grep -q '^state: authoritative' "$V2" || MISSING="$MISSING state"
grep -q '^generation: 2' "$V2" || MISSING="$MISSING generation"
grep -q '^supersedes: framing-working' "$V2" || MISSING="$MISSING supersedes"
grep -q '^derived_from:' "$V2" || MISSING="$MISSING derived_from"
for section in "problem statement" "desired outcome" "relevant context" \
               "core primitives" "priorities" "constraints" "assumptions" \
               "decisions made" "alternatives considered" \
               "unresolved questions" "confidence"; do
  grep -qiE "^#+ .*${section}" "$V2" || MISSING="$MISSING section:$section"
done
if [ -n "$MISSING" ]; then
  echo "Framing v2 failed verification — missing:$MISSING" >&2
  echo "agent output kept at $V2 for inspection; working material untouched" >&2
  exit 1
fi

# Compaction consumed the working material: mark it superseded. Only each
# file's own frontmatter (its first --- block); embedded quotes stay intact.
for f in artifacts/raw-thought.md "$WORKING" "$QUESTIONS"; do
  tmp="$(mktemp)"
  awk 'NR==1 && $0=="---" {fm=1; print; next}
       fm && $0=="---" {fm=0; print; next}
       fm && /^state: working$/ {print "state: stale"; print "superseded_by: framing-v2"; next}
       {print}' "$f" > "$tmp"
  mv "$tmp" "$f"
done

echo
echo "authoritative framing: $V2"
grep -n '^state:\|^generation:\|^superseded_by:\|^confidence:' \
  "$V2" artifacts/raw-thought.md "$WORKING" "$QUESTIONS"
