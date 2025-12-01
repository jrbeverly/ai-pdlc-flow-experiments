---
state: working
derived_from:
  - proposed-design-v2
---

# Review working artifact

Working material for the promotion stage. Three review agents score Proposed
Design v2 across the eight dimensions from VISION.md: robustness, simplicity,
strategic alignment, technical feasibility, security, customer value,
operational impact, and implementation risk. Dispositions are appended by the
compaction step after remediation.

Each finding uses this format:

    ### Finding: <dimension>
    **Severity:** significant | trivial
    **Description:** ...


## Agent review — structural-review

### Finding: robustness

**Severity:** significant
**Description:** The design concedes a single unmitigated dependency: F10 states adoption is "the design's only true dependency and it is social: the reallocation of attention does not happen in software," and that if reviewers decline to batch "the design collapses to exactly the advisory-only variant the framing dismissed as inert." Yet no gate anywhere measures or enforces adoption — the P2 graduation gate is "escalation-rate asymmetry below a queue-ops-set threshold," which the design explicitly calls "an attention-quality gate, not a safety gate" and which says nothing about whether reviewers actually use the sessions. As a delivery artifact this leaves the load-bearing failure mode without a defined threshold at which the workstream stops, reverts, or is abandoned, so the one way the design can fail to its inert variant would surface only after full P2 rollout.

### Finding: simplicity

**Severity:** trivial
**Description:** The design carries real added surface — eight new record/primitive types, two new roles (queue-operations lead, attention-policy owner), and a tier taxonomy — but it handles the concern for delivery: complexity is stacked "smallest-to-largest, each phase valuable alone," degradation "is the status quo rather than a designed fallback" ("overlay down → untiered queue, raw screen, same gate"), and the added machinery sits in front of an untouched gate rather than inside the decision path. The added primitives do not change delivery outcomes because each phase ships independently and the failure surface returns to the substrate it decorates.

### Finding: strategic alignment

**Severity:** significant
**Description:** The design's differentiating value over doing nothing rests entirely on assumption A5, which it admits is only "weakly, directionally supported by a mock run whose data is synthetic, involved no real reviewers or LLM," and it concedes "If A5 is false, the design retains 'no worse than unchanged' ... but forfeits the safety upside." This matters for delivery because the artifact is being promoted at confidence 0.67 while its entire strategic case — attention quality serving screening quality — is unvalidated against real data, and separately the design accepts it "may add modest mean wait for the routine class," conceding it "is the one axis where it may be net-negative against the seed's original complaint of deployer delay." A delivery artifact whose upside is unproven and whose downside touches the originating complaint should make the real-data replication of E1 an explicit precondition of any queue change, not a parallel activity.

## Agent review — technical-review

### Finding: technical feasibility

**Severity:** significant
**Description:** The brief generator is specified as a deterministic function `(snapshot, attention-policy-version, generator-digest) → {tier, trace, brief, batch-abstract}` with "no wall clock, no evaluation-time I/O," and replayability is called "non-negotiable from the first commit, because a non-replayable brief is an unauditable input to the sole control." But the review brief is also required to contain "the history of similar changes in this service/class (recent dispositions, common denial reasons, rework rate)" — data that lives in the mutable, append-only disposition store and is not among the function's stated inputs. As written, two identical snapshots generated at different times would either yield different briefs (breaking determinism) or require reading the store at generation time (the "evaluation-time I/O" the design forbids); the design never states that the disposition-store state is content-addressed into the input, so the load-bearing replay/audit property has an unresolved contradiction at the exact point it claims to be strongest.

### Finding: security

**Severity:** trivial
**Description:** The design already handles the security concern for delivery: the org constraint "Any automated approval must be inspectable after the fact by the security team" is genuinely inert because "there is no automated approval," the never-T1 set structurally excludes "tiering code, policy corpus, pipeline control, security-critical configuration" from shallow screening, and "the tiering service has no actuator: its compromise is a presentation-layer compromise, recoverable by feature flag." The one admitted safety-relevant error, mis-tiering into shallow T1 review (F1), cannot release a change — "a human decided; the gate held" — and is bounded by conservative conjunction plus "incident attribution by tier," which lets security "demand a T1 contraction." Because no failure in this overlay can authorize a deployment, the residual does not change delivery outcomes.

### Finding: customer value

**Severity:** significant
**Description:** The originating customer complaint was deployer delay, yet the design concedes it "may not reduce hours much, and it may add modest mean wait for the routine class," and names this "the one axis where it may be net-negative against the seed's original complaint of deployer delay," resting the compensating case on the reframed metric of attention quality where "hours saved [is] a proxy, not the goal." The problem for delivery readiness is that E5's own failure signal — "material degradation with no attention-quality gain" — resolves only to "batching cadence or class scoping must be revised," never to a defined point at which sustained negative customer value halts or abandons the workstream. Promoting an artifact that admits possible net-negative value on the customer's own stated problem, with the compensating value unproven (E3/E4/E5 still open) and no stop condition tied to it, leaves the customer-value case an ambiguous, unbounded gate.

## Agent review — delivery-review

### Finding: operational impact

**Severity:** significant
**Description:** The design bills itself as "the cheapest of the three proposals to operate" with "near-zero added tax: the review is the measurement," yet it simultaneously commits the fixed pool to "scheduled sessions consuming reviewer calendar in deliberate blocks" and to a new "queue-operations lead" plus "attention-policy owner," both "drawn from existing reviewer seniority." Against the organizational constraint that "reviewer capacity is fixed and does not scale with deployment volume," this is a net draw on a resource that cannot grow: the queue-ops role "formalizes queue coordination that today happens implicitly (or not at all)," and where it is "not at all" that coordination is new labor pulled from senior reviewers who would otherwise be reviewing. The design names these costs and their owners but never states the operational prerequisite that the pool has slack to reserve batch-calendar blocks and staff a coordination role without reducing review throughput — and if it does not, the batch-cadence floor that sets the T1 "expected within N hours" commitment cannot be held, so the unstated capacity assumption is load-bearing for the design's own SLA honesty (F8, E5).

### Finding: implementation risk

**Severity:** significant
**Description:** The one error the design concedes has "a safety character" — mis-tiering a consequential change into shallow T1 review (F1) — is bounded by expansion policy: "T1 starts conservative... and expands only on measured escalation quiet," with escalation "confirmation rate is the standing T1-expansion gate," and the P2 rollout gated by "escalation-rate asymmetry below a queue-ops-set threshold over minimum volume per class — an attention-quality gate, not a safety gate." The threshold that governs both when batching goes live and when shallow screening widens is therefore set by the queue-operations lead, a role that does not exist until P2 and whose mandate is to make batching succeed, with no pre-committed value and no independent or security owner. For a delivery artifact this is an ambiguous gate at exactly the point where the design's only safety-relevant failure mode lives: the guard on F1 is a movable number chosen by the interested party, and the design's insistence that it is "not a safety gate" does not remove the fact that it controls exposure to the one consequence with safety character.

## Dispositions (post-compaction)

Extracted from §Review findings and dispositions in the Authoritative Workstream:


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
