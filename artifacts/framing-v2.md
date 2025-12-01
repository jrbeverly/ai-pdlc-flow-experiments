---
state: authoritative
generation: 2
supersedes: framing-working
derived_from:
  - raw-thought
  - framing-working
  - framing-questions
confidence: 0.7
---

# Framing v2

## Problem statement

Every deployment waits on the same manual approval regardless of what it touches. Most deployments are routine, so the gate consumes fixed reviewer capacity on clicks and produces rubber-stamping: approvers clicking through changes they cannot meaningfully screen, and deployers waiting on changes nothing in particular is screening. As scoped with the sponsor, the problem this framing addresses is **routine-approval volume and the reviewer attention waste it produces**, manifesting as avoidable delay for routine changes.

In scope: routine-change throughput for deployers; wasted reviewer attention. Out of scope: high-risk-change latency — that is a different problem, not being solved here; the high-risk path may get *slower* as reviewers stop rubber-stamping, and the sponsor accepts that.

Manual approval is the sole control between a CI-passing change and production. Whatever changes it, two properties must remain observable: a human has looked at every change, and there is a recorded sign-off with a name attached. The sponsor adds a third guarantee the org context does not require: a named accountable party for every deployment, automated ones included — accountability-to-nobody is a regression the sponsor will not accept.

The problem is not yet one problem: it has four defensible readings (efficiency, control-quality, deployment-model, information — see Alternatives considered), and no reading is selected. The framing's deliverable is a decision document that presents the readings and what each commits the organization to; selection is deferred until the security conversation happens (see Unresolved questions).

One scoping fact constrains everything: there is no systematic record of what today's gate actually blocks. Denials, reworks, and incident attribution are not queryable, so the baseline control's detection rate is currently unmeasurable. The sponsor has committed to measuring it before any replacement claims the guarantees survived.

## Desired outcome

- **Routine changes reach production faster**: less delay attributable to the approval queue for the changes that make up the bulk of deployment volume.
- **Reviewer attention is applied where it matters**: fixed reviewer capacity is spent on changes that need human judgment; wasted attention (rubber-stamping) declines. Success is **attention quality, not hours** — the same hours with better attention counts as a win; hours saved is a proxy, not the goal.
- **The guarantees survive in observable form**: (a) human visibility of every change; (b) a recorded named sign-off; (c) the added accountability guarantee — a named accountable party for every deployment, including automated ones.
- **Safety parity is demonstrated, not asserted**: any replacement cuts over only after it is shown no worse than the measured baseline on the rare dangerous class. The shadow period this requires delays the velocity gain; the sponsor accepts that trade (safety first).
- **The high-risk cohort is explicitly not an outcome**: its latency may degrade and that is accepted as the price of restoring meaningful review.

## Relevant context

- **Ownership boundaries**: the platform/pipeline team owns the shared pipeline and the approval logic inside it; this team builds atop it. Changing the approval mechanism goes through the platform team's change process. The platform team is not yet in the room.
- **The rollout paradox**: by this project's own criteria, the first deployment of a new approval mechanism is itself a high-risk change — it alters the fate of every future deployment. It must pass human approval under the current rules before it replaces them.
- **The revert path**: reverts transit the same pipeline and the same gate. Emergency revert today is ad hoc — there is no defined override path. Under automation an override must be explicit and audited, or it becomes the side channel the constraints forbid.
- **Records reality**: approvals are logged (who, when), but denials, reworks, and incident attribution are not queryable. Any baseline measurement requires new instrumentation first.
- **The unasked stakeholder**: the security team has not been asked anything yet. Their answer — whether retrospectively inspectable automated decisions are acceptable, and for which classes — licenses or kills the automation readings as stated. That conversation is the first step; the sponsor accepts that reading selection cannot precede it. The stakeholder's inspection capacity has also not been secured.
- **Input provenance**: diff, test results, and service identity are author-supplied; pipeline stage/environment metadata and (if built) a blast-radius graph are independently generated. The audit record must capture input values *and their source*.

## Core primitives

