#!/usr/bin/env bash
set -euo pipefail

# Experimentation stage, step 3 of 3: amendment and compaction. Feeds the
# evidence from the E1 mock experiment into an amendment and produces
# Proposed Design v2 in the AUTHORITATIVE state, superseding v1.

cd "$(dirname "$0")/.."

V1="artifacts/proposed-design-v1.md"
WORKING="artifacts/experiment-working.md"
EVIDENCE="artifacts/evidence-e1.md"
CONTEXT="context/organizational-context.md"
V2="artifacts/proposed-design-v2.md"

for f in "$V1" "$WORKING" "$EVIDENCE" "$CONTEXT"; do
  [ -f "$f" ] || { echo "missing input: $f" >&2; exit 1; }
done

grep -q '^state: authoritative' "$V1" || {
  echo "refusing: $V1 is not authoritative" >&2; exit 1
}
grep -q '^## Outcome$' "$WORKING" || {
  echo "refusing: $WORKING has no Outcome section — run experiment step first" >&2; exit 1
}

if [ -f "$V2" ]; then
  echo "refusing: $V2 already exists — remove it for a fresh run" >&2
  exit 1
fi

PROMPT="$(cat <<EOF
You are the compaction agent for the experimentation stage of an AI-guided
product-development pipeline. You have no tools; reply with plain markdown
only, never tool-call syntax.

Your task: apply the evidence from the E1 mock experiment to Proposed Design
v1 and produce Proposed Design v2. Compaction is not summarization. The
output is a new generation of the authoritative design, amended where the
evidence speaks to it, with the amendment stated explicitly.

Rules:
- The FIRST section must be "## Amendments from v1". Name each section
  changed, state the change in one sentence, and say why the evidence
  justifies it. At least one amendment is required.
- Retain every section from v1 verbatim unless the evidence changes it.
  Do not rewrite sections the evidence does not touch.
- Under "Unresolved questions for experimentation", update E1's entry to
  reflect the signal matched (success or failure) and what it means: does
  E1 move from open to partially answered, or does it require a different
  experiment next?
- Under "Security implications" and/or "Confidence", update any claim that
  A5 is "unevidenced" to reflect the mock experiment's result; name the
  evidence artifact.
- The Confidence section must state the updated confidence level and say
  whether and why it changed.
- v2 differs from v1 by at least the stated amendment; do not merely bump
  the version and leave the body identical.

Output the artifact and nothing else. Start with this provenance frontmatter
(verbatim, except replace confidence with your honest assessment):

---
state: authoritative
generation: 4
supersedes: proposed-design-v1
derived_from:
  - proposed-design-v1
  - evidence-e1
confidence: 0.68
---

Then the title "# Proposed Design v2", then these sections with "## " headers
in this order (use "### " subheadings inside "Chosen design" as v1 had):

## Amendments from v1
## Chosen design
## Why this design was chosen
## Trade-offs accepted
## Designs considered and not chosen
## Unresolved questions for experimentation
## Confidence

Organizational context:
--- 8< ---
$(cat "$CONTEXT")
--- 8< ---

Proposed Design v1:
--- 8< ---
$(cat "$V1")
--- 8< ---

Evidence — E1 mock experiment:
--- 8< ---
$(cat "$EVIDENCE")
--- 8< ---

Experiment working artifact:
--- 8< ---
$(cat "$WORKING")
--- 8< ---
EOF
)"

echo "== compaction agent"
V2_CONTENT="$(printf '%s' "$PROMPT" | timeout 900 claude -p --tools "" | awk '!/^<\|/')"
printf '%s\n' "$V2_CONTENT" > "$V2"

# Verify the authoritative artifact before touching anything else.
MISSING=""
grep -q '^state: authoritative' "$V2"               || MISSING="$MISSING state"
grep -q '^generation: 4' "$V2"                       || MISSING="$MISSING generation"
grep -q '^supersedes: proposed-design-v1' "$V2"      || MISSING="$MISSING supersedes"
grep -q 'evidence-e1' "$V2"                          || MISSING="$MISSING derived_from:evidence-e1"
for section in "amendments from v1" "chosen design" "why this design was chosen" \
               "trade-offs accepted" "designs considered and not chosen" \
               "unresolved questions for experimentation" "confidence"; do
  grep -qiE "^#+ .*${section}" "$V2" || MISSING="$MISSING section:$section"
done
if [ -n "$MISSING" ]; then
  echo "Proposed Design v2 failed verification — missing:$MISSING" >&2
  echo "agent output kept at $V2 for inspection; working material untouched" >&2
  exit 1
fi

# Mark v1 as stale.
tmp="$(mktemp)"
awk 'NR==1 && $0=="---" {fm=1; print; next}
     fm && $0=="---" {fm=0; print; next}
     fm && /^state: authoritative$/ {print "state: stale"; print "superseded_by: proposed-design-v2"; next}
     {print}' "$V1" > "$tmp"
mv "$tmp" "$V1"

echo
echo "authoritative proposed design: $V2"
grep -n '^state:\|^generation:\|^supersedes:\|^superseded_by:\|^confidence:' \
  "$V2" "$V1" artifacts/framing-v2.md
