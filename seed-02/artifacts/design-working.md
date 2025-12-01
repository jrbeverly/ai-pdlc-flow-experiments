---
state: stale
superseded_by: proposed-design-v1
derived_from:
  - framing-v2
---

# Design working artifact

Working material for Proposed Design v1. Messy by design: the proposals
below develop different approaches into the solution space and are expected
to disagree with each other and with the framing. The compaction step
distills this into the authoritative proposed design; disagreement is
recorded here, not reconciled away.

## Input: Framing v2

---
state: authoritative
generation: 2
supersedes: framing-working
derived_from:
  - raw-thought
  - framing-working
  - framing-questions
confidence: 0.78
---

# Framing v2

## Problem statement

On-call is unsustainable: a shift can absorb forty-plus pages of which perhaps
six require action. The underlying defect is not raw volume but an **unmeasured
signal-to-noise ratio** — the organization has never linked an alert to what
happened next (engineer acted / condition auto-resolved / alert dismissed / no
response), so it cannot state its current noise ratio nor what it currently
misses. Because that linkage does not exist in queryable form, no noise-reduction
mechanism can be evaluated as better or worse than today. The problem is
therefore two-layered: (1) the epistemic gap — we cannot measure — and, once
measured, (2) the fatigue itself, which is a reliability hazard because an
overwhelmed engineer who stops trusting pages will dismiss a real one.

## Desired outcome

On-call engineers are paged for real incidents and not for noise, **without any
real production-affecting incident being silently dropped**. Success is defined
in this order:

1. Instrumentation exists that links each alert to its outcome, making the noise
   ratio and the current miss rate measurable.
2. Top-tier customer-facing services (payment processor and financial-settlement
   path) page on first occurrence with no suppression, confirmed independently of
   the baseline.
3. Any reduction mechanism adopted for lower-tier services is evaluable against
   the measured baseline and provably does not increase missed real incidents.

Engineer sustainability is the leading indicator (loss of trust in pages
destroys reliability directly); service reliability is the goal. Volume
reduction is a likely by-product, not the target, and is treated as a
reliability concern — not mere convenience — because fatigue erodes detection.

## Relevant context

- Last-week baseline: >40 alerts in one Friday-evening shift; ~6 actionable.
- The alerting platform retains raw alert timestamps only. There is **no record**
  of engineer action, dismissal, or auto-resolution, and **no audit trail** for
  anything a suppression or dedup rule would withhold.
- Ownership is fragmented: the platform team owns shared alerting infrastructure
  and the tiering/routing layer; individual service teams own their own
  thresholds; nobody holds the complete picture. No one owns the definition of
  "real incident vs noise."
- Service-criticality mapping exists only informally and partially documented; it
  is not authoritative and is not trustworthy for automated routing without a
  verification pass.
- Threshold changes run through each service team's change-review process with
  platform-team sign-off for shared infrastructure; iteration latency is ~2–5
  business days per threshold. This bounds any tuning-dependent approach.

## Core primitives

- **Alert** — a fired condition from the alerting platform (currently only a
  timestamped event with no outcome attached).
- **Alert outcome** — the missing linkage the plan depends on: acted /
  auto-resolved / dismissed / no-response-in-N-minutes.
- **Noise** — an alert requiring no engineer action; its exact classification is
  **undefined** and must be assigned an owner (mirrors the org's unresolved
  "low-risk change" definition).
- **Suppression / deduplication** — a machine deciding a human need not be
  interrupted; functionally an *automated approval* and therefore subject to the
  org's auditability and after-the-fact-inspectability constraints.
- **Severity tier** — critical/warning/info policy governing whether on-call is
  paged; a *policy replacing judgment*, inspectable but only as trustworthy as
  the criticality catalog beneath it.
- **Async/dashboard channel** — a change to the delivery model (push-interrupt →
  pull-monitor) that relocates rather than removes human watching duty.

## Priorities

Applying the org priority order to this problem:

1. **Safety and security** — never trade away detection of a real
   production-affecting incident. Top-tier/financial-path services page on first
   occurrence, no exceptions. Any automated page-withholding must be auditable
   and inspectable by the security team.
2. **Reliability and operability** — this covers *both* signal quality (each page
   trustworthy and actionable) *and* alert fatigue itself, since fatigue degrades
   detection. The prior working material's split (signal = reliability, volume =
   convenience) is rejected: fatigue is a reliability risk at this priority level.
3. **Developer velocity** — faster triage (better runbooks) and fewer spurious
   interruptions, pursued only after the priority-2 concerns are protected.
4. **Convenience** — pure comfort gains rank last.

The relative ordering *within* priority 3 (runbooks vs routing fixes vs
recalibration) is not yet fixed; it will be set by what the measured baseline
shows.

## Constraints

- Every deployment/withholding decision must be auditable; a suppression audit
  trail **does not exist today** and is a hard prerequisite for adopting any
  suppression or dedup policy.
- Any automated approval (page-withholding) must be inspectable after the fact by
  the security team. An anomaly-detection model that cannot explain a specific
  suppression is likely inadmissible on these grounds.
- On-call (reviewer) capacity is fixed and does not scale with alert volume;
  moving alerts to async channels does not free capacity, only relabels it.
- All alert-config changes flow through the shared change process (no side
  channel); threshold tuning latency is 2–5 business days.
- Top-tier customer-facing / financial-settlement services: no suppression, no
  delay, ever.

## Assumptions

- The dismissal signal is contaminated: a "dismissed" or "no-response" alert
  cannot currently be distinguished between "noise correctly ignored" and "real
  alert missed under fatigue." The instrumentation design must name this hazard;
  noise-ratio estimates derived from dismissals are suspect until it is resolved.
- Raw alert timestamps are sufficient to *begin* building outcome linkage
  (assumed, not confirmed by the human).
- The informal criticality mapping is close enough to bootstrap a verification
  pass rather than requiring a from-scratch catalog (assumed).
- The two-to-five-day threshold-change latency applies uniformly across service
  teams (assumed from a single stated figure).

## Decisions made

- **Sequencing is two tracks, not one.** Track A: top-tier services get their
  policy confirmed *now* — page on first occurrence, no suppression — with no
  dependence on the baseline. Track B: recalibration, tiering, dedup, and any
  learned approach wait on the instrumentation and the noise-ratio data.
- **First deliverable is instrumentation** linking alert → outcome. It does not
  exist and everything else depends on it.
- **Detection tolerance is tiered:** zero suppression for the payment processor
  and financial-settlement path; a 1–2 minute confirmation window is acceptable
  for internal / non-customer-facing services. No formal SLA number was set.
- **The acceptable missed-incident rate is not the seed author's to set** — it
  belongs to the service owners who hold the SLAs, with input from whoever owns
  on-call capacity budget. The author's "rather keep the status quo than miss a
  production-down event" was a personal assertion, not policy.
- **Ownership of "real incident vs noise" must be assigned before any tiering or
  suppression policy** — service owners define it per service, with SRE oversight
  on the cross-service definition.
- **Authority boundary for changes:** threshold recalibration is within each
  service team's authority (config); severity tiering, deduplication logic, and
  AI anomaly detection touch shared infrastructure and require the platform
  team's process.
- **No suppression/dedup policy is acceptable until the withholding audit trail
  is built first.**
- **AI-based anomaly detection is gated:** a security-team conversation about
  admissibility of an unexplainable withholding decision must precede any
  commitment; it is ranked last of the floated ideas.
- **Deduplication grouping must be visible to the on-call engineer before they
  dismiss** (not a black box); the on-call engineer is the accountable party for
  a dismissed grouped alert. Working grouping intuition (same origin service,
  same error type, within 5 minutes) is provisional and known to risk collapsing
  multi-component cascades.

## Alternatives considered

- **Cut volume first, measure later** (Reading 1) — rejected; volume reduction
  without a baseline is guesswork and cannot be shown safe.