- **routine change** — a frequency statement about what gets approved; it says nothing about danger. Not a risk category.
- **low-risk change** — criteria remain unresolved, but the direction is set by the sponsor: built from **failure mode and blast radius** (what breaks, who is affected, how fast it is caught), not from change type. Under that test the seed's own examples split: service bumps and copy tweaks qualify low; config tweaks do **not** automatically qualify (feature flags, traffic routing, and security settings have wide blast radius). The seed's lumping of config tweaks as routine was wrong and is corrected here.
- **guarantee** — the observable properties that must survive the change: a human has looked at every change; a recorded sign-off with a name attached; plus the sponsor-added guarantee of a named accountable party per deployment. The sponsor can name only the first two today; asking the approvers may extend the list.
- **baseline gate** — today's manual approval, whose detection rate is currently unmeasurable and must be instrumented before any replacement can claim parity on the guarantees.
- **shadow period** — running the classifier alongside the human gate, comparing outcomes, and cutting over only after false-negative performance on the rare dangerous class is demonstrated. It delays the velocity gain; the sponsor accepts this.
- **audit record** — must support reconstruction of the decision: policy version, every evidence input with value and source, an evaluation trace, and a named accountable party. Reproducibility, not a log line.
- **readings** — the four candidate problem-identities the decision document presents: efficiency (automate the decision for low-risk changes), control-quality (differentiated review without automating any decision), deployment-model (restructure the pipeline so routine and dangerous changes do not share a gate), information (make the informed human decision fast). No reading is selected yet.
- **deployment decision** — under a policy-only design the sponsor's default is that the policy evaluation *counts* as the decision, with a recorded accountable owner (policy owner plus deployer); otherwise idea 2 manufactures unauditable non-decisions. The final definition is the security team's terminology to own.

## Priorities

The organizational priority order applied to this problem:

1. **Safety and security governs.** Security sets the acceptable false-negative rate (against the measured baseline, not a guess); the baseline must be measured before any survival claim; the shadow period is accepted even at velocity's expense; the rollout of the new mechanism itself passes human approval under current rules; the sponsor would give security a veto over the baseline-measurement commitment.
2. **Reliability and operability.** Evidence dependability is now load-bearing: metadata that once only decorated dashboards (blast radius, service identity) becomes an input to the sole control. Provenance of inputs and the revert-path design sit here.
3. **Developer velocity.** Routine-change throughput is the driver, and is explicitly subordinated — sequencing decisions that trade velocity for safety are already made (shadow period, baseline-first).
4. **Convenience.** What the seed actually complained about, reframed: wasted attention, not hours. Attention quality is also instrumental to priorities 1–2 (rubber-stamping degrades screening), which in effect ranks it above a raw hours-saved target. No sub-ordering among the lower priorities is unknown: the org order (velocity above convenience) applies; the only nuance introduced by the sponsor's answers is the dual nature of "attention quality," stated here.

## Constraints

- **Organizational**: every deployment decision remains auditable (non-negotiable); all deployments go through the shared pipeline, no side channel; reviewer capacity is fixed and does not scale with volume; any automated approval must be inspectable after the fact by security.
- **Sponsor's reading of "no side channel"**: everything transits the one pipeline and every decision is audited. Whether *internal* gates may differ by change class is not this team's call — the platform/pipeline team owns that interpretation (open).
- **Ownership**: the approval mechanism cannot be changed without the platform team's change process, under rules not yet clarified.
- **Data**: no historical deployment-to-outcome data exists; baseline measurement requires new instrumentation (making denials, reworks, and incident attribution queryable).
- **Audit content**: policy version pinned; every evidence input with value and source (provenance required, not just values); evaluation trace; named accountable party. Pre-deploy reproducibility semantics for deployers are open (see Unresolved questions).
- **Policy governance**: a named owner (not silent absorption into the reviewer pool); policy version pinned in every audit record; policy changes get their own approval; the sponsor proposes security co-owns policy changes (unassigned today).
- **Rollout**: the new approval mechanism is treated as a high-risk change and approved by humans under the current rules before it replaces them.
- **Revert**: reverts stay on the same pipeline and gate; any emergency override must be explicit, audited, and designed not to become a side channel (no such design exists today).

