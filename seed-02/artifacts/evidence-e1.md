---
state: working
derived_from:
  - experiment-working
---

# Evidence: E1 mock experiment

## What was run

`scripts/run-experiment.sh` — no external systems or infrastructure. Twelve
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
| no brief | 6 | 50% | 33% | 18.7 min |
| brief-assisted | 6 | 66% | 0% | 7.0 min |

## Signal matched

**success**

The success signal from the hypothesis stated that anchored-denial rate in
the brief-assisted group is ≥ the rate in the no-brief group, while average
review time in the brief-assisted group is lower. The failure signal stated
that anchored-denial rate falls in the brief-assisted group, indicating
accuracy was traded for speed.

Observed: brief-assisted anchored-denial rate 66% vs. no-brief
50%; brief-assisted avg review time 7.0 min vs. no-brief
18.7 min. The success signal condition is met.

## Interpretation

This is a mock experiment with synthetic data; statistical conclusions do
not follow. The loop mechanics work: hypothesis stated before run, experiment
ran from the runbook, evidence recorded, signal identified. The result is a
weak positive first indicator for A5: in the synthetic data, brief-assisted
reviews showed a higher anchored-denial rate and zero subsequent rework at
materially lower review time. The signal must be reproduced on P0 real data
before any design decision rests on it.