- **Uniform "persist for N minutes" suppression platform-wide** — rejected; a
  single delay ignores blast radius and would delay the payment-processor case.
  Replaced by per-tier delay tolerance.
- **Treat volume reduction as a convenience outcome** — rejected; fatigue is a
  priority-2 reliability risk.
- **Adopt severity tiering on the current criticality map** — deferred; the map
  must be audited and confirmed authoritative first.
- **AI anomaly detection as a peer option** — demoted to last and gated on
  security inspectability.

## Unresolved questions

- **Async/dashboard paging model:** if non-critical alerts move off push-paging,
  who is accountable for watching the async channel, during which hours, and how
  is that accountability recorded and verified? Until named, this reading is not
  implementable.
- **Dismissal disambiguation:** what instrumentation design (if any) can separate
  "noise correctly ignored" from "real alert missed under fatigue" so the
  baseline is not built on contaminated negatives?
- **Security-team requirement** for retention/inspectability of an automated
  page-withholding decision — the specific bar is unknown and determines whether
  learned suppression is admissible at all.
- **Formal acceptable missed-incident rate** per lower-tier service — the
  authority is now assigned (service owners) but the numbers are not yet set.
- **Formal, authoritative criticality catalog** — the verification pass is a
  named prerequisite but has not been done.

## Confidence

0.78. The framing is now well-grounded: the primary work (instrumentation),
the two-track sequencing, the tiered detection tolerance, and the ownership and
audit prerequisites are all decided by the human against the org priority order.
The largest remaining source of uncertainty is **the noise baseline itself** —
it is unmeasured, and the one signal available for measuring it (dismissals /
non-responses) is contaminated by the very fatigue under study. Until that
measurement hazard is resolved in the instrumentation design, every downstream
choice about which reduction mechanism the data "supports" rests on a number we
cannot yet trust.

## Design proposal — classify-and-auto-approve

### Approach

The authoritative framing has already translated this problem out of the deployment domain and into the alerting domain, and it did so on purpose: it defines *suppression / deduplication* as "**a machine deciding a human need not be interrupted; functionally an *automated approval***" and *noise* as the direct analog of the org's undefined "low-risk change." I design against that mapping and commit to the alert domain. Here, "classify changes by risk and auto-approve the low-risk ones" becomes: **a supervised classifier scores every fired alert from pipeline evidence; alerts it classifies as noise (low-risk) are auto-approved — withheld from the page and routed to an inspectable queue — and everything else pages a human.** The classifier runs in shadow beside the existing on-call gate, logging the decision it *would* have made, until its miss rate on the rare dangerous class (a real, production-affecting incident) is provably bounded per service, then cuts over.

I take two positions the later agents should not expect me to soften:

1. **This is not the "AI anomaly detection" the framing demoted to last and gated on inspectability.** That objection is aimed at an *unsupervised, unexplainable* detector. My design is a supervised, evidence-feature classifier that emits a per-decision explanation and never sees the top-tier services. The framing's gate is correct for a black box; it is over-broad if applied to an inspectable classifier with a hard policy floor. I quote the constraint — "An anomaly-detection model that cannot explain a specific suppression is likely inadmissible" — and meet it by construction rather than treating it as a reason to abandon the approach.

2. **The false-negative gate must be measured against independently-confirmed incidents, not against dismissals.** The framing's deepest hazard is that "a 'dismissed' or 'no-response' alert cannot currently be distinguished between 'noise correctly ignored' and 'real alert missed under fatigue.'" That contamination is fatal to any noise-*ratio* estimate — but it is *not* fatal to the safety gate, because a real production incident leaves independent traces (incident tickets, SLO breaches, customer-impact events). I build the entire cutover decision on that independent evidence and leave the contaminated dismissal signal out of the safety path entirely. This is also exactly what the desired outcome demands — top-tier behavior "confirmed independently of the baseline."

### System primitives

- **Evidence record** — the feature vector for one alert, extracted from pipeline evidence at fire time: origin service, tier, error class, blast-radius signals, correlated deploys, downstream health, recurrence within window. This is the *only* input the classifier sees; it is content-addressed and retained.
- **Classifier** — a supervised model mapping an evidence record to a class in {noise / low-risk, escalate} with a confidence and, mandatorily, a **decision attribution**: the specific features and thresholds that produced the class. I require an inspectable model form (rule list or gradient-boosted trees with per-decision feature attribution), not because it scores better but because the security constraint makes an unexplainable withholding decision inadmissible.
- **Auto-approve region** — the subset of evidence space the classifier maps to "noise." It is bounded from below by an **exclusion signature set**: evidence patterns matching any historically-confirmed real incident, which can *never* be auto-approved regardless of model output.
- **Tier floor** — a hard policy, outside the model, that forces `escalate` for the payment processor and financial-settlement path: "no suppression, no delay, ever." The classifier is never even consulted for these.
- **Shadow decision** — the classifier's would-be decision, logged against the *actual* human outcome, with the human unaware of it (see workflows).
- **Confirmed-incident feed** — an independent stream of production-affecting incidents (tickets, SLO-breach records, customer-impact events) used as the *clean* label source for the dangerous class. This is a new primitive I add on top of the framing's instrumentation, and it is a hard prerequisite.
- **Alert outcome** — the framing's acted / auto-resolved / dismissed / no-response linkage. I use `acted` and `auto-resolved` as training signal; I treat `dismissed` / `no-response` as **contaminated and inadmissible** for the safety path.
- **Cutover gate** — a per-service, service-owner-set bound on the miss rate that must be met on the confirmed-incident feed before the classifier's auto-approve region is allowed to withhold pages for that service.
- **Audit record** — for every auto-approval: evidence record, class, attribution, model version, exclusion-set version, timestamp, and the accountable on-call identity.

### Architecture

```
alert fires
   │
   ▼
[evidence extraction] ──► evidence record (retained)
   │
   ├─ tier == top-tier?  ──yes──► PAGE (classifier not consulted)  ──► audit
   │
   ▼ no
[classifier]  ─► class + confidence + attribution
   │
   ├─ evidence incomplete OR out-of-distribution ─► ESCALATE (default-safe)
   ├─ matches exclusion signature ──────────────► ESCALATE
   │
   ▼
 SHADOW MODE                          POST-CUTOVER
 ─────────                            ────────────
 human is paged as today             class==noise ─► inspectable queue (+ audit)
 shadow decision logged              class==escalate ─► PAGE (+ audit)
 vs actual outcome                   + hold-out sample: X% of would-be
                                       auto-approvals still PAGE, forever
```

The pipeline is single-path per the constraint ("no side channel"). Shadow mode adds a logging tap, not a second gate. The **hold-out sample post-cutover is not optional**: cutting over blinds the model to precisely the region it now automates, so I keep a random fraction of would-be auto-approvals on the page path indefinitely to preserve a live, un-blinded miss-rate measurement and to keep the confirmed-incident feed populated in the auto-approve region. Model training reads `acted`/`auto-resolved` outcomes and the confirmed-incident feed; it is explicitly firewalled from `dismissed`/`no-response`. Model versions and the exclusion set are immutable, signed artifacts in a registry governed by the shared change process.

### User workflows

- **On-call, shadow phase:** unchanged from today — every non-top-tier alert still pages. The shadow decision is **hidden from the engineer.** Showing it ("the classifier would have suppressed this") would bias the human's action and contaminate the very outcome we are trying to measure. This costs velocity during shadow but protects the measurement.
- **On-call, post-cutover:** real alerts page as before; auto-approved alerts land in an inspectable queue the engineer owns. Per the framing, "the on-call engineer is the accountable party for a dismissed grouped alert" — so the queue is reviewable, attributed, and never a black hole. Hold-out-sampled would-be-approvals still page.
- **Service owner:** sets the acceptable missed-incident rate for their service — the cutover gate. The framing is explicit that this number "belongs to the service owners." No cutover for a service without their sign-off on the measured bound.
- **Security team:** pulls any auto-approval and gets the full audit record — evidence, attribution, model + exclusion-set version. Inspectability is a query, not a forensic reconstruction.
- **Platform / SRE:** owns the exclusion set, drift monitors, retraining cadence, and the confirmed-incident feed integration; all model changes flow through the shared change process.