## Assumptions

- **Security acceptance of automated approval with a preserved audit trail** — the seed's second assumption, still unconfirmed; the framing is instructed to carry both answers live. It must not function as a design premise before the security conversation.
- **That the two named guarantees are the complete set** manual approval provides today. The sponsor can name only two and says more may exist pending asking the approvers.
- **That low-risk changes are identifiable from information the pipeline already has.** Unproven: the definitional direction (failure mode, blast radius) is set, but the criteria have no owner, several inputs are author-supplied, and no validation data exists to test the signal.
- **That the baseline gate's blocking behavior can be made measurable with new instrumentation.** Committed in intent; the mechanics are unbuilt.
- **That attention quality serves screening quality** — i.e., that rubber-stamping actually degrades the control. This underpins the redefined success metric and the sponsor's acceptance of a slower high-risk path; it is plausible and consistent with the answers, but not yet evidenced.

## Decisions made

1. **Outcome scope**: routine-approval volume (throughput for deployers) and attention waste (for reviewers). High-risk latency is excluded as a separate problem; it may get slower, accepted.
2. **Success metric**: attention quality, not hours. "Fewer humans spent rubber-stamping" means less wasted attention; same hours with better attention is a win; hours saved is a proxy.
3. **Guarantees to preserve**: (a) a human has looked at every change; (b) a recorded named sign-off; (c) additionally, a named accountable party for every deployment including automated ones — accountability-to-nobody rejected as a regression.
4. **Low-risk direction**: defined from failure mode and blast radius, not change type; the seed's config-tweak example is corrected (config tweaks are not automatically low-risk).
5. **Baseline first**: the current gate's detection/blocking performance must be measured before any replacement claims the guarantees survived. Parity on argument alone is not acceptable; security gets a veto over that choice. New instrumentation is required since denials/reworks/incident attribution are not queryable.
6. **Deployment path**: a shadow period is mandatory — classify alongside the human gate, cut over only on demonstrated false-negative performance on the rare class. The velocity delay is accepted; safety first.
7. **Rollout self-application**: the new gate deploys under the old rules first — human-approved as a high-risk change under the current process before it replaces that process.
8. **Audit bar**: reconstruction-grade records — policy version, every evidence input with value and source, evaluation trace, named accountable party.
9. **False-negative threshold**: security owns it; set against the measured baseline, not a guess; not set by the sponsor alone.
10. **Policy governance**: named owner required; policy version pinned per audit record; policy changes separately approved; security co-ownership of policy changes proposed (unassigned).
11. **Framing deliverable**: a decision document presenting the readings and what each commits the organization to; no reading selected. Reading selection (D1) is deferred until the security conversation (D2) is answered.
12. **Deployment-model redesign**: in scope as a reading to be evaluated, not a committed direction; if selected, it becomes its own workstream with the platform team. For this stage: on the table, not designed.
13. **Input provenance is a design constraint**: audit records capture input values and their sources; mixing independently generated signals (pipeline stage/environment metadata, blast-radius graph if built) is required.
14. **Default for policy-only decisions**: the policy evaluation counts as the deployment decision, with a recorded accountable owner (policy owner plus deployer) — the sponsor's position against idea 2 manufacturing unauditable non-decisions; subject to security's ownership of the term.
15. **Classification consumer is explicitly unmade**: the seed's open question is carried with both consumers — machine classifier and human deciding quickly — because the evidence bar differs materially between them. The earlier implicit machine-consumer assumption is withdrawn.
16. **Uniformity suspicion, not commitment**: the sponsor suspects uniform application of one approval rule is the root cause (tiering, routing, and batching could reclaim attention without touching the approval concept), but is not committing the framing to the deployment-model reading.

## Alternatives considered

