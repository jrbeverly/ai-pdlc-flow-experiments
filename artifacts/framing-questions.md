---
state: stale
superseded_by: framing-v2
derived_from:
  - framing-working
---

# Framing questions

Collected from the framing agents. This file is the only human input the
stage requires: answer each question under its `**Answer:**` line, then run
the compaction step.


## From: outcome-and-users

- What concrete guarantees does today's manual approval actually provide — human visibility of every change, a named accountable owner, an enforced pause before exposure, compliance or legal sign-off — and which of those must remain observable properties after the change?
- For which cohort is the outcome defined: low-risk changes only, or all deployments? Given fixed reviewer capacity, is the problem routine-approval volume, high-risk-change latency, or both — are they even the same problem?
- What is the operational definition of "low-risk" that the organization would accept, given the exact classification criteria are unresolved — and how do the seed's own examples (service bumps, config tweaks, copy tweaks) classify under it?
- Does the security team accept retrospectively inspectable automated decisions, or does it require a human accountable at decision time for some classes of change — and if so, which classes, on what criteria?
- If approval is dropped or automated, what must the audit record contain (policy version, all evidence inputs, the evaluation trace) for a third party after the fact to reconstruct why this deployment did not require a human?
- Who carries the cost of a false negative — a dangerous change auto-approved — and what maximum rate of such failures is acceptable before the priority-1 guarantee is considered lost?
- Should "low-risk" incorporate business/revenue impact at all, given the priority order only covers safety, reliability, velocity, and convenience — and where does the seed's copy-tweak example sit on that axis?
- Does reducing approver-hours actually require changing the approval concept at all, or is the problem the uniform application of one approval rule — i.e., is the deployment model the real target, as the seed half-suspects ("Maybe approval is a symptom and the deployment model is the problem")?

**Answer:**

1. The two guarantees I can name today: a human has looked at every change, and there is a recorded sign-off with a name attached. No enforced pause beyond the queue itself, no compliance sign-off. Those two — human visibility and a named decision — are what must survive in observable form. I can't name more without asking the approvers.
2. The outcome is about routine-change throughput for deployers and attention waste for reviewers. I am not claiming the high-risk path gets faster — it may get slower when reviewers stop rubber-stamping. Routine-approval volume is the problem; high-risk latency is a different problem I'm not solving here.
3. No accepted definition exists. I'd build it from failure mode and blast radius (what breaks, who's affected, how fast it's caught), not change type. By that test the seed's own examples split: service bumps and copy tweaks are low; config tweaks are NOT automatically low — feature flags, traffic routing, and security settings have wide blast radius. My notes lumped them together; that was wrong.
4. I have not asked them. That is the first conversation. The framing must treat this as open with both answers live, not assumed.
5. My bar: enough to reconstruct the decision — policy version, every evidence input, the evaluation trace, and a named accountable party. Reproducibility, not just a log line. I agree with the risk entry on this.
6. On-call and users absorb the cost. No rate has been set. I can't set it alone — security owns that threshold, and it should be set against the baseline's measured rate, not a guess.
7. Yes — the copy tweak shows why: operationally trivial can be business-critical. But the priority order has no business axis, so this needs either an explicit addition or a documented "deliberately excluded" decision. Unresolved until someone owns it.
8. No, it doesn't require it. Tiering, routing, and batching could reclaim attention without touching the approval concept. I suspect uniformity is the root cause but I'm not committing the framing to that — keep the deployment-model question as a reading, not a decision.


## From: risk-and-constraints

- What has today's manual approval actually blocked, and does a record exist — denied changes, reworked deploys, production incidents attributed to specific deployments — from which the baseline control's detection rate can be measured?
- Who owns the shared pipeline and the approval logic inside it, and can this team change the decision mechanism at all — and who approves the change that changes the approval process, under which rules, with what evidence?
- What is the revert path for a mis-auto-approved deployment: does the rollback itself require approval from the same classifier, is "revert" a class the system recognizes, and if an emergency path bypasses approval, what stops that path from becoming a side channel in violation of the stated constraint?
- How observable will the classification rules be to deployment authors, and does the security team accept a control whose bypass surface can be enumerated by reading the inspectable policy — given that auditability and gameability are the same property?
- Which classifier inputs are author-supplied versus independently generated, and does the inspectability condition require provenance of the evidence inputs, or only that their recorded values are replayed?
- If no historical deployment-to-outcome data exists, by what means and over what period will the classifier be validated as no worse than the baseline before it gates production, and what does the shadow period cost the velocity outcome it exists to serve?
- Who owns the policy after launch, out of which fixed capacity pool, and is the policy's own version and change history part of the audit record — who approves changes to the policy that decides approvals?
- Who decides the maximum acceptable false-negative rate of the new control, and against what incident data, given the baseline control's rate will presumably still be unknown at that point?
- What does the security team mean by "inspectable after the fact" — replayable by whom, over every decision or sampled exceptions — and has anyone secured their capacity to actually inspect, given audit records are non-negotiable and inspection is the stated precondition?
- Is the deployment-model redesign the seed half-proposes ("Maybe approval is a symptom...") in scope for this framing at all, or is it a second project with its own risk surface and its own pipeline-authority dependencies?

