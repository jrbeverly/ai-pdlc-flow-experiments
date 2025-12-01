# Runbook

Command sequence for a pipeline run. Stages 0–2 are complete; stages 3–5 are
placeholders — each stage's issue adds its commands here. Run stages in order
and only after the stage before them has completed.

## Stage 0 — Foundation

The ground layer: seed raw thought, organizational context, lifecycle
convention. These commands verify it is in place:

```bash
# ground layer present?
ls artifacts/raw-thought.md context/organizational-context.md

# the seed is working material, generation 1
grep -n '^state:' artifacts/raw-thought.md
grep -n '^generation:' artifacts/raw-thought.md
```

## Stage 1 — Framing

Framing agents develop the raw thought into a working framing (`VISION.md`:
"AI-guided framing"); compaction produces the authoritative framing.

```bash
# the three framing agents append their entries to
# artifacts/framing-working.md; their questions are collected into
# artifacts/framing-questions.md
./scripts/run-framing-agents.sh

# THE ONLY HUMAN STEP: edit artifacts/framing-questions.md and answer each
# question under its **Answer:** marker. Nothing else in the stage needs a
# human.

# merge the answers into the working artifact, compact it into Framing v2,
# and mark the working material superseded
./scripts/run-compaction.sh

# the current understanding is artifacts/framing-v2.md (state: authoritative)
grep -n '^state:' artifacts/raw-thought.md artifacts/framing-working.md \
  artifacts/framing-questions.md artifacts/framing-v2.md
grep -n '^supersedes:\|^derived_from:' artifacts/framing-v2.md
```

## Stage 2 — Design

Design agents explore the solution space from the authoritative framing
(`VISION.md`: "Moving from framing into design"); their proposals coexist in
a working artifact and are allowed to disagree; compaction produces the
proposed design. No human step in this stage.

```bash
# the three design agents append their proposals to
# artifacts/design-working.md
./scripts/run-design-agents.sh

# compaction distills the proposals into Proposed Design v1 and marks the
# working material superseded
./scripts/run-design-compaction.sh

# the current proposed design is artifacts/proposed-design-v1.md
# (state: authoritative); Framing v2 stays the authoritative framing
grep -n '^state:' artifacts/proposed-design-v1.md artifacts/design-working.md \
  artifacts/framing-v2.md
grep -n '^supersedes:\|^derived_from:' artifacts/proposed-design-v1.md
```

## Stage 3 — Experimentation

Hypothesis, experiment, evidence, amendment loop (`VISION.md`:
"Experimentation as a confidence-building mechanism"); compaction folds the
results into Proposed Design v2.

```bash
# state the selected question, hypothesis, experiment, and signals before
# the experiment runs
./scripts/run-experiment-hypothesis.sh

# (no human step — the experiment uses hardcoded synthetic data)

# run the mock experiment; appends outcome to working material and writes
# the evidence artifact
./scripts/run-experiment.sh

# feed the evidence into an amendment and compact to Proposed Design v2
./scripts/run-experiment-compaction.sh

# Proposed Design v2 is now authoritative; v1 is stale
grep -n '^state:' artifacts/proposed-design-v1.md artifacts/proposed-design-v2.md
grep -n '^supersedes:\|^derived_from:' artifacts/proposed-design-v2.md
```

## Stage 4 — Promotion

Multi-agent review of Proposed Design v2 across the eight promotion-review
dimensions (`VISION.md`: "Promotion into delivery"); significant findings are
remediated before compaction into the Authoritative Workstream; a derived task
list demonstrates downstream consumability.

```bash
# three review agents score Proposed Design v2 and append findings to the
# review working artifact
./scripts/run-review-agents.sh

# compact review findings into the Authoritative Workstream; append final
# dispositions to the review working artifact; derive the demonstration task
# list; mark Proposed Design v2 stale
./scripts/run-promotion-compaction.sh

# Authoritative Workstream is now authoritative; Proposed Design v2 is stale
grep -n '^state:' artifacts/proposed-design-v2.md artifacts/authoritative-workstream.md
grep -n '^supersedes:\|^derived_from:' artifacts/authoritative-workstream.md
```

## Stage 5 — End-to-end evaluation

A second, different seed through the complete pipeline as the repeatability
check. The second seed runs in `seed-02/`, which contains copies of the
scripts and context unchanged from the main directory, plus its own
`artifacts/` tree.

```bash
# create the second-seed run directory (scripts and context copied verbatim)
mkdir -p seed-02/artifacts seed-02/context seed-02/scripts
cp context/organizational-context.md seed-02/context/
cp scripts/*.sh seed-02/scripts/
chmod +x seed-02/scripts/*.sh

# HUMAN STEP 0: write seed-02/artifacts/raw-thought.md — a raw thought in a
# domain different from the first seed. The file must carry state: working
# and generation: 1 frontmatter.

# verify the ground layer
ls seed-02/artifacts/raw-thought.md seed-02/context/organizational-context.md
grep -n '^state:' seed-02/artifacts/raw-thought.md
grep -n '^generation:' seed-02/artifacts/raw-thought.md

# Stage 1 — Framing (from seed-02/)
bash seed-02/scripts/run-framing-agents.sh

# HUMAN STEP 1: edit seed-02/artifacts/framing-questions.md and answer each
# question under its **Answer:** marker. Nothing else in the stage needs a human.

bash seed-02/scripts/run-compaction.sh

grep -n '^state:' seed-02/artifacts/raw-thought.md \
  seed-02/artifacts/framing-working.md \
  seed-02/artifacts/framing-questions.md \
  seed-02/artifacts/framing-v2.md
grep -n '^supersedes:\|^derived_from:' seed-02/artifacts/framing-v2.md

# Stage 2 — Design (no human step)
bash seed-02/scripts/run-design-agents.sh
bash seed-02/scripts/run-design-compaction.sh

grep -n '^state:' seed-02/artifacts/proposed-design-v1.md \
  seed-02/artifacts/design-working.md \
  seed-02/artifacts/framing-v2.md
grep -n '^supersedes:\|^derived_from:' seed-02/artifacts/proposed-design-v1.md

# Stage 3 — Experimentation (no human step; note: hypothesis script contains
# first-seed domain content — see Notes for the repeatability finding)
bash seed-02/scripts/run-experiment-hypothesis.sh
bash seed-02/scripts/run-experiment.sh
bash seed-02/scripts/run-experiment-compaction.sh

grep -n '^state:' seed-02/artifacts/proposed-design-v1.md \
  seed-02/artifacts/proposed-design-v2.md
grep -n '^supersedes:\|^derived_from:' seed-02/artifacts/proposed-design-v2.md

# Stage 4 — Promotion (no human step)
bash seed-02/scripts/run-review-agents.sh
bash seed-02/scripts/run-promotion-compaction.sh

grep -n '^state:' seed-02/artifacts/proposed-design-v2.md \
  seed-02/artifacts/authoritative-workstream.md
grep -n '^supersedes:\|^derived_from:' seed-02/artifacts/authoritative-workstream.md
```