- **Idea 1 — classify by risk, auto-approve low-risk** (efficiency reading). Live. Gated on the security answer and an owned low-risk definition; delivers throughput directly; carries sole-control replacement risk and the gameability of a learnable boundary.
- **Idea 2 — drop approval for qualifying deployments, enforce guarantees entirely in automated policy** (efficiency reading, policy variant). Live. Hardest audit problem (what is the decision when no human decides — sponsor's default: the policy evaluation itself). Its failure mode is silent by construction: policy gaps are not recorded errors. Requires complete enumeration of the guarantees, which is strictly harder than preserving them.
- **Idea 3 — keep approval as an explicit state; AI/policy recommendation** (control-quality reading). Live, but split: **advisory UI** (decision maker unchanged — the seed's complaint persists; absorbed by the information reading below) vs. **default-approve-with-a-window** (a de facto automation and must then meet the automation bar of ideas 1/2).
- **Reading 3 — deployment-model change.** Two sub-variants: a separate fast lane (collides head-on with "no side channel") vs. restructuring inside the pipeline (the auditable decision becomes classification or staged rollout; rewrites "approval" in org terminology). Feasibility depends on the platform team's interpretation of the constraints; they are not in the room.
- **Reading 4 — information problem: faster informed human decisions** via tiering, routing, batching, better pre-review evidence — without touching the approval concept. Compatible with every org constraint as written; the sponsor endorsed that these can reclaim attention without renegotiation. Ceiling: may not reduce hours much — acceptable under the redefined success metric.
- **Set aside**: hours-saved as the success metric; high-risk latency as part of this problem; committing to any reading before the security conversation; the seed's lumping of config tweaks as low-risk; asserting parity on argument alone without baseline measurement.

## Unresolved questions

1. **Security's position.** Does the security team accept retrospectively inspectable automated decisions — and for which change classes, under what conditions? What precisely does "inspectable after the fact" mean to them (replayable by whom; over every decision or sampled exceptions)? Has anyone secured their capacity to actually inspect? This answer licenses or kills ideas 1 and 2 as stated and must precede reading selection.
2. **Ownership of the "low-risk" definition.** The direction (failure mode, blast radius) is set but the criteria have no owner. Related: whether business/revenue impact is included at all — the priority order has no business axis, and the copy-tweak example shows operational triviality can be business-critical; resolved only by an explicit addition to the priority order or a documented deliberate exclusion, and no one is assigned to that call.
3. **Classification consumer.** Machine classifier, human deciding quickly, or both — the choice is explicitly unmade and must not be smuggled in as an assumption.
4. **"No side channel" interpretation for class-differentiated gates.** The platform/pipeline team owns this interpretation and is not yet in the room.
5. **The auditable unit under policy-only deployments.** The sponsor's default (policy evaluation counts as the decision, with recorded accountable owner) needs security's confirmation since the "deployment decision" terminology is theirs.
6. **The acceptable false-negative rate.** Security decides, against the measured baseline; both the measurement instrumentation and the measurement itself do not exist yet.
7. **Emergency revert override design.** Must be explicit, audited, and not a side channel; today the path is ad hoc and no design exists.
8. **Pre-deploy feedback to authors.** Whether deployers see classification results before deploying (transparency vs. gameability of a readable policy) — a security-team question, open.
9. **Policy ownership assignment post-launch.** A named owner is required and security co-ownership is proposed, but the assignment against the fixed reviewer capacity pool is unassigned.
10. **Completeness of the guarantees list.** The two named guarantees are what must survive in observable form, but whether they are the complete set is unverified — the approvers have not been asked.
11. **Platform team's gate on the whole direction.** Whether, and under what evidence, the platform team's change process will approve a change to the approval mechanism itself — not yet broached.

## Confidence

Confidence in this framing overall: **0.7**. The framing is now coherent on scope, success metric, guarantees, sequencing, and its own deliverable shape. The largest single source of uncertainty is the security team's unasked position: it gates the two automation readings, the definitional questions (deployment decision, inspectability, false-negative threshold), and the reading selection itself. The remaining material uncertainty is structural: two defining stakeholders — security and the platform/pipeline team — are not yet in the room, and the risk criteria they are needed to define have no owner.