### Failure modes

- **Silent miss (the catastrophic one):** classifier auto-approves a real incident. Layered defense: tier floor removes the highest-stakes services from the model entirely; exclusion set makes known-incident patterns un-approvable by construction; the cutover gate bounds the residual statistically; the permanent hold-out sample catches post-cutover regressions. Even so, this failure is never driven to zero for novel incident shapes — that residual is the whole reason the *gate* is owned by service owners, not by me.
- **Contaminated-label death spiral:** if the "safe to suppress" label were trained on `dismissed` outcomes, the model would learn to suppress incidents that fatigued engineers missed — and then, post-cutover, those alerts stop paging, so they get "dismissed" by omission, reinforcing the error. This is a self-amplifying loss of detection. My design severs it by refusing dismissal signal in the safety path; it is the single most important structural decision here.
- **Cutover-induced blindness:** once you stop paging a region, you stop learning about it. Mitigated only by the permanent hold-out sample and the independent confirmed-incident feed; without both, cutover is a one-way loss of observability.
- **Rare-event under-powering:** the gate may be statistically unreachable. With zero misses in *n* confirmed incidents, the rule-of-three gives a 95% upper bound of ≈ 3/n; a service owner asking for a 0.5% miss bound needs ≈ 600 confirmed incidents observed in shadow with zero classifier misses. For a genuinely rare production-down class this can mean an impractically long shadow phase. **This is why the exclusion set (proof by construction), not the statistical bound, carries most of the safety weight** — the statistical gate is a backstop, not the primary guarantee. If neither can be satisfied, the honest outcome is: the service never cuts over and the human gate stays. The approach must be allowed to fail closed at the service granularity.
- **Out-of-distribution / incomplete evidence:** a new service or a partial evidence record. Default-safe: abstain → escalate. The model never auto-approves on inputs it has low coverage for or on incomplete evidence.
- **Drift:** deploy patterns, error taxonomies, or topology change under the model. Continuous drift monitoring on the input distribution; a drift trip reverts affected services to escalate-by-default pending re-validation.

### Operational complexity

