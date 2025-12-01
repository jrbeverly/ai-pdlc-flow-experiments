#!/usr/bin/env bash
set -euo pipefail

# Promotion stage, step 2 of 2: compact review findings and Proposed Design v2
# into the Authoritative Workstream; append final dispositions to the review
# working artifact; derive the demonstration task list; mark v2 stale.

cd "$(dirname "$0")/.."

V2="artifacts/proposed-design-v2.md"
REVIEW="artifacts/review-working.md"
CONTEXT="context/organizational-context.md"
WORKSTREAM="artifacts/authoritative-workstream.md"
TASKLIST="artifacts/task-list-demo.md"

for f in "$V2" "$REVIEW" "$CONTEXT"; do
  [ -f "$f" ] || { echo "missing input: $f" >&2; exit 1; }
done

grep -q '^state: authoritative' "$V2" || {
  echo "refusing: $V2 is not authoritative" >&2; exit 1
}
grep -qiE "^### Finding:" "$REVIEW" || {
  echo "refusing: $REVIEW has no findings — run review step first" >&2; exit 1
}

if [ -f "$WORKSTREAM" ]; then
  echo "refusing: $WORKSTREAM already exists — remove it for a fresh run" >&2
  exit 1
fi

# --- Compaction agent ---

PROMPT="$(cat <<EOF
You are the compaction agent for the promotion stage of an AI-guided
product-development pipeline. You have no tools; reply with plain markdown
only, never tool-call syntax.

Your task: compact Proposed Design v2 and its multi-agent review findings
into the Authoritative Workstream — the promotion target. This is a delivery
artifact, actionable and structured for downstream execution.

Instructions:
- Address every significant finding (Severity: significant) from the review
  working artifact. "Address" means the finding is reflected in the workstream
  as a phase gate, named constraint, explicit precondition, or stated
  measurement commitment. In the dispositions section, state which workstream
  section contains the reflection and in one sentence what was made explicit.
- Note trivial findings as dismissed: confirm the reason given by the review
  agent in brief.
- The workstream must read as a delivery brief, not a design exploration.
  Every section should let a reader start work from this document alone.

Output the artifact and nothing else. Start with this frontmatter (replace
confidence with your honest assessment):

---
state: authoritative
generation: 5
supersedes: proposed-design-v2
derived_from:
  - proposed-design-v2
  - review-working
confidence: 0.75
---

Then "# Authoritative Workstream: Approval Attention Engineering" followed by
these sections with "## " headers in this order:

## Goal
(problem statement and desired outcome — two paragraphs)

## Approach
(the chosen direction in three to five paragraphs: what it does, what it does
 not do, and the commitments that define it)

## System primitives
(the named data structures and concepts: evidence object, attention tier,
 attention policy, review brief, batch abstract, disposition record,
 escalation record, review-context record, attention ledger — one short
 paragraph each)

## Implementation phases
(P0 through P3 as named subsections ### P0, ### P1, ### P2, ### P3; each
 with: entry condition, what ships, who owns it, what it measures)

## Success metrics
(each metric as a named item with how it is collected and what success means)

## Operating bounds
(F1 through the bounded failure modes; each: what can go wrong, the bound
 already in the design, any addition from a significant finding)

## Security posture
(the security model, threat surface, and any explicit gate added from a
 significant security finding)

## Dependencies
(platform team work, new roles, external conversations — stacked P0-through-P3
 smallest-to-largest; flag critical-path items)

## Review findings and dispositions
(a table listing every finding from the review working artifact:

| dimension | severity | disposition |
|---|---|---|

For significant findings: "addressed — §<section name>: <one sentence of
what was added or made explicit>"
For trivial findings: "noted-and-dismissed — <the reason from the review
agent, confirmed in one sentence>")

Organizational context:
--- 8< ---
$(cat "$CONTEXT")
--- 8< ---

Proposed Design v2:
--- 8< ---
$(cat "$V2")
--- 8< ---

Review working artifact:
--- 8< ---
$(cat "$REVIEW")
--- 8< ---
EOF
)"

echo "== compaction agent"
WS_CONTENT="$(printf '%s' "$PROMPT" | timeout 900 claude -p --tools "" | awk '!/^<\|/')"
printf '%s\n' "$WS_CONTENT" > "$WORKSTREAM"

