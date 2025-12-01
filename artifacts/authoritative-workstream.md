---
state: authoritative
generation: 5
supersedes: proposed-design-v2
derived_from:
  - proposed-design-v2
  - review-working
confidence: 0.7
---

# Authoritative Workstream: Approval Attention Engineering

## Goal

Deployments must pass a human approval gate, but reviewer capacity is fixed while deployment volume is not. Under uniform review, every change receives the same undifferentiated look, which manufactures rubber-stamping: attention is spread evenly regardless of where judgment is actually needed, and no record captures whether a given change was reviewed at the right depth. The originating complaint is deployer delay, but the organization's chosen success metric is attention quality — whether the fixed reviewer pool's scrutiny lands where it matters — with hours saved treated as a proxy, not the goal.

The desired outcome is an overlay that re-engineers how the fixed pool's attention is classified, prepared, routed, batched, and measured, while leaving the approval decision a human act on the unchanged gate for every deployment. Success means: (1) attention becomes an auditable, instrumented signal rather than an unmeasured assumption; (2) routine-shaped changes are batch-screened at right-sized depth so deep judgment is freed for changes that need it; (3) all three named guarantees — a human looked at every change, a named sign-off exists per change, the approver is accountable — survive unmodified in per-change form; and (4) the design degrades to exactly the status quo under any component failure. The differentiating value over doing nothing rests on assumption A5 (attention quality serves screening quality), which is weakly and directionally supported by a synthetic mock and remains unvalidated against real data; this workstream therefore treats the real-data validation of A5 as a delivery gate, not an assumption.

## Approach

The chosen direction is **approval-preserving attention engineering**. No deployment decision is automated by mechanism or by creep: no classifier output authorizes a deployment, no qualification bypasses the gate, no windowed default converts silence into consent, no batch signature covers items. One deployment, one human decision, one named sign-off, one record. Classification is advice about attention — "routine-shaped, confirm in minutes" or "judgment territory, here is where" — never a claim about safety. The decision unit is always the deployment; batching is a presentation and scheduling mechanism, never a decision mechanism. The brief presents what a change is, what is verified and by whom, and what is unverified; it never proposes approve or deny.

What it does not do: it does not automate any approval, does not create class-differentiated gates (only differentiated queues in front of one gate), does not add an override or bypass surface, does not remove the human from the routine path, and does not promise reduced hours. It may add modest mean wait for the routine class under the batch-cadence floor; this is measured and bounded by a stop condition (see Operating bounds F11 and Success metrics), not assumed away.

The commitments that define the direction: (1) the gate executes byte-for-byte as today — the design is an overlay in front of it, with no actuators; (2) degradation is the steady state, not a fallback — overlay down means untiered queue, raw screen, same gate; (3) every review leaves a replayable record of what the human was shown, at what allotted depth, and what they did with it; (4) the design's central and only safety-relevant risk — mis-tiering a consequential change into shallow T1 review — is named, bounded by conservative conjunction, and its expansion gated by a pre-committed, security-co-owned threshold; and (5) automation is a specified, gated branch that grows from the data this design produces, not adopted now.

Two commitments are elevated from the design's parallel activities to hard preconditions in response to review. First, the real-data replication of experiment E1 (does prepared, differentiated attention improve screening quality) is a **precondition for any queue change**: no routing or batching ships until the P0/P1 replication returns its success signal. Second, no phase that consumes reviewer calendar ships until reviewer-pool slack is confirmed sufficient to reserve batch blocks and staff the queue-operations role without reducing review throughput.

## System primitives

**Evidence object.** `{id, kind, value, source-class, origin, capture-time, integrity, derived-from[]}` with `source-class ∈ {author-supplied, pipeline-derived, pipeline-observed}`, bound by hash to the deployment artifact. Provenance is load-bearing because the brief is what a human reads: a laundered author claim risks misdirecting attention, so author-supplied evidence cannot satisfy a safety-relevant predicate and forces a higher tier where the unverified assertion is displayed for the scrutiny it should attract.

