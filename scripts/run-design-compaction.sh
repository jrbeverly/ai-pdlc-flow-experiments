#!/usr/bin/env bash
set -euo pipefail

# Design stage, step 2 of 2: compaction. Runs the compaction agent over the
# design working material to produce Proposed Design v1 (the new
# authoritative artifact), verifies it, and marks the working material
# superseded. Framing v2 remains the authoritative framing — this stage
# produces the authoritative design alongside it.

cd "$(dirname "$0")/.."

WORKING="artifacts/design-working.md"
CONTEXT="context/organizational-context.md"
V1="artifacts/proposed-design-v1.md"

for f in "$CONTEXT" "$WORKING"; do
  [ -f "$f" ] || { echo "missing input: $f" >&2; exit 1; }
done

grep -q '^state: working' "$WORKING" || {
  echo "refusing: $WORKING is not working material — remove it for a fresh run" >&2
  exit 1
}

if [ -f "$V1" ]; then
  echo "refusing: $V1 already exists — remove it for a fresh run" >&2
  exit 1
fi

PROMPT="$(cat <<EOF
You are the compaction agent for the design stage of an AI-guided
product-development pipeline. Below is the complete working material: the
authoritative framing (embedded in the working artifact) and the design
agents' proposals with their disagreements. You have no tools; reply with
plain markdown only, never tool-call syntax.

Compaction is not summarization. Produce the next generation of the
authoritative artifact: the proposed design representing the strongest
current understanding of what to build.

Output the artifact and nothing else. Start with this provenance frontmatter
(verbatim, except replace the confidence number with your honest assessment
of the proposed design, 0 to 1):

---
state: authoritative
generation: 3
supersedes: design-working
derived_from:
  - framing-v2
  - design-working
confidence: 0.7
---

Then the title "# Proposed Design v1", then exactly these sections with "## "
headers, in this order:

## Chosen design

## Why this design was chosen

## Trade-offs accepted

## Designs considered and not chosen

## Unresolved questions for experimentation

## Confidence

Rules:
- Select the design direction that is the strongest current understanding:
  you may choose one proposal or synthesize the best of the proposals into
  one coherent direction, but the output must be a single proposed design.
- Chosen design must describe the direction completely enough for the next
  stage: its approach, system primitives, architecture, user workflows,
  failure modes, operational complexity, security implications, and
  implementation constraints. Use "### " subheadings inside the section.
- Every section must be specific to this framing. No boilerplate.
- No contradiction or disagreement present in the working material may be
  carried forward unresolved. For each: resolve it where the material or the
  organizational context supports a resolution, and say why; otherwise list
  it under Unresolved questions for experimentation.
- Why this design was chosen must argue against the organizational priority
  order and the framing's constraints, and say why the chosen direction wins
  over the others.
- Trade-offs accepted must state at least one trade-off as a consequence the
  organization accepts, not merely a risk to watch.
- Designs considered and not chosen must name each alternative proposal and
  say, in substance, why it was not chosen.
- Unresolved questions for experimentation are the input to the next stage
  (experimentation). For each question, give the cheapest experiment that
  would materially move confidence: hypothesis, experiment, success signal,
  failure signal. Only questions an experiment could answer belong here;
  questions only a stakeholder can answer belong in the proposal's
  constraints, not this list.
- Confidence states the confidence in the proposed design overall and names
  the largest source of uncertainty.

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
V1_CONTENT="$(printf '%s' "$PROMPT" | timeout 900 claude -p --tools "" | awk '!/^<\|/')"
printf '%s\n' "$V1_CONTENT" > "$V1"

# Verify the authoritative artifact before touching anything else.
MISSING=""
grep -q '^state: authoritative' "$V1" || MISSING="$MISSING state"
grep -q '^generation: 3' "$V1" || MISSING="$MISSING generation"
grep -q '^supersedes: design-working' "$V1" || MISSING="$MISSING supersedes"
grep -q '^derived_from:' "$V1" || MISSING="$MISSING derived_from"
for section in "chosen design" "why this design was chosen" \
               "trade-offs accepted" "designs considered and not chosen" \
               "unresolved questions for experimentation" "confidence"; do
  grep -qiE "^#+ .*${section}" "$V1" || MISSING="$MISSING section:$section"
done
if [ -n "$MISSING" ]; then
  echo "Proposed Design v1 failed verification — missing:$MISSING" >&2
  echo "agent output kept at $V1 for inspection; working material untouched" >&2
  exit 1
fi

# Compaction consumed the working material: mark it superseded. Only its own
# frontmatter (its first --- block); the embedded framing quote stays intact.
tmp="$(mktemp)"
awk 'NR==1 && $0=="---" {fm=1; print; next}
     fm && $0=="---" {fm=0; print; next}
     fm && /^state: working$/ {print "state: stale"; print "superseded_by: proposed-design-v1"; next}
     {print}' "$WORKING" > "$tmp"
mv "$tmp" "$WORKING"

echo
echo "authoritative proposed design: $V1"
grep -n '^state:\|^generation:\|^supersedes:\|^superseded_by:\|^confidence:' \
  "$V1" "$WORKING" artifacts/framing-v2.md