# Verify the authoritative workstream before touching anything else
MISSING=""
grep -q '^state: authoritative' "$WORKSTREAM"           || MISSING="$MISSING state"
grep -q '^generation: 5' "$WORKSTREAM"                  || MISSING="$MISSING generation"
grep -q '^supersedes: proposed-design-v2' "$WORKSTREAM" || MISSING="$MISSING supersedes"
grep -q 'review-working' "$WORKSTREAM"                  || MISSING="$MISSING derived_from"
for section in "goal" "approach" "system primitives" "implementation phases" \
               "success metrics" "operating bounds" "security posture" \
               "dependencies" "review findings"; do
  grep -qiE "^## .*${section}" "$WORKSTREAM" || MISSING="$MISSING section:${section// /-}"
done
if [ -n "$MISSING" ]; then
  echo "Authoritative Workstream failed verification — missing:$MISSING" >&2
  echo "agent output kept at $WORKSTREAM for inspection; working material untouched" >&2
  exit 1
fi

# Append the dispositions table from the workstream to the review working artifact
{
  echo
  echo "## Dispositions (post-compaction)"
  echo
  echo "Extracted from §Review findings and dispositions in the Authoritative Workstream:"
  echo
  awk '/^## Review findings/{p=1; next} p && /^## [A-Z]/{p=0} p{print}' "$WORKSTREAM"
} >> "$REVIEW"

# --- Task derivation agent ---

TASK_PROMPT="$(cat <<EOF
You are the task-derivation agent for the promotion stage of an AI-guided
product-development pipeline. You have no tools; reply with plain markdown
only, never tool-call syntax.

Derive a demonstration task list from the Authoritative Workstream. This is
not an implementation plan — it demonstrates that the workstream can feed
downstream execution.

Rules:
- Produce at least seven task items.
- Each task must name the workstream section it derives from using
  "**[§<section name>]**" at the start of the item text.
- Together the tasks must cover the entire workstream: every section must be
  the source of at least one task.
- Each task is one sentence in verb-object form, concrete enough to assign.
- No background, rationale, or explanation — one line per task.

Output the artifact and nothing else. Start with this frontmatter:

---
state: working
derived_from:
  - authoritative-workstream
---

Then:

# Task list (derived from Authoritative Workstream)

## Note

This is a demonstration artifact showing that the Authoritative Workstream
is structured to feed downstream execution. It is not an implementation plan.

## Tasks

(numbered list)

Authoritative Workstream:
--- 8< ---
$(cat "$WORKSTREAM")
--- 8< ---
EOF
)"

echo "== task derivation agent"
TASK_CONTENT="$(printf '%s' "$TASK_PROMPT" | timeout 900 claude -p --tools "" | awk '!/^<\|/')"
printf '%s\n' "$TASK_CONTENT" > "$TASKLIST"

# Validate the task list
TASK_COUNT="$(grep -cE '^[0-9]+\.' "$TASKLIST" 2>/dev/null || true)"
SECTION_REFS="$(grep -c '\[§' "$TASKLIST" 2>/dev/null || true)"
MISSING=""
[ "${TASK_COUNT:-0}" -ge 5 ]   || MISSING="$MISSING tasks:${TASK_COUNT:-0}<5"
[ "${SECTION_REFS:-0}" -ge 5 ] || MISSING="$MISSING section-refs:${SECTION_REFS:-0}<5"
grep -q '^derived_from:' "$TASKLIST" || MISSING="$MISSING frontmatter"
if [ -n "$MISSING" ]; then
  echo "Task list failed verification — missing:$MISSING" >&2
  echo "agent output kept at $TASKLIST for inspection" >&2
  exit 1
fi

# Mark proposed-design-v2 as stale
tmp="$(mktemp)"
awk 'NR==1 && $0=="---" {fm=1; print; next}
     fm && $0=="---" {fm=0; print; next}
     fm && /^state: authoritative$/ {print "state: stale"
                                      print "superseded_by: authoritative-workstream"; next}
     {print}' "$V2" > "$tmp"
mv "$tmp" "$V2"

echo
echo "authoritative workstream: $WORKSTREAM"
echo "task list: $TASKLIST"
grep -n '^state:\|^generation:\|^supersedes:\|^superseded_by:\|^confidence:' \
  "$WORKSTREAM" "$V2" artifacts/proposed-design-v1.md artifacts/framing-v2.md