**Attention tier.** A deterministic, conjunctive classification assigning every change to exactly one tier. **T1 (batch-screened)**: every predicate affirms on independently generated or pipeline-observed evidence — `artifact-integrity`, `composition-bounded` (mechanically derived, declared type never an input), `blast-radius-bounded`, `failure-detectable`, `tests-affirmative`, `no-special-infra` (no feature flags, traffic routing, security settings, credentials, migrations, infra code), `history-clean`. **T3 (deep review)**: special infrastructure, wide blast radius, open incident, or the never-T1 set. **T2 (individual judgment)**: the default. Untiered is defined as not-T1, so degradation conserves attention. T1 starts at the mechanically provable core and expands only on measured escalation quiet.

**Attention policy.** The versioned, content-addressed, named-owner document holding tiering rules, the depth rubric (tier-by-tier contract for review depth), and the routing matrix. It is deliberately not an approval policy: it governs allocation of a fixed human resource, not admission to production. Changes are separately approved and publish their predicted routing-distribution impact before release. Security co-ownership is a standing veto over policy diffs.

**Review brief.** The pre-digested reviewer screen, generated deterministically from the frozen snapshot: per-rule outcomes with source-class on every input, structured diff summary, blast-radius summary, monitoring-coverage summary, test summary, tier and its trace, the depth rubric for the class, and the history of similar changes in the service/class. It is content-addressed and versioned; disposition records store its fingerprint and generator version so "what was the reviewer shown" is replayable. The same brief is shown to the deployer at enqueue.

**Batch abstract.** Metadata for a T1 session: grouping key, commonality summary (what is identical, read once), and outlier marks (items differing in any safety-relevant dimension, flagged for full opening). It records per-item sign-off status so a batch cannot close with an unsigned item. It is a presentation vehicle, never a decision unit.

**Disposition record.** The superset of today's approval log: `{decision-id, disposition ∈ {approved, denied, reworked, escalated}, approver, timestamp, tier-at-presentation, brief-fingerprint, escalation?, annotations[]}`. Annotations anchor a denial to specific brief rules, making review reasoning queryable for the first time.

**Escalation record.** A reviewer-initiated re-tier with a structured reason — the design's divergence signal, a human disagreeing with where attention was routed. Escalation patterns and their confirmation rates drive attention-policy revision and gate T1 expansion; they also passively measure whether reviewer judgment reduces to rules (the encodability signal).

**Review-context record.** `{deployment-id, brief-version, tier, tier-agreement ∈ {none, concur, disputed}, reviewer-time, disposition, reason, sign-off-name, timestamp}`, appended to the existing approval record with the existing sign-off. It makes attention auditable per deployment.

**Attention ledger.** The standing measurement of attention quality: time-to-review by tier, queue depth and staleness, batch cadence planned vs. achieved, per-item sign-off times, rework and denial rates by class, escalation rates and confirmation by rule, incident attribution by tier, flagged-but-enqueued rate, and batch-session utilization (the adoption watch). Because attention quality has no naive operationalization, its proxies are named as proxies: anchored-denial share, escalation confirmations, time-per-item vs. rubric, incident attribution by tier.

## Implementation phases

### P0 — Baseline instrumentation

**Entry condition:** this team plus a single field on the existing approval screen from the platform team; no other precondition.
**What ships:** disposition capture with anchored reasons, the review-context hook, and incident-attribution linkage — the D5 baseline every direction inherits. In parallel, reviewer interviews begin (advancing Q10).
**Who owns it:** this team (records, measurement); platform team (the field).
**What it measures:** the pre-overlay baseline — denial/rework rates by class, review times, incident attribution — against which every later phase is compared, and the P0-side data feeding the E1 real-data replication.

### P1 — Recorded tiers and briefs

**Entry condition:** P0 shipping and accumulating records; the brief generator's determinism/replay discipline in place from the first commit, including the content-addressing constraint below.
**What ships:** the deterministic generator runs; reviewers see tier, trace, and brief alongside the unchanged screen; routing and batching are not live. Escalations and dispositions accumulate. This is a tuning loop, not a shadow period — no cutover, no parity oracle. **Named constraint (technical feasibility finding):** the history-of-similar-changes content in the brief is derived from a *pinned, content-addressed snapshot* of the disposition store, and that snapshot digest is an explicit input to the generator function `(snapshot, attention-policy-version, disposition-corpus-digest, generator-digest) → {tier, trace, brief, batch-abstract}`. The generator performs no evaluation-time read of the mutable store; determinism and replay hold because every input, including corpus state, is fixed and addressed.
**Who owns it:** this team.
**What it measures:** tiering distribution, escalation rate and confirmation, and the **E1 real-data replication** — whether brief-assisted review detects denials/rework at least as well as undifferentiated review as review time falls.