**Answer:**

1. No systematic record exists. Approvals are logged (who, when), but denials, reworks, and incident attribution are not queryable. The baseline detection rate is currently unmeasurable without new instrumentation — a gap I hadn't seen.
2. The platform/pipeline team owns the pipeline; this team builds on it. Changing the approval mechanism goes through their change process. And by our own logic the rollout of a new gate is itself a high-risk change — it gets human approval under the current rules before it replaces them. I hadn't thought about our own rollout; you're right.
3. Reverts go through the same pipeline and the same gate. Emergency revert today is ad hoc — no defined override path. Under automation the override path must be explicit and audited or it becomes the side channel. Needs designing.
4. I'd keep the policy readable by deployers — transparency is part of trust — but gameability is real and I don't have a position beyond "rules must be inspectable; whether authors get pre-deploy feedback is open". This is a security-team question, not mine alone.
5. Diff, test results, and service identity are author-supplied; pipeline stage/environment metadata and (if built) a blast-radius graph are independently generated. The audit record should capture input values and their source. Mixing in independent signals is a design constraint.
6. We don't have historical deployment-to-outcome data. So: a shadow period — classify alongside the human gate, compare, cut over only when false-negative performance on the rare class is demonstrated. It delays the velocity gain; I accept that. Safety first.
7. The policy needs a named owner, not silent absorption into the reviewer pool. Policy version must be pinned in every audit record, and policy changes get their own approval. I'd propose security co-owns policy changes. Unassigned today.
8. Security decides, with the measured baseline as input — not me alone and not without measurement.
9. I don't know what they mean precisely — that's part of the first conversation. I have not secured their capacity to inspect; I should book that before proposing anything.
10. In scope as a reading to be evaluated, not a committed direction. If it wins it becomes its own workstream with the pipeline team. For this stage: on the table, not designed.


## From: ambiguity-and-decisions

- Is the framing's deliverable a single selected reading, or a decision document presenting the readings to the sponsor — and if the former, does the sponsor accept that selection cannot precede the security conversation (D2)?
- Is the seed's open question about CI signal adequacy being asked for a machine classifier, a human deciding quickly, or both — and has the consumer choice actually been made, or is the question smuggling Reading 1 in as neutral?
- Does "no side channel" mean a single gate applied uniformly to all changes, or a single pipeline whose internal gates may differ by class of change — and who has authority to interpret the constraint for this project?
- Does the security team accept retrospective inspectability as a substitute for a human accountable at decision time, and if so, with what conditions — because their answer kills or licenses two of the three floating ideas as stated?
- For a policy-only (idea 2) deployment, is the policy evaluation itself the "deployment decision" the audit record must capture, or must a human decision exist somewhere in the chain — and who decides what the auditable unit is?
- Is human accountability a guarantee the seed intends to preserve, given the org context requires auditable decisions but not accountable humans — and who, under each feasible reading, is the accountable party for an auto-approved change?
- Under Reading 3, which party holds the authority to amend the pipeline constraints the reading collides with, and is that party in the room — because "no side channel" and "all deployments go through the shared pipeline" are the only constraints that decide the reading's fate?
- Does the sponsor commit to measuring the baseline gate's actual detection/blocking performance before any replacement claims the guarantees "survived," or will parity be asserted on argument alone — and does security hold a veto over that choice?
- Does the seed's stated want — "fewer humans spent rubber-stamping" — accept a solution that reduces attention waste without reducing approver-hours much, i.e., is Reading 4's ceiling of hours-saved acceptable, or do the hours themselves have to come down for the outcome to count?

**Answer:**

1. A decision document presenting the readings and what each commits us to. Selection waits on the security conversation — D1 is deferred until D2 is answered.
2. I had implicitly assumed the machine consumer. The consumer choice is NOT made. The framing should carry the seed's open question with both consumers explicit — the bar is far lower for a human deciding quickly.
3. I read it as: everything transits the one pipeline and every decision is audited. Whether the internal gate may differ by change class is not mine to interpret — the platform/pipeline team owns that. Open.
4. Unanswered — I have not asked. Their answer licenses or kills ideas 1 and 2 as stated. First conversation.
5. My instinct: the policy evaluation must count as the decision, with a recorded accountable owner (policy owner plus deployer) — otherwise idea 2 manufactures unauditable non-decisions. But the definition of "deployment decision" is security's terminology to own.
6. Yes — I intend a named accountable party for every deployment, including automated ones. The org context requires only auditable decisions; accountability-to-nobody is a regression I'm not willing to accept, so it's a guarantee I want kept.
7. The platform/pipeline team — and no, they're not in the room yet. A stakeholder to add before Reading 3 can be evaluated honestly.
8. Yes, I commit to measuring the baseline before any replacement claims the guarantees survived. Parity on argument alone isn't acceptable. Security holding a veto over that choice: I'd give them one — they own priority 1.
9. Yes. "Fewer humans spent rubber-stamping" was about wasted attention, not a quota of hours. Same hours with better attention is a win. Hours are a proxy, not the goal.

