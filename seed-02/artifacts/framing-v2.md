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