### P2 — Routing and batching presentation

**Entry condition (hard preconditions):** (a) the E1 real-data replication (P1) has returned its success signal — per-class denial detection holds or improves as routine review time falls; (b) reviewer-pool slack is confirmed sufficient to reserve batch blocks and staff the queue-operations role without reducing review throughput; (c) the named attention-policy owner and queue-operations lead are assigned; (d) SLA dashboards are live before any review-slot commitment is made; (e) the F1 expansion threshold is pre-committed and security-co-owned (see Security posture).
**What ships:** batch sessions for T1, domain-default routing for T2/T3, enqueue screening for deployers — all feature-flagged, per domain, measured against the P0 baseline. Per-feature revert is one deploy.
**Who owns it:** platform team (queue-presentation rework); queue-operations lead (cadence, SLAs, routing defaults); attention-policy owner (tiering rules, rubric, matrix).
**What it measures:** the per-domain graduation gate — escalation-rate asymmetry below the pre-committed threshold over minimum volume per class — plus batch-session utilization (adoption), routine-class p95 wait vs. baseline, and per-item time and disposition quality (E4/E5).

### P3 — Steady state

**Entry condition:** P2 graduated on at least one domain with adoption, attention-quality, and customer-value gates all held.
**What ships:** the attention-policy revision cadence, brief-feedback review loop, standing tiering retro, and measurement audits.
**Who owns it:** queue-operations lead (retro, cadence); attention-policy owner (revisions); this team (measurement audits); security (reader, standing veto).
**What it measures:** whether T1 expands or contracts on escalation evidence, label informativeness over time (E6), and the standing ledger metrics that keep the automation branch's feedstock and the F5 telemetry honest.

## Success metrics

- **Anchored-denial share.** Collected from disposition records (denials citing specific brief rules vs. free text). Success: sustained at or above the P0 baseline as review time falls — informative review is not being traded away for speed.
- **Escalation confirmation rate.** Collected from escalation records cross-referenced to subsequent dispositions. Success: escalated items produce denials/rework at elevated rates (deeper scrutiny finds what the batch would have missed) *and* the base escalation rate on T1 stays below the pre-committed threshold — the standing gate on T1 expansion.
- **Time-per-item vs. rubric.** Collected from review-context records against the depth rubric's expected investment per class. Success: routine-class time falls materially while T3 time is unhurried, matching intended depth allocation.
- **Incident attribution by tier.** Collected by resolving incidents through the disposition chain (deployment → reviewer → brief version → tier → reasons). Success: the batch-screened T1 class is *not* overrepresented in incidents; overrepresentation triggers mandatory T1 contraction.
- **T1 volume share.** Collected from tiering records. Success: T1 captures a material share (target ~30%+) of volume with escalation-confirmed consequential mis-tiering below the threshold — enough routine bulk to make batching worthwhile without over-inclusion.
- **Batch-session utilization (adoption).** Collected from batch-abstract records and calendar data — do reviewers actually attend reserved sessions and dispose items in them rather than grabbing ad hoc. Success: utilization above a queue-ops-set floor per domain; **sustained utilization below that floor over the defined window is the halt/revert condition for the adoption failure mode** (F10).
- **Routine-class queue delay.** Collected from attention-ledger queue-age by tier vs. P0 baseline. Success: routine-class p95 wait within a small tolerance of baseline or better. **Sustained material degradation with no measured attention-quality gain over the defined window is the customer-value stop condition** (F11) — the workstream halts on that domain rather than only revising cadence.
- **Flagged-but-enqueued rate.** Collected from enqueue-screening and disposition records. Success: bounded above zero (screening informs without becoming a gate) while rework on enqueued items falls; a collapse toward zero is a social-gate alarm (F7).
- **Label informativeness.** Collected from monthly independent sampling of denial/rework records scored informative/uninformative. Success: informed share sustained at or above ~80% — the on-ramp feedstock and F8 boilerplate-rot watch.

## Operating bounds

**F1. Mis-tiering into shallow T1.** The one error with safety character — a consequential change batch-screened shallow. Bounds in design: T1 admission is a conjunction never a score; batch construction marks outliers and the session norm requires opening them; conservative start, expansion only on measured escalation quiet; incident attribution by tier. **Addition (implementation-risk finding):** the escalation-rate threshold that governs both P2 go-live and T1 expansion is **pre-committed to a conservative starting value before P2** and is **co-owned by security, not set unilaterally by the queue-operations lead**; any loosening requires a policy diff subject to security's standing veto and publishes its predicted routing-distribution impact.