This is a standing ML system, not a one-time rule. It requires: two live data feeds (the framing's outcome instrumentation **plus** the confirmed-incident feed I add); shadow logging at full alert volume; a signed model + exclusion-set registry under the shared change process; drift and miss-rate dashboards; a retraining cadence; per-service gate configuration; and a model-governance sign-off flow. Against a fixed on-call capacity that "does not scale with alert volume," none of this frees a reviewer until cutover — and shadow *adds* the review overhead of maintaining the pipeline while paging stays at today's level. Organizations should size this as ongoing platform work, and should be told plainly that the payoff is deferred behind the cutover gate and may, for the rarest services, never arrive.

### Security implications

- **The classifier is a bypass control.** Auto-approval creates an incentive to shape a change so it is *classified* low-risk and thereby skips the human gate. The evidence features must be ones an actor cannot cheaply forge (server-side test results, measured blast radius, downstream health) rather than self-asserted metadata. This threat is why the tier floor exists in policy, above the model, for the highest-value paths.
- **The training set and model registry are privileged.** Anyone who can alter the training data or the model artifact can effectively grant blanket approvals — poisoning the labels toward "suppress" is functionally a compromise of the approval gate. The registry, the confirmed-incident feed, and the training pipeline therefore need the same access controls and audit as the deployment gate itself; they are in-scope for the security team's review, not just the model's runtime output.
- **Contaminated labels are a security weakness, not only a data-quality one:** if dismissals fed training, an actor who could make a real incident *look* dismissible could teach the model to suppress it. Excluding dismissal signal closes this specific avenue.
- **Inspectability is a hard runtime requirement, met by design:** every auto-approval carries evidence, attribution, and versions, satisfying "inspectable after the fact by the security team." A model that cannot produce this per decision is disqualified before evaluation — I treat the framing's admissibility bar as a build constraint, not a downstream negotiation.
- **Fail-safe posture:** every uncertainty — incomplete evidence, OOD input, drift trip, feed outage — resolves to *escalate*, never to *auto-approve*. The secure default is to page.

### Implementation constraints

- **Blocked on the framing's first deliverable.** No shadow phase can begin before alert→outcome instrumentation exists, and my design additionally blocks on the confirmed-incident feed. I name that second feed as a design assumption the framing did not commit to: I am asserting that independently-confirmed incidents are queryable; if they are not, the safety gate has no clean labels and this approach is not implementable.
- **Interpretable model mandatory** — dictated by the inspectability constraint, not by accuracy.
- **Top-tier floor is policy, not model** — hard-coded, outside the classifier, non-overridable.
- **Cutover is per-service and owner-gated** — the acceptable miss rate is set by service owners; the platform team cannot cut a service over unilaterally.
- **Change latency applies to the model** — model and exclusion-set updates flow through the shared change process with its 2–5 business-day latency; this bounds retraining responsiveness and must be planned around.
- **Audit retention is non-negotiable** for every decision, including shadow decisions.

### Alternatives considered

- **Unsupervised anomaly detection instead of a supervised evidence classifier** — rejected. It cannot produce a per-decision explanation and gives no principled miss-rate bound; it is the exact thing the framing rightly gates. My supervised, attributed model is what lets me *challenge* that gate for this specific construction.
- **Training the "safe to suppress" label on dismissal/no-response outcomes** — rejected as the central error to avoid; it wires the contamination directly into the safety path and creates the death-spiral failure mode.
- **Full hard cutover (stop paging the auto-approve region entirely)** — rejected in favor of a permanent hold-out sample. A clean cutover blinds the system to the region it just automated; never fully stop measuring.
- **Showing the shadow decision to the on-call engineer during shadow** — rejected; it biases the human's action and contaminates the outcome labels the whole evaluation depends on.
- **A single global suppression threshold** — rejected, consistent with the framing's rejection of "uniform 'persist for N minutes' suppression"; blast radius differs by service, so I use one model with per-service gate thresholds and a tier floor, not one global cut.
- **One model per service** — rejected; per-service data is too sparse to power any gate. A shared model with per-service thresholds concentrates the (still scarce) dangerous-class signal.
- **Confidence-threshold-only decisioning, no exclusion set** — rejected; on a rare, under-powered class a threshold alone cannot give a defensible guarantee. The exclusion set provides proof-by-construction for known incident shapes and carries the safety weight the statistics cannot.

## Design proposal — policy-replaces-approval

### Approach

The framing has already moved this problem into the alerting domain and named the exact mechanism I am here to build: a **severity tier** is "*a policy replacing judgment, inspectable but only as trustworthy as the criticality catalog beneath it*," and the org context defines **policy** as "*machine-checkable rules that encode when approval is required*." My approach takes that literally and generalizes it. Mapped from the deployment framing: **eliminate the per-alert human decision for qualifying alerts and enforce every reliability guarantee as a deterministic, machine-checkable policy rule over pipeline evidence.** An alert that a rule resolves — page, withhold, or hold-then-page — is handled with no human interrupted, and **the policy evaluation trace is itself the audit record**; there is no separate approval event to log.

I commit to three positions and will not soften them:

1. **Deterministic rules, not a learned model.** The differentiator from the preceding *classify-and-auto-approve* proposal is total: I do not train, do not run a shadow-then-cutover ML lifecycle, and do not offer a statistical miss-rate bound. A withhold rule either *provably* excludes every known-incident shape in the backtest or it does not merge. That proposal itself concedes "*the exclusion set (proof by construction), not the statistical bound, carries most of the safety weight*." I take that concession to its conclusion: if proof-by-construction carries the weight, drop the classifier and keep only the constructive policy.

2. **The service owner's noise definition *is* the rule.** The framing decides "*service owners define [real incident vs noise] per service*." My design realizes that decision directly instead of inferring it from data: the owner writes an explicit predicate ("error-class X on service Y with no downstream-health signal is noise"), it is validated against the confirmed-incident feed, and it becomes the executable, inspectable, owned artifact. Definition and enforcement are the same object.

3. **A withheld alert requires no human watcher.** If withholding merely routes to a queue an engineer must review, the human decision is not eliminated — it is batched and relabeled async, and it re-consumes the fixed reviewer capacity the framing says "*does not scale with alert volume*." I reject the queue. Safety for withheld alerts rests on rule correctness, the merge-time backtest, the default-page floor, and a continuous conformance backstop — not on a person.

The strongest and safest withholding action falls out of the framing's own decision that "*a 1–2 minute confirmation window is acceptable for internal / non-customer-facing services*": `PAGE-AFTER-CONFIRM`. It withholds based on a **future observation** (did the condition clear?) rather than a **prediction** (is this noise?). That is epistemically far stronger than classification and is self-correcting; I foreground it as the preferred withholding action wherever a service can tolerate the window.

### System primitives

- **Evidence record** — the feature vector extracted at fire time from pipeline evidence: origin service, tier, error class, blast-radius signals, correlated deploys, downstream health, recurrence within window. Content-addressed and retained. Same input the preceding proposal uses; I make it the sole input to the policy.
- **Policy rule** — a machine-checkable predicate over an evidence record → action, carrying immutable metadata: rule id, version, **named accountable owner**, the guarantee or noise-definition it encodes, and authored rationale. A rule without a named accountable owner cannot be merged.
- **Policy** — a priority-ordered, **total** ruleset evaluated deterministically (first-match). Totality is a hard property: every evidence record hits a rule; the terminal rule is default-page.
- **Guarantee rule** — a rule encoding a framing invariant, evaluated first and non-overridable (see Architecture). Guarantees "become policy rules" as the task requires.
- **Action** — `PAGE`, `WITHHOLD`, or `PAGE-AFTER-CONFIRM(window)`.
- **Decision** — the evaluation result: action + firing rule id/version + evidence hash + policy version + accountable owner + timestamp. **The decision record is the audit record.** There is no approval object separate from it.
- **Confirmed-incident feed** — independently-confirmed production incidents (tickets, SLO-breach records, customer-impact events). I adopt this primitive from the preceding proposal but **repurpose it**: not a training-label source and not a statistical gate, but (a) the merge-time backtest oracle and (b) the runtime conformance backstop.
- **Backtest harness** — replays a candidate ruleset against retained alert-evidence history and against the full confirmed-incident feed; a rule that would have withheld any confirmed incident fails the merge.
- **Conformance monitor** — at runtime, cross-checks withheld/held decisions against the confirmed-incident feed; a match alarms and **auto-suspends the firing rule**.

### Architecture

```
alert fires
  │
  ▼
[evidence extraction] ──► evidence record (content-addressed, retained)
  │
  ▼
[policy engine] — deterministic, priority-ordered, total
  │
  1. GUARANTEE RULES  (non-overridable, evaluated first)
  │     tier == top-tier                         → PAGE
  │     evidence incomplete / out-of-catalog     → PAGE
  │     matches confirmed-incident signature     → PAGE
  │
  2. OWNER RULES  (per service; each carries a named accountable owner)
  │     noise predicate matches                  → WITHHOLD
  │     confirmable predicate matches            → PAGE-AFTER-CONFIRM(window)
  │
  3. DEFAULT
  │     no match                                 → PAGE
  │
  ▼
[decision] = action + firing rule id/version + evidence hash
           + policy version + named accountable owner + timestamp
  │
  ├─► the decision record IS the audit record (no separate approval event)
  ▼
action executed
  ▲
  │
[conformance monitor] ── reads confirmed-incident feed ──►
   withheld/held decision later matches a confirmed incident
   → alarm + auto-suspend the firing rule
```

Single-path per "*no side channel*." `PAGE-AFTER-CONFIRM(window)` withholds for the window; an **independent** auto-resolve signal (the condition clearing — not a dismissal) keeps it withheld with an audit record; persistence past the window pages. The rule repository is versioned and governed by the shared change process; every candidate ruleset must pass the backtest before merge.

### User workflows

- **Service owner** authors and owns the noise/confirmable rules for their service — their executable noise definition — and is recorded as the accountable party stamped into every decision those rules produce. Sets the `PAGE-AFTER-CONFIRM` window within their SLA. No withhold rule ships for a service without its owner's authored, backtested rule.
- **Platform / SRE** owns the engine, the guarantee rules (top-tier floor, incomplete-evidence floor, confirmed-signature floor), the totality/default-page invariant, the criticality-catalog verification, and the conformance monitor. Is the accountable party recorded on guarantee-rule and default decisions.
- **On-call** is **not** interrupted for withheld alerts — that is the point. Real pages arrive as today; `PAGE-AFTER-CONFIRM` alerts page only if they persist. There is no queue to watch.
- **Security team** pulls any decision and reads the firing rule, evidence hash, policy version, and accountable owner. Inspectability is a lookup, not a reconstruction, and not an interpretation of feature contributions — it is the machine-checkable rule that fired.

### Failure modes

- **Silent miss via a bad withhold rule (the catastrophic one).** A rule withholds a real-incident shape absent from the backtest history. Layered defense: top-tier floor removes the highest-stakes paths; the confirmed-signature guarantee rule blocks known shapes; the merge backtest rejects any rule that would have withheld a confirmed incident; default-page catches non-matches; the conformance monitor auto-suspends a rule the moment a confirmed incident matches a withheld decision. **Honest limit:** the conformance monitor is a *rule-quality* backstop, not a per-incident safety net — it fires only after the confirmed-incident feed registers the incident, which lags the withheld page by the feed's own latency (minutes to hours). It will catch a systematically-bad rule; it will **not** save the specific incident that slipped. Per-incident safety therefore rests entirely on rule correctness + backtest + default-page. This is why top-tier never withholds and why I prefer `PAGE-AFTER-CONFIRM` (self-correcting) over `WITHHOLD` (predictive).
- **Confirmation-invisible incident.** A real degradation whose *only* trace is the alert itself — no ticket, no SLO breach — is withheld and then never surfaces in the confirmed-incident feed, so the backstop is blind to it forever. This is the hard ceiling on how aggressive any withhold rule may be, and the strongest argument for conservative, owner-authored rules over broad suppression.
- **Rule rot.** A rule written for last year's error taxonomy keeps withholding silently after the world changes — the deterministic analog of model drift, with no self-awareness that its assumptions expired. Mitigation: every rule carries a mandatory review/expiry date; expired rules fail closed (revert to page); periodic rule audit.
- **Rule interaction / ordering error.** Overlapping rules can produce an unintended withhold. Mitigation: strict first-match priority, conflict detection at merge, guarantee rules evaluated first and non-overridable.
- **Catalog error.** A top-tier service mis-tiered downward evades the top-tier floor. Mitigated by the verification-pass prerequisite and by treating tier assignment as a privileged, audited change (see Security).
- **Confirmed-incident feed outage.** The backstop goes blind; fail-safe response is to suspend new `WITHHOLD` decisions (default toward page) until the feed recovers.
- **Evidence spoofing.** Covered under Security.

### Operational complexity

Substantially lower than a standing ML system, and I state that plainly as the payoff of determinism. There is **no** training pipeline, **no** input-distribution drift monitoring, **no** retraining cadence, **no** model registry, and **no** statistical-power problem — the preceding proposal's "*≈ 600 confirmed incidents observed in shadow with zero classifier misses*" gate simply does not exist here, because a deterministic exclusion is categorical, not probabilistic.

What it does require, concretely:

- A deterministic policy engine and a versioned rule repository under the shared change process.
- The confirmed-incident feed (hard prerequisite; used for backtest + conformance).
- A backtest harness and a runtime conformance monitor.
- Retained alert-evidence history for backtest coverage.

**Reviewer-capacity accounting (honest).** Unlike the ML approach, which "*frees no reviewer until cutover*," a policy rule frees per-alert capacity the moment it merges — withheld alerts genuinely do not page and need no watcher. But the cost relocates, it does not vanish: recurring per-alert interruption becomes one-time per-rule authoring/review plus ongoing rule maintenance, drawing on the **same** fixed owner/reviewer capacity. For high-frequency structured noise this is a large net win; for long-tail one-off noise it is not worth a rule, and those alerts keep paging — which is the intended, safe outcome.

**Change-latency accounting.** The framing's "*2–5 business days*" now bounds *rule* iteration. Acceptable under the priority order (safety and reliability over velocity): a newly-discovered noise pattern is filed as a rule change and waits, rather than being suppressed reactively. Rules should not churn hourly; if they do, that is a signal the definition is wrong, not that the latency is the problem.

### Security implications

- **Policy is a bypass control, and its readability cuts both ways.** A deterministic ruleset is exactly the map of which evidence patterns skip the page. This makes it maximally auditable (a strength) and maximally targetable — an actor with repo read access knows precisely what shape of alert gets withheld (a weakness). The mitigation is identical in spirit to the preceding proposal but sharper here: **withhold predicates must depend only on forgery-resistant, server-measured evidence** (measured blast radius, downstream health, correlated deploys), never on self-asserted metadata an actor controls. The top-tier floor exists in policy *above* every owner rule precisely so the highest-value paths cannot be reached by evidence-shaping at all.
- **Human judgment is relocated, not eliminated — and its blast radius grows.** This is the central security trade and I will not hide it. "Eliminating approval for qualifying deployments" moves the human decision from per-alert to per-**rule**: reviewed once, applied N times. One bad or malicious withhold rule silently suppresses an entire class indefinitely. The rule repository is therefore the privileged asset with the same authority as the deployment gate itself. It requires: two-party review on every rule change, access control equal to the gate, a named accountable owner recorded on the rule and stamped into every decision, and full change audit. Anyone who can merge a withhold rule can grant blanket suppression; that authority must be governed as such.
- **Catalog integrity is security-relevant.** The top-tier floor is only as trustworthy as the tier assignment beneath it — the framing's own caveat. Tier assignments are privileged, audited inputs; the verification pass is a security prerequisite, not merely a data-quality one.
- **Inspectability is met by construction, and better than the ML alternative.** The audit record *is* the machine-checkable rule that fired; the security team reads a predicate, not a model's feature attribution. This is the strongest possible satisfaction of "*inspectable after the fact by the security team*," and it structurally closes the framing's flagged gap that "*a suppression audit trail does not exist today*" — this mechanism **cannot** withhold without emitting the trail.
- **Fail-safe posture.** Every gap resolves to `PAGE`: incomplete evidence, out-of-catalog service, no matching rule, expired rule, feed outage. The secure default is to interrupt a human.

### Implementation constraints

- **Lighter dependency on the framing's first deliverable than the preceding proposal.** I do **not** need the contaminated `acted`/`dismissed`/`no-response` outcome linkage for the safety path — the framing calls that signal "*contaminated and inadmissible*," and my rules are validated against **independently**-confirmed incidents instead. I depend on: (a) the confirmed-incident feed (hard, and I name it as an added assumption the framing did not commit to — if independently-confirmed incidents are not queryable, the backtest has no oracle and the approach is not implementable), and (b) retained alert-evidence history for backtest coverage. This is a genuine advantage of the deterministic path: it sidesteps the contaminated-outcome instrumentation entirely for safety.
- **Backtest fidelity is bounded by historical evidence.** Evidence extraction is a new go-forward capability; history holds mainly raw timestamps. The backtest can only be as rich as the evidence reconstructable from the past. New/sparse services therefore start under default-page with no owner withhold rules until enough live evidence and confirmed-incident history accrue.
- **Criticality-catalog verification is a blocking prerequisite for tier-based rules.** Until the catalog is verified authoritative, the policy runs in a restricted mode: default-page dominates and the *only* withholding permitted is explicit, owner-authored, backtested per-service rules — tiers are not used for withholding decisions.
- **Guarantees must reduce to predicates over forgery-resistant evidence — this is the boundary of the approach.** Any guarantee that cannot be so expressed cannot be enforced by this mechanism and must keep the human gate. I name this boundary rather than papering over it: the approach enforces the guarantees it can encode, and honestly declines the ones it cannot.
- **Totality and determinism are hard invariants.** The evaluator is deterministic and side-effect-ordered; the ruleset is total with default-page; no rule may act on unavailable evidence without falling through to page.
- **Every rule requires a named accountable owner and a review/expiry date** — no merge without both. Expiry-lapsed rules fail closed.
- **Audit retention is non-negotiable** for every decision, since the decision *is* the audit record.

### Alternatives considered

- **A learned policy instead of deterministic rules** — rejected. It reintroduces the inspectability problem, statistical gates, drift, retraining, and a privileged training-data asset, for coverage of exactly the long-tail region where the guarantee is weakest. Determinism is the entire point of this direction.
- **Keeping an async inspectable queue with a human watcher for withheld alerts** — rejected. It does not eliminate the human decision; it batches and relabels it, re-consuming fixed reviewer capacity. Either an alert is noise (no queue needed) or it is not (page).
- **Deriving withhold rules from `acted`/`dismissed` outcomes** — rejected as contaminated per the framing; rules come from explicit owner definition validated against confirmed incidents.
- **Using the confirmed-incident feed as a real-time per-alert safety net** — rejected as infeasible: the feed's latency exceeds any tolerable page-withholding window. It is a rule-quality backstop only, and I design to that limit rather than overselling it.
- **A single global ruleset with no per-service ownership** — rejected; the noise definition is per-service and per-owner by the framing, and accountability must attach to the authoring owner.
- **Advisory/soft policy where a human confirms each withhold** — rejected; that is the status-quo approval gate under another name.
- **A statistical miss-rate cutover gate** — rejected for this mechanism; a deterministic rule has no probabilistic output to bound. The backtest is a *proof over observed history*, not a bound over the future, and I state that limit plainly rather than dressing it as a guarantee for novel shapes.

### Disagreements with earlier proposals

- **The classify-and-auto-approve ML apparatus is unjustified for the guarantee it yields.** Its own failure analysis admits the statistical gate "*may be statistically unreachable*" and that "*the exclusion set (proof by construction) … carries most of the safety weight.*" If the constructive component carries the safety, the classifier is marginal machinery — adding drift, retraining latency, label-poisoning surface, and a privileged training set — to reach benign long-tail noise that is, by definition, the least safely withheld region. Under the priority order (safety over velocity) that extra reduction is not worth its risk surface. I keep only the constructive policy.
- **Its post-cutover "inspectable queue the engineer owns" reintroduces the human it claims to remove.** An auto-approved alert that still lands in a queue an engineer reviews is a batched interruption, not an eliminated one, and it draws on the fixed capacity the framing says does not scale. I remove the queue; withheld means no human, with the conformance feed and default-page as the backstop.
- **I reassign the accountable party, against the framing's decision.** The framing states "*the on-call engineer is the accountable party for a dismissed grouped alert.*" My approach structurally cannot rest accountability there, because there is no per-alert human decision to attribute. Accountability moves to the **rule's named owner**, recorded once at authoring and stamped into every decision the rule produces. I flag this as a deliberate consequence of eliminating the per-alert gate, not an oversight — and note it is the honest security accounting: the human judgment did not disappear, it was relocated to rule authorship, where its blast radius is larger and must be governed accordingly.
- **Full live shadow-then-cutover is unnecessary for a deterministic policy.** A model's behavior is unknown until observed, so it earns a shadow phase; a ruleset's behavior is knowable by reading and backtesting it. I replace the indefinite shadow + statistical cutover with a merge-time backtest plus continuous conformance. A bounded shadow run is available as optional confirmation, never as the safety mechanism.
- **I adopt the confirmed-incident feed but reject its stated role.** The preceding proposal uses it as a training-label source and statistical gate; I use it as the backtest oracle and the runtime auto-suspend backstop. It is the right primitive pointed at the wrong job in that proposal.

## Design proposal — differentiated-human-review

### Approach

The framing committed this problem to the alerting domain and, in doing so, gave every reduction mechanism the same load-bearing definition: suppression/dedup is "**a machine deciding a human need not be interrupted; functionally an *automated approval***." The two proposals before me accept that machines should make that decision — one probabilistically (classify-and-auto-approve), one categorically (policy-replaces-approval). I reject the premise. Mapped from the deployment framing, my approach is: **no alert decision is automated; a named human signs off on every one. The machine re-engineers the *attention* around that decision — how, when, in what grouping, and with what pre-attached evidence the human is interrupted — but never *whether*.**

The distinction I build the whole design on is **routing vs. suppression**. Suppression decides a human is *never* interrupted for an alert; the decision belongs to the machine. Routing decides *how and when* a human is interrupted and *with what evidence*; the decision still belongs to the human. The consequence is categorical and is my central claim under the org priority order:

> **A routing error degrades to a bounded latency cost — a real alert seen at a slower tier — never to a silently dropped incident.**

Both earlier proposals concede they cannot drive the silent-drop to zero: proposal 1 admits "this failure is never driven to zero for novel incident shapes"; proposal 2 admits its backstop "will **not** save the specific incident that slipped." Priority 1 is "never trade away detection of a real production-affecting incident." My reading is that if neither automated approach can eliminate silent drops, the safe design does not accept silent-drop risk *at all* — it accepts a bounded latency cost instead, and pays for that with a smaller velocity gain. That is exactly the trade the priority order prescribes (safety over velocity).

The fatigue attack does not come from removing decisions — the framing is right that fixed reviewer capacity "does not scale with alert volume" and that async channels "relabel" rather than free it. It comes from attacking the three drivers of the fatigue *hazard* the framing names ("an overwhelmed engineer who stops trusting pages will dismiss a real one"): **interrupt count**, **per-decision cost**, and **trust erosion** — none of which is the same as raw decision count. I use the prior proposals' classifier and policy engine, but **demoted to advisory pre-review evidence with no authority**. Because the model never decides, it never needs a cutover gate, a statistical power argument, an exclusion set for safety, or a shadow-then-cutover lifecycle. The framing's AI gate — "an anomaly-detection model that cannot explain a specific suppression is likely inadmissible" — is aimed at a model that *withholds*. Mine only *suggests to a human who withholds nothing without signing off*, which is a far lower admissibility bar.

Two hard commitments I will not soften: **decisions are opt-in, never opt-out** (nothing is approved by a human's silence — default is always page/escalate); and **every non-immediate channel is a named, scheduled obligation with escalation, never a passive dashboard** — I resolve the framing's open async-watcher question rather than inheriting it.

### System primitives

- **Evidence record** — the feature vector at fire time (origin service, tier, error class, blast-radius signals, correlated deploys, downstream health, recurrence within window). Content-addressed and retained. Same input the prior proposals use.
- **Pre-review evidence bundle** — the advisory layer's output attached to an alert: suggested classification + confidence, matched policies/guarantees, blast-radius summary, correlated deploy, recurrence, and a plain-language *rationale*. It is **evidence, not a decision** — it carries a suggestion, never an authority.
- **Advisory classifier** — a model mapping evidence → suggested triage tier + suggested class. Because it holds no authority, it may be richer than proposal 1's mandatory-interpretable model — but it must still emit a human-readable rationale to guard against automation bias.
- **Interrupt tier** — how/when a human is reached: `T0 immediate-page`, `T1 coalesce-then-page(window)`, `T2 batched-review(SLA)`. A tier is a *latency budget*, set by policy, never by the model alone.
- **Risk router** — deterministic policy that maps (tier floor + catalog + evidence + advisory suggestion) → interrupt tier, with hard floors to T0 that the advisory can never override.
- **Batch / digest** — a grouped set of same-tier, same-owner T2 items presented as one review session. Sign-off is recorded **per item**, not per batch.
- **Scheduled review obligation** — a named reviewer role, a cadence, an SLA, and completion tracking. Non-completion is itself an escalating alert. This is what makes T2 not a black hole.
- **Named accountable sign-off** — the human identity attached to every decision (T0 ack, T1 ack, each T2 item). Preserves the framing's "the on-call engineer is the accountable party."
- **Decision / audit record** — action + firing router rule/version + evidence hash + interrupt tier + advisory suggestion shown + **the human sign-off identity and time**. The routing is auditable *and* the human decision is auditable; the two are distinct events.
- **Confirmed-incident feed** — independently-confirmed incidents (tickets, SLO breaches, customer-impact). I adopt this primitive but point it at a third job: a **routing-quality (latency) monitor** — did any confirmed incident get routed below T0?
- **Outcome instrumentation** — the framing's acted/auto-resolved/dismissed/no-response linkage. I use it to *evaluate* fatigue reduction and tune routing, **not** as a safety substrate.

### Architecture

```
alert fires
   │
   ▼
[evidence extraction] ──► evidence record (content-addressed, retained)
   │
   ▼
[advisory layer]  ─► pre-review evidence bundle
   │                 (suggested tier + class + rationale + policy matches)
   │                 NO decision, NO withholding
   ▼
[risk router] — deterministic; advisory is an INPUT, never an authority
   │
   ├─ tier == top-tier ─────────────────────────► T0
   ├─ evidence incomplete / out-of-catalog / OOD ─► T0   (fail-safe up)
   ├─ blast radius > tier tolerance ─────────────► T0
   │
   ├─ confirmable, low blast ────────────────────► T1  coalesce-then-page(window)
   ├─ owner-classified low-risk, bounded blast ──► T2  batched-review(SLA)
   └─ no match ──────────────────────────────────► T0  (default-page)
   │
   ▼
delivery to a NAMED human at the routed tier, evidence bundle attached
   │
   ├─ T0: immediate push page  ──► human ack/act
   ├─ T1: window coalesces dupes into ONE page (grouping visible pre-dismiss)
   │       still active after window ──► page ──► human ack/act
   └─ T2: appears in the owner's scheduled review session
           each item signed off individually
           item aging past SLA OR blast-radius change ──► escalate to T1/T0
   │
   ▼
[decision] = action + router rule/version + evidence hash + tier
           + advisory shown + HUMAN sign-off identity + timestamp
   │
   ├─► audit record (routing event + human decision event, both retained)
   ├─► outcome instrumentation (acted/dismissed/…)  [evaluation only]
   ▼
[routing-quality monitor] ── reads confirmed-incident feed ──►
   any confirmed incident routed below T0 → routing defect + retune
   (bounded latency already incurred; NOT a silent drop)
```

Single-path per "no side channel." Every leaf ends in a human sign-off. The router only chooses the *path*; the terminal action on every path is a human decision. Fail-safe is always *up* toward T0. Router rules and tier assignments are versioned under the shared change process.

### User workflows

I own this dimension; I make it concrete.

**On-call, T0 (critical / top-tier):** unchanged in urgency — immediate page, first occurrence, no suppression, no batching, ever (Track A honored directly). What changes is the *cost per page*: the pre-review evidence bundle arrives with the page (blast radius, correlated deploy, suggested class, matched runbook), so triage starts already-briefed instead of from a bare timestamp. The engineer acts and acks; the ack is the audit sign-off.

**On-call, T1 (coalesce-then-page):** a burst of same-origin/same-error alerts within the window is coalesced into **one** page whose body lists every coalesced member — the grouping is **visible before the engineer dismisses**, honoring the framing's "deduplication grouping must be visible to the on-call engineer before they dismiss." The engineer is the accountable party for the coalesced group. If the condition self-clears within the window (an *independent* clear signal — the condition resolving, not a dismissal), it is recorded as auto-resolved with an audit record and no page. Persistence past the window pages. This is where a 20-alert cascade storm becomes one interrupt without any decision being dropped.

**On-call / service-team reviewer, T2 (scheduled batch review):** this is the core new workflow, and I design it against batch rubber-stamping — the failure the automated approaches avoid by never showing the human anything. Rules:
- The digest is a **scheduled obligation** with a named owning reviewer (default: the alert's service team), a cadence, and an SLA (owner-set; e.g. ≤ 4 business hours). It is *not* a dashboard someone might glance at.
- **Non-completion escalates**: an unreviewed session past its SLA pages the reviewer, then the reviewer's escalation contact. There is no way for the batch to silently rot.
- **Per-item sign-off**, not per-batch. Each item records who signed off and the outcome. A "reviewed" stamp on a batch is not accepted; the audit demands item-level identity.
- **Bounded batch size + forced sampling**: sessions are capped; oversized backlogs escalate to T1 rather than being dumped into one session. A random sample of each session is flagged for mandatory rationale entry, so pure rubber-stamping is detectable.
- **Dwell-time is instrumented** as a fatigue indicator: near-zero dwell across a session is a rubber-stamp signal that feeds the framing's instrumentation and triggers review of whether that noise class should even be in T2.
- **Any item whose blast radius or recurrence changes escalates out of the batch** to T1/T0 before the session is due.

**Service owner:** sets, per service, (a) which classes may be routed to T1/T2 and (b) the **latency tolerance** for each tier. This is where I map the framing's decision that the acceptable-miss authority "belongs to the service owners" — but onto a *latency budget* (how long may a human decision wait) rather than a *miss rate* (how often may an incident be dropped), because in my design nothing is dropped. Owners cannot route their own top-tier services below T0.

**Platform / SRE:** owns the router, the T0 floors, the catalog verification, the digest-obligation scheduling and escalation, the advisory model, and the routing-quality monitor. Accountable party on routing-config decisions and default-page decisions.

**Security team:** pulls any decision and reads two linked, non-interpretive facts — the router rule that assigned the tier, and the named human who signed off. Inspectability is a lookup of *who decided*, not an interpretation of a model's feature attribution.

### Failure modes

- **Batch rubber-stamping (my catastrophic one, and the price of keeping the human).** A reviewer signs off a 200-item digest without reading; a real incident hidden in it is acted on late or dismissed. This is the fatigue hazard reappearing inside the batch. Layered defense: bounded batch size (overflow escalates to T1, never grows unbounded); forced-sample mandatory-rationale items; dwell-time instrumentation that flags near-zero-dwell sessions; blast-radius/recurrence escalation *out* of the batch before review; and the hard rule that only owner-classified, blast-bounded classes are eligible for T2 at all, so the residual cost of a rubber-stamp is bounded by the same tier tolerance. **Honest limit:** if the *actionable* volume alone exceeds capacity, no attention-routing fixes it — that is a staffing/architecture problem, and I name it rather than pretend batching absorbs it.
- **Mis-routing a real incident downward.** The router (via a wrong advisory suggestion or stale catalog) sends a real incident to T1/T2. Unlike suppression, the human still sees it — just late. The damage is bounded by the tier's latency tolerance; the routing-quality monitor catches the class systematically; blast-radius escalation catches the acute case mid-window. This is a *latency defect to tune*, not a silent drop.
- **Automation bias.** Reviewers defer to the advisory suggestion and stop thinking — the advisory becomes a de facto decision-maker despite holding no authority. Mitigation: the router floors are human-set policy the advisory can never override; the bundle presents *evidence and rationale*, and periodically withholds the suggested class on sampled items to keep judgment live; dwell-time and agreement-rate monitoring flag reviewers who never diverge from the suggestion.
- **Catalog error.** A top-tier service mis-tiered downward escapes the T0 floor. Same mitigation as proposal 2: verification pass is a blocking prerequisite; tier assignment is a privileged audited change.
- **Confirmation-invisible incident (T1).** A degradation that self-clears within the window and never re-fires is recorded as auto-resolved and never paged. This is the ceiling on the T1 window; it is why window length is owner-set within SLA and why blast-radius floors exclude anything consequential from T1. Weaker than the automated approaches' version of this failure only in that the human never saw it — so I keep T1 windows short and blast-bounded.
- **Confirmed-incident feed outage.** Routing-quality monitor goes blind. Fail-safe: I do *not* need to suspend routing (nothing is being withheld from a human), but I raise a monitoring-degraded alert and tighten toward T0 for newly-classified low-risk routing until the feed recovers.
- **Advisory model wrong at scale.** Because it holds no authority, a broadly wrong model produces *bad routing*, i.e. worse interrupt economy — never a bad decision. Detected by routing-quality + dwell-time; corrected by retuning without any safety cutover.

### Operational complexity

I own this dimension; here is the honest accounting.

**Lighter than proposal 1's ML system on the safety-critical axis.** No shadow-then-cutover lifecycle, no per-service statistical cutover gate, no "≈ 600 confirmed incidents with zero misses" power problem, no safety-critical exclusion set. The advisory model can go live immediately because its worst error is routing latency, not a silent drop; it is tuned continuously against the routing-quality monitor rather than gated behind a proof.

**Lighter than proposal 2 on the merge bar.** A routing rule's worst case is a bounded delay, so its merge test is "does it keep blast radius within the tier's latency tolerance," not proposal 2's categorical "prove it never withholds any confirmed incident." Backtesting is still useful for tuning, but a routing rule failing the backtest is a latency defect, not an admissibility failure.

**What I add that the others do not** — and this is real, ongoing, *human-process* complexity, not ML complexity:
- The **scheduled-review-obligation machinery**: reviewer rostering, cadence, SLA tracking, completion verification, and non-completion escalation. This is a standing operational process, not a one-time build.
- **Batch-fatigue instrumentation**: dwell-time, agreement-rate, forced-sampling, batch-size governance. Without it the T2 tier silently reproduces the original problem.
- **Advisory-model + router config** under the shared change process (2–5 day latency), plus the routing-quality monitor and the confirmed-incident feed integration.

**Reviewer-capacity accounting (honest, per the framing's insistence).** I do **not** free raw capacity — I reshape it. Total human-minutes may be roughly unchanged; what changes is their *composition*: ~40 push-interrupts collapse to a handful of T0/T1 pages plus one or two batched sessions. The fatigue mechanism the framing names (interrupt overload → distrust → missed real page) is broken by cutting interrupts and per-decision cost even when headcount is fixed. For high-frequency structured noise, batching amortizes review well; for long-tail one-offs, batching is not worth the overhead and those keep paging at T1 — the intended safe outcome. Where I relieve *less* load than suppression, I accept that consciously: it is the velocity cost of the categorically safer failure mode.

**Dependency posture — the lightest of the three on the safety-critical path.** For *safety* I depend on neither the framing's outcome instrumentation nor the confirmed-incident feed — only on evidence extraction + a verified catalog to route. I use the outcome instrumentation and confirmed-incident feed for *evaluation and tuning* (did fatigue actually drop; is any confirmed incident mis-routed), not to make the design safe. Both prior proposals block their safety on the confirmed-incident feed; I do not.

### Security implications

- **The router is a bypass-of-*urgency* control, not a bypass-of-*human* control.** An actor can at worst shape an alert to be routed to a slower tier — delaying a human, never eliminating one. This is a materially smaller attack surface than either automated approach, where shaping evidence can skip the human entirely. Still, routing-down predicates must depend only on forgery-resistant, server-measured evidence (measured blast radius, downstream health, correlated deploys), never self-asserted metadata; and the T0 floors sit in policy above the advisory so the highest-value paths cannot be reached by evidence-shaping at all.
- **The advisory model is low-privilege by construction.** It holds no authority, so poisoning it degrades routing, not decisions — poisoning cannot grant an approval, because only a human grants approval. This removes the "privileged training-data asset with gate-equivalent authority" that both prior proposals must guard. The training set and model still merit integrity controls (a systematically biased advisory drives systematic mis-routing and automation bias), but they are not gate-equivalent secrets.
- **Human sign-off is the security anchor, and it is preserved.** Every decision carries a named accountable human. This is the strongest form of "inspectable after the fact by the security team": the audit answers *who decided* with a person, not a model attribution or a rule id. It also means I do **not** need to build the novel withholding-audit trail the framing flags as a hard prerequisite ("a suppression audit trail does not exist today") — because nothing is withheld from a human, the existing human-decision audit path carries the load.
- **The new privileged asset is the routing config + the digest-obligation roster**, not a suppression ruleset. Compromising them delays classes and can misroute escalation, so they need two-party review and access control — but a compromise buys *delay bounded by tier SLA and caught by the routing-quality monitor*, not indefinite silent suppression. Compare proposal 2's own concession that "one bad or malicious withhold rule silently suppresses an entire class indefinitely" — my worst case is strictly weaker.
- **Fail-safe posture.** Every gap resolves *upward*: incomplete evidence, OOD, out-of-catalog, blast-radius change, expired routing rule, feed outage, or unmet review SLA → escalate toward T0. The secure default is to interrupt a human sooner.

### Implementation constraints

- **Catalog verification is a blocking prerequisite for tier routing.** Until the catalog is verified authoritative, the router runs restricted: T0-dominant, with T1/T2 permitted *only* for explicit, owner-authored, blast-bounded classes. Same posture as proposal 2's restricted mode.
- **The advisory holds no authority — this is a hard invariant.** The router's tier floors are human-set policy; no model output may route below a floor. Any change that lets the model override a floor is out of scope for this approach.
- **Every non-immediate tier is a named scheduled obligation with escalation.** A T1/T2 channel without an owning reviewer, an SLA, and non-completion escalation may not ship. This is how I resolve the framing's open async-watcher question; I do not leave it open.
- **Opt-in, never opt-out.** No decision is approved by a human's silence. `no-response` is never `approved`; it escalates. This closes the contaminated "no-response = safe" path the framing warns of.
- **Per-item sign-off and audit retention are non-negotiable** for every decision at every tier, including coalesced T1 groups and each T2 item.
- **Change latency applies to router config and the advisory model** (2–5 business days); routing tolerances are set to absorb this — the router should not need hourly retuning, and if it does that signals a catalog/definition problem, not a latency problem.
- **Batch-fatigue instrumentation must ship with T2, not after.** T2 without dwell-time, forced sampling, and batch-size governance recreates the original fatigue inside the digest and is not admissible.

### Alternatives considered

- **Advisory-only (attach evidence, keep all 40 interrupts).** Rejected. It lowers per-decision cost but not interrupt count, and interrupt count and trust erosion are the dominant fatigue drivers. Evidence without routing leaves the "40 pages, 6 actionable" interrupt storm intact. The task's "re-engineer the attention" requires reshaping *when and how*, not only *with what*.
- **Default-approve-with-a-window (opt-out human).** Rejected outright. A window in which silence becomes approval *is* automated approval with a human fig leaf — it silently drops whatever a sleeping/overloaded engineer doesn't veto in time, which is precisely the contaminated `no-response` path the framing calls out. My T1 window is the inverse: silence within the window means *nothing is approved*, and persistence *pages* — default-page, never default-approve.
- **Pure async dashboard (pull, no obligation).** Rejected — this is the framing's unresolved "who watches the async channel." I replace it with a scheduled obligation + escalation so non-review is itself an alert.
- **Batch everything, including top-tier.** Rejected — violates the T0 floor and Track A.
- **Let the advisory model set the interrupt tier autonomously.** Rejected — it makes the model a de facto decision-maker, reintroducing the inspectability/automation-bias problems and the very authority I removed. Floors stay human-set policy.
- **A single global reviewer for all batches.** Rejected — it strips domain context and concentrates rubber-stamp pressure. Batches route to the owning service team, with a platform aggregator only for genuinely cross-cutting classes.
- **Interpretable-model mandate for the advisory (as proposal 1 requires for its classifier).** Rejected as unnecessary *for the model* — since it holds no authority, its admissibility bar is lower; I require a human-readable rationale for automation-bias reasons, not model interpretability for suppression-inspectability reasons.
- **Skip the confirmed-incident feed.** Rejected — I need it as the routing-quality (latency) monitor, though only for tuning, not safety.
- **Full ML shadow-then-cutover for the advisory.** Rejected — a model earns a shadow phase only when it will *hold authority*. Mine never does; it goes live immediately and is tuned continuously.

### Disagreements with earlier proposals

- **Both proposals automate the decision; I reject the premise.** Proposal 1 auto-approves ("withheld from the page"); proposal 2 auto-withholds ("withheld means no human"). Both concede they cannot eliminate the silent drop — "never driven to zero for novel incident shapes" and "will **not** save the specific incident that slipped." Under priority 1 (safety, never trade away detection), I refuse *any* silent-drop risk and accept bounded latency instead. My failure mode is a real alert seen late; theirs is a real alert seen never. That is the whole disagreement, and I resolve it in favor of the priority order.
- **Proposal 2 overrides the framing's accountability decision; I restore it.** It relocates accountability to a rule owner and concedes "one bad or malicious withhold rule silently suppresses an entire class indefinitely" with a blast radius that "grows." The framing decided "the on-call engineer is the accountable party." I keep per-decision human accountability; my worst config compromise buys *delay bounded by the tier SLA and caught by the routing-quality monitor*, never indefinite silent suppression. I do not accept the enlarged blast radius as a cost of doing business.
- **Proposal 1's "inspectable queue the engineer owns" is under-specified; I fix it.** It never says *owns how* or *watched when* — the framing's exact open question. I replace the vague queue with a named scheduled obligation, an SLA, per-item sign-off, and non-completion escalation. Proposal 2 was right to attack the passive queue; it was wrong to conclude the fix is to remove the human. The fix is to give the queue an accountable owner and an escalation, which is what a queue lacking those was missing.
- **Proposal 1's shadow-then-cutover apparatus is unnecessary at its root.** Its statistical-power problem and cutover gate exist only because the model holds authority. Demote the model to advisory and the entire lifecycle — shadow, cutover, exclusion set, 600-incident gate — dissolves, while the classifier's *evidence* value is fully retained. Proposal 1 built a safety cathedral around a model it did not need to give authority to.
- **I disagree with both on dependency framing.** Proposal 1 blocks safety on instrumentation *plus* a confirmed-incident feed; proposal 2 blocks safety on the confirmed-incident feed as its backtest oracle. I block *safety* on neither — only evidence extraction and a verified catalog — and use instrumentation and the confirmed-incident feed for evaluation and tuning. This makes my approach the only one whose safety does not wait on a data feed the framing has not confirmed is queryable.
- **Where I am honestly weaker, and will not hide it:** I relieve the least load (every decision still happens), and I carry a failure the automated approaches structurally avoid — batch rubber-stamping, the fatigue hazard reappearing inside the digest. I spend real, ongoing operational complexity (review obligations, batch-fatigue instrumentation, automation-bias guards) to contain it. I judge that price correct under a priority order that puts safety and reliability above velocity — but it *is* a price, and the compaction step should weigh it against the larger load relief the automated approaches buy with silent-drop risk.