**F2. Batch blur.** Homogeneous items breed complacency. Bounds: bounded sessions, homogeneity grouping built to surface the odd item, per-item sign-off as a structural UI fact. Residual: a reviewer who confirms without looking is undetectable by machinery — bounded, not eliminated.

**F3. Queue starvation and cherry-picking.** Bounds: staleness bins with escalation thresholds, domain routing giving every change a default owner, oldest-first defaults. All defaults, none enforceable; the residual is social and named.

**F4. Routing hardens into a shadow gate.** Bounds: the invariant *routing is default-presentation, never filtering* is written into the attention policy and checked in platform UI review — any item that no reviewer can see and claim is a gate and needs the gate's governance.

**F5. Attention-policy erosion.** Lighter governance is exposed to quiet drift. Bounds: heavy telemetry — every policy change publishes predicted routing impact before release and is checked against measured escalation/disposition shifts after; an expansion producing an escalation spike is reverted by policy revision.

**F6. Brief rot.** Bounds: deterministic generation with replay-regression gating generator releases, provenance display on every input, and a reviewer brief-feedback channel feeding the revision loop.

**F7. Enqueue flag becomes a de facto gate.** Bounds: the flagged-but-enqueued rate and denial rate among enqueued items are ledger metrics; collapse toward zero is an alarm treated as a communication/ownership intervention.

**F8. SLA theater.** Bounds: SLAs set from measured cadence never before it; the dashboard ships before the commitment; a missed SLA is a ledger incident.

**F9. The measurement loop lies.** Bounds: the escalation-rate threshold gating T1 expansion inherits an audit obligation; nothing downstream is a cutover, but the gate's inputs are audited.

**F10. Adoption failure — reviewers do not batch.** The design's only true dependency, and social. Bounds in design: calendar-reserved sessions, visible outcomes, an adoption-oriented success metric. **Addition (robustness finding):** batch-session utilization is a first-class ledger metric with a **defined floor and window; sustained utilization below the floor is the explicit halt/revert condition** — the workstream stops rolling out to a domain rather than discovering the inert-variant collapse only after full P2.

**F11. Net-negative customer value on routine wait.** The design may add modest mean wait for the routine class. **Addition (customer-value finding):** routine-class p95 wait is measured against baseline with a **defined stop condition** — sustained material degradation with no attention-quality gain over the window halts the workstream on that domain (not merely "revise cadence"), tying the accepted latency trade-off to a real gate.

**F12. Capacity draw on a fixed pool.** The queue-ops role and batch calendar draw from senior reviewer time that cannot grow. **Addition (operational-impact finding):** confirmed reviewer-pool slack sufficient to staff coordination and reserve batch blocks without reducing review throughput is a **named P2 precondition**; if slack is insufficient the batch-cadence floor cannot be held and P2 does not ship.

## Security posture

**Security model.** There is no automated approval anywhere in the delivery path; the org constraint "any automated approval must be inspectable after the fact" is inert because nothing to inspect is created. The gate executes as today. The security-relevant surface is *allocation, not decision*: tiering rules route scrutiny depth, and depth is a screening-quality input.

**Threat surface.** (1) A mis-tier routing a consequential change to shallow T1 review (F1) — the sole error with safety character, which still cannot release a change because a human decides on the unchanged gate. (2) Brief gameability — fought at evidence provenance: author-supplied claims cannot satisfy tiering predicates, tier and brief derive mechanically, and the deployer sees the same brief at enqueue, so optimizing toward the presentation optimizes toward the scrutiny; the payoff for gaming is a shorter line, not a bypassed human. (3) The never-T1 set structurally excludes tiering code, policy corpus, pipeline control, and security-critical configuration from shallow screening. (4) The tiering service has no actuator; its compromise is a presentation-layer compromise recoverable by feature flag.

**Explicit gate added (implementation-risk significant finding).** The escalation-rate threshold governing P2 go-live and T1 expansion — the guard on F1, the one safety-character failure — is not a movable number chosen by the interested party. It is **pre-committed to a conservative value before P2, co-owned by security, and any change is a policy diff subject to security's standing veto**. Security is additionally a standing reader of disposition records, escalation rates, brief-audit reports, incident attribution by tier, and the flagged-but-enqueued watch; incident attribution by tier lets security demand a T1 contraction if the batch-screened class is overrepresented. Security consumes no critical-path time to ship any phase.

**Adopted hygiene.** Predicates read derived structure only; raw diffs retained under access control. Disposition and review-context stores are append-only, write-restricted to the disposition hook. The rollout paradox is near-trivial: the overlay alters no future deployment's fate, so its own deployment is a normal-risk change through the unchanged gate.

## Dependencies

**P0 (smallest, critical path to everything).** Platform team: one disposition-capture field and a review-context hook on the existing approval screen. This team: record stores, incident-attribution linkage, measurement loop. This is the D5 baseline shared by all directions. **Critical-path:** the P0 records are the feedstock for the E1 real-data replication that gates P2.

**P1.** This team alone plus the P0 field. No new roles. Requires the brief generator's determinism discipline (including disposition-corpus content-addressing) from the first commit. **Critical-path:** the E1 real-data replication runs here and is a hard precondition for P2.

**P2 (largest).** Platform team: queue-presentation rework (batch construction, routing defaults, staleness surfaces, enqueue screening) — a view change on the unchanged gate; Q11 (platform change process) applies. **New roles, drawn from existing reviewer seniority:** attention-policy owner and queue-operations lead. **External conversation:** security must ratify the pre-committed F1 threshold and accept the standing veto (a reader/veto role, not a licensor — off the critical path for shipping). **Named precondition:** confirmed reviewer-pool slack (F12). **Critical-path:** all P2 entry conditions (E1 success, slack confirmed, roles assigned, dashboards live, threshold ratified) must hold before any queue change ships. Degradation floor: if the platform team refuses UI integration, the design degrades to a sidecar mode (briefs in an adjacent tool) — worse, but operational, gate untouched.

**P3.** Standing ownership: queue-operations lead (retro, cadence), attention-policy owner (revisions), this team (audits), security (reader/veto). No new external conversations.

**Not on the delivery path (carried as automation-branch gates only):** Q1 (security license for automation), Q4 strong form, Q5, Q6, Q7 (emergency revert), Q10 completeness. None gate this workstream.

## Review findings and dispositions

| dimension | severity | disposition |
|---|---|---|
| robustness | significant | addressed — §Operating bounds (F10) and §Success metrics: batch-session utilization is now a first-class metric with a defined floor and window, and sustained sub-floor utilization is an explicit halt/revert condition rather than a post-P2 surprise. |
| simplicity | trivial | noted-and-dismissed — the agent confirms complexity is stacked smallest-to-largest with each phase valuable alone, degradation is the status quo, and the machinery sits in front of an untouched gate; the added primitives do not change delivery outcomes. |
| strategic alignment | significant | addressed — §Approach and §Implementation phases (P2 entry condition): the real-data replication of E1 is elevated from a parallel activity to a hard precondition — no routing or batching ships until it returns its success signal. |
| technical feasibility | significant | addressed — §System primitives (review brief) and §Implementation phases (P1): the disposition-corpus state is content-addressed as an explicit generator input (`disposition-corpus-digest`), resolving the determinism/replay contradiction — no evaluation-time store read occurs. |
| security | trivial | noted-and-dismissed — the agent confirms the automation constraint is genuinely inert (no automated approval), the never-T1 set and absent actuator bound the surface, and no overlay failure can authorize a deployment; the residual does not change delivery outcomes. |
| customer value | significant | addressed — §Operating bounds (F11) and §Success metrics: routine-class p95 wait carries a defined stop condition — sustained degradation with no attention-quality gain over the window halts the workstream on that domain, not merely "revise cadence." |
| operational impact | significant | addressed — §Operating bounds (F12) and §Dependencies (P2): confirmed reviewer-pool slack sufficient to staff the queue-ops role and reserve batch blocks without reducing throughput is now a named P2 precondition, making the previously unstated capacity assumption explicit and gating. |
| implementation risk | significant | addressed — §Security posture and §Operating bounds (F1): the escalation-rate threshold guarding F1 is pre-committed to a conservative value before P2 and co-owned by security under a standing veto, so the guard on the sole safety-character failure is no longer a movable number set by the interested party. |
