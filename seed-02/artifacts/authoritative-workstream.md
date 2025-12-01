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

The shared deployment pipeline pages a fixed-capacity on-call roster far beyond
its useful signal — the anchoring example is a shift of ~40 push interrupts
carrying ~6 actionable alerts. The hazard is not raw decision count but the
three drivers it produces: interrupt overload, high per-decision cost, and the
trust erosion that ends in a real production-affecting page being missed. The
organization's first priority forbids trading away detection of a real incident;
reviewer capacity does not scale with deployment volume; and every deployment
decision must remain auditable and inspectable after the fact by the security
team.

The desired outcome is a pipeline that re-engineers the *attention* around every
alert — how, when, in what grouping, and with what pre-attached evidence a human
is reached — while never letting a machine decide that a human is not reached at
all. Success is a measured fall in interrupt count and per-decision cost toward
the actionable floor, with no confirmed incident ever routed to a
seen-never outcome, delivered without new headcount and with full audit and
security inspectability preserved.

## Approach

The chosen direction is **differentiated human review driven by a deterministic
risk router with an advisory, non-authoritative evidence layer**. Every alert
still terminates in a named human sign-off; the router only chooses the *path* —
the latency tier at which that human is reached. The two automated alternatives
are absorbed and demoted: the supervised classifier becomes advisory evidence
with no authority, and the deterministic policy engine becomes the routing engine
applied to *latency tier* rather than to *suppression*. The load-bearing property
is that a routing error degrades to a bounded latency cost — a real alert seen at
a slower tier — and (subject to the P2 gate below) never to a silently dropped
incident.

What it does: it reshapes interrupt count (T1 coalescing), per-decision cost
(evidence briefs attached to every page), and grouping (visible-before-dismissal
coalescing, scheduled batched review). What it does *not* do: it does not free raw
reviewer capacity — total human-minutes are roughly unchanged; it does not remove
any human from any decision; it does not batch or delay top-tier alerts; and it
does not eliminate long-tail one-off noise, which continues to page at T1 as the
intended safe outcome.

The commitments that define it are hard invariants. **Opt-in, never opt-out**:
nothing is approved by silence; `no-response` escalates. **Advisory holds no
authority**: no model output routes below a human-set floor. **Every
non-immediate tier is a named, staffed, scheduled obligation with escalation**,
never a passive dashboard. **Fail-safe is always upward toward T0** for every
gap — incomplete evidence, out-of-catalog, OOD, blast-radius change, expired
rule, feed outage, or unmet review SLA. **Per-item sign-off and audit retention
are non-negotiable at every tier**, and — as made explicit by review — every
machine disposition (including T1 self-clear) emits an inspectable disposition
record.

Because the human always signs off, the design needs no cutover gate, no
statistical miss-rate proof, and no shadow-then-cutover lifecycle. But three
things the review surfaced are now first-class preconditions rather than
assumptions: fire-time server-measured blast radius must be proven computable
before relief is promised; T1 self-clear is gated on the confirmation-invisible
incident study; and a named threshold of owner-authored eligible classes must
exist before relief onset is declared.

## System primitives

- **Evidence object** — the content-addressed, retained feature vector extracted
  at fire time: origin service, tier, error class, server-measured blast-radius
  signals, downstream health, correlated deploys, and recurrence within window.
  It is the sole machine input. Its blast-radius fields must be forgery-resistant
  and server-measured; self-asserted metadata may never drive a downward route.

- **Attention tier** — the latency budget for reaching a human: `T0
  immediate-page`, `T1 coalesce-then-page(window)`, `T2 batched-review(SLA)`. Set
  by the attention policy, never by the advisory alone.

- **Attention policy (risk router)** — the deterministic, priority-ordered,
  *total* first-match policy engine mapping (tier floor + verified catalog +
  evidence object + advisory suggestion) → attention tier, with hard floors to T0
  the advisory can never override and a terminal default-page fall-through. Rules
  are versioned under the shared change process.

- **Review brief (pre-review evidence bundle)** — the advisory layer's output
  attached to an alert: suggested tier + class + confidence, matched
  policies/floors, blast-radius summary, correlated deploy, recurrence, matched
  runbook, and a plain-language rationale. It carries a suggestion, never an
  authority, and always emits a human-readable rationale to guard against
  automation bias.

- **Batch abstract** — the bounded summary of a T2 review session: its member
  items, per-item age against SLA, dwell-time instrumentation, forced-sample
  markers, and batch-size against the overflow bound. It exists so a reviewer
  and an auditor can see the shape of a session and so overflow escalates to T1
  rather than growing unbounded.

- **Disposition record** — the retained record of every alert outcome: action +
  firing router rule/version + evidence-object hash + attention tier + advisory
  suggestion shown + sign-off identity + timestamp. Two linked events (routing
  event and human decision event). For T1 self-clear, the disposition record
  names the automated rule and the independent condition-clear evidence in place
  of a human identity, so no disposition is invisible to audit.

- **Escalation record** — the tracked lifecycle of any obligation that is not met
  on time: T1 persistence past window, T2 item aging past SLA, blast-radius or
  recurrence change out of a batch, non-completion of a scheduled review. Each
  escalation is itself an alert with a named next contact.

- **Review-context record** — what was placed in front of the reviewer for a
  given decision: the review brief shown (or deliberately withheld for
  bias-sampling), the agreement/divergence outcome, and dwell-time. It is the
  substrate for automation-bias monitoring.

- **Attention ledger** — the retained instrumentation stream linking each alert
  through acted / auto-resolved / dismissed / no-response and joining it to the
  confirmed-incident feed. Used for evaluation, tuning, and the routing-quality
  monitor — never as a safety substrate.

## Implementation phases

### P0 — Instrumentation, catalog, and feasibility floor

**Entry condition:** current state; no prerequisites.
**What ships:** evidence-object extraction; the attention ledger
(alert→outcome instrumentation, the framing's first deliverable); catalog
verification of service criticality/tiers; a measured interrupt-count and
per-decision-cost **baseline**; and a **blast-radius feasibility spike** that
proves forgery-resistant, server-measured blast radius is computable at
alert-fire time. Reproduction of E1 on P0 real data against the measured baseline.
**Who owns it:** Platform / SRE, with the security team consulted on the audit
and inspectability schema.
**What it measures:** the true baseline interrupt count and dwell-time per
current tier; the fraction of alerts for which server-measured blast radius is
actually available at fire time. **Gate:** if fire-time blast radius is not
reliably computable, the router would collapse to all-T0 and deliver no relief —
so a stated coverage threshold on blast-radius availability is a blocking exit
condition for P0, on par with catalog verification.

### P1 — Advisory layer and router (restricted, T0-dominant)

**Entry condition:** P0 catalog verified and blast-radius coverage threshold met.
**What ships:** the advisory classifier and review brief; the risk router running
**restricted** — T0-dominant, with T1/T2 permitted only for explicit,
owner-authored, blast-bounded classes; T0 floors; disposition records and the
two-event audit path. The advisory can go live immediately because its worst
error is routing latency.
**Who owns it:** Platform / SRE owns the router, floors, catalog verification,
and the advisory model; service owners begin authoring eligible classes and
per-tier latency tolerances.
**What it measures:** review-brief rationale quality; advisory
agreement/divergence via the review-context record; routing latency; and the
count of owner-authored eligible classes accumulating toward the relief-onset
threshold.

### P2 — Coalescing and batched review with fatigue instrumentation

**Entry condition — two named gates:** (1) the confirmation-invisible incident
study is complete and its answer bounds T1 self-clear; T1 self-clear may not
enable until this study lands. (2) A stated **relief-onset threshold** of
owner-authored, staffed, blast-bounded classes exists, each with a named
reviewer, cadence, and SLA — so the system is not run indefinitely T0-dominant
(the original interrupt storm plus new machinery) with no defined point at which
relief begins.
**What ships:** T1 coalesce-then-page with grouping visible before dismissal and
blast-radius escalation mid-window; T2 scheduled batched review with per-item
sign-off, batch abstract, bounded batch size with overflow-to-T1, forced-sample
mandatory rationale, dwell-time instrumentation, and escalation records for
non-completion. **Batch-fatigue instrumentation must ship with T2, not after.**
**Who owns it:** service owners (eligibility, tolerances, review staffing);
Platform / SRE (coalescing logic, obligation scheduling and escalation).
**What it measures:** interrupt-count reduction against the P0 baseline;
rubber-stamp signals (dwell-time, agreement rate); seeded-incident detection rate
in T2 digests; cascade-collapse behavior in T1.

### P3 — Routing-quality monitor and steady-state tuning

**Entry condition:** T1/T2 in production for the relief-onset class set.
**What ships:** the routing-quality monitor reading the confirmed-incident feed
(any confirmed incident routed below T0 → routing defect); the **bounded
time-to-contain** loop — on a detected downward mis-route the affected class
**auto-tightens toward T0 immediately** as interim mitigation, mirroring the
feed-outage path, while the durable config fix clears the shared change process;
feed-outage degraded-mode handling; ongoing tuning.
**Who owns it:** Platform / SRE, accountable on routing-config and default-page
decisions; security team for periodic inspection.
**What it measures:** time-to-detect and time-to-contain for downward
mis-routes; residual seen-late incidents per class; feed availability.

## Success metrics

- **Interrupt-count reduction** — collected from the attention ledger as T0/T1
  push interrupts per shift versus the P0 baseline. Success: interrupt count
  falls toward the actionable count (~6 in the anchoring example) with no
  confirmed incident landing below T0.
- **Screening quality (not accuracy-for-speed)** — collected from
  review-context records and the confirmed-incident feed: anchored-denial rate
  and subsequent-rework rate, brief-assisted versus undifferentiated. Success:
  brief assistance raises correct denial and lowers rework, reproduced on P0 real
  data (E1's synthetic 66%/50% denial and 0%/33% rework are directional only and
  carry no statistical weight).
- **Seen-never rate** — collected by joining the confirmed-incident feed to the
  attention ledger. Success is absolute: zero confirmed incidents with no human
  disposition; any T1 self-clear of a later-confirmed incident is a defect.
- **Batch-fatigue containment** — collected from batch abstracts and
  review-context records: dwell-time distribution and seeded-incident detection
  rate in T2 sessions. Success: seeded incidents detected and escalated within
  SLA; dwell-time on real items non-trivial.
- **Automation-bias health** — collected from review-context records on
  brief-withheld samples. Success: reviewers diverge from injected wrong
  suggestions at a healthy rate; agreement does not approach 100%.
- **Time-to-contain a known downward mis-route** — collected from the
  routing-quality monitor and escalation records. Success: interim auto-tighten
  engages within the monitor's detection window; the class stops producing
  seen-late incidents before the config fix clears the 2–5 business-day change
  process.
- **Relief-onset progress** — collected as the count of owner-authored, staffed,
  blast-bounded classes versus the relief-onset threshold. Success: threshold met
  before the program is declared value-delivering.

## Operating bounds

- **F1 — Batch rubber-stamping (the self-inflicted catastrophic one).** The
  fatigue hazard reappears inside the T2 digest. **Bound in design:** bounded
  batch size with overflow-to-T1, forced-sample mandatory rationale, dwell-time
  instrumentation, blast-radius/recurrence escalation out of the batch, and
  eligibility restricted to owner-classified blast-bounded classes. **Honest
  limit:** if actionable volume alone exceeds capacity, no attention routing
  fixes it — that is a staffing/architecture problem, named not papered over.

- **F2 — Confirmation-invisible incident (T1 self-clear).** A degradation that
  self-clears within the window and never re-fires is recorded auto-resolved and
  never paged — the one genuine exception to the never-silently-dropped invariant.
  **Bound in design:** short, owner-set, blast-bounded windows. **Addition from
  the significant robustness finding:** T1 self-clear is now an explicit P2 entry
  gate — it may not enable until the confirmation-invisible incident study bounds
  it; the never-silently-dropped invariant is stated as conditional on this gate,
  not unconditional.

- **F3 — Mis-routing a real incident downward.** Via wrong advisory suggestion or
  stale catalog. **Bound in design:** the human still sees it (late); damage
  bounded by tier latency tolerance; blast-radius escalation catches the acute
  case mid-window; routing-quality monitor catches the class. **Addition from the
  significant operational finding:** a bounded time-to-contain — on detection the
  class auto-tightens toward T0 immediately, so the class does not keep producing
  seen-late incidents for the 2–5 business days the durable fix takes.

- **F4 — Blast radius not computable at fire time.** If server-measured blast
  radius is unavailable, every alert fails safe to T0 and the design collapses to
  all-T0, delivering no relief. **Addition from the significant feasibility
  finding:** the P0 blast-radius feasibility spike and a coverage threshold gate
  progression, so this is proven, not assumed.

- **F5 — Automation bias.** Reviewers defer to the advisory. **Bound in design:**
  human-set floors the advisory cannot override; periodic withholding of the
  suggested class on sampled items; dwell-time and agreement-rate monitoring via
  review-context records.

- **F6 — Catalog error.** A mis-tiered top-tier service escapes the T0 floor.
  **Bound in design:** blocking catalog verification (P0) and treating tier
  assignment as a privileged, audited change.

- **F7 — Confirmed-incident feed outage.** The routing-quality monitor goes
  blind. **Bound in design:** because nothing is withheld from a human, routing
  need not suspend; a monitoring-degraded alert is raised and newly-classified
  low-risk routing tightens toward T0 until the feed recovers.

- **F8 — Unbounded T0-dominant ramp (net-negative value).** The system runs
  restricted indefinitely — the original interrupt storm plus new machinery —
  with no point at which relief begins. **Addition from the significant
  implementation-risk finding:** the P2 relief-onset threshold gate defines when
  enough owner-authored classes exist for relief to start, and dependency
  sequencing (below) makes the organizational prerequisites explicit and
  critical-path.

## Security posture

The security model rests on three claims: human sign-off is the security anchor;
the audit answers *who decided* with a person; and the advisory model is
low-privilege because poisoning it degrades routing, not decisions — only a human
grants an approval. The router is a bypass-of-*urgency* control, not a
bypass-of-*human* control: an actor can at worst shape an alert to a slower tier,
delaying a human but never eliminating one. Downward-routing predicates therefore
depend only on forgery-resistant, server-measured evidence, and T0 floors sit
above the advisory so the highest-value paths cannot be reached by
evidence-shaping. New privileged assets are the routing config and the review
obligation roster (two-party review, access control); their compromise buys delay
bounded by tier SLA and caught by the routing-quality monitor, not indefinite
silent suppression. Fail-safe is always upward toward T0.

**Explicit gate added from the significant security finding:** the T1 self-clear
path disposes of an alert with no human, so the "who decided" lookup would return
no person and cross the org constraint that automated disposal be inspectable
after the fact. Therefore the per-item-sign-off invariant is amended: T1
auto-resolve is not exempt from audit. Every T1 self-clear **must emit a
disposition record** naming the firing router rule/version, the evidence-object
hash, and the independent condition-clear signal that closed it, and this
machine-disposition path must satisfy the security team's inspectability bar
**before T1 self-clear enables in P2**. The security team's specific
inspectability bar is a P0 stakeholder input (captured in dependencies), not left
unresolved at ship time.

## Dependencies

Stacked smallest-to-largest across phases; critical-path items flagged.

- **P0 — Platform team:** evidence-object extraction and the attention ledger.
  **[critical path]** Catalog verification. **[critical path]** Blast-radius
  feasibility spike proving fire-time server-measured blast radius. **Security
  team conversation:** the specific inspectability bar, including for the T1
  auto-resolve disposition record. **Stakeholder input:** the P0 measured
  baseline must exist before relief is claimed.

- **P1 — Platform team:** advisory model, review-brief generation, the risk
  router and T0 floors, disposition-record audit path. **New role / stakeholder
  work:** service owners begin authoring eligible classes and per-tier latency
  tolerances.

- **P2 — New roles (largest, critical path):** named T1/T2 reviewers with
  cadences, SLAs, and non-completion escalation contacts — a standing staffing
  commitment, not a one-time build. **[critical path]** Owner-authored eligible
  classes reaching the relief-onset threshold. **External / research
  dependency:** the confirmation-invisible incident study gating T1 self-clear.
  Batch-fatigue instrumentation must be built with T2.

- **P3 — Platform team:** routing-quality monitor, the interim auto-tighten
  time-to-contain loop, and feed-outage degraded mode. **External dependency:**
  a queryable confirmed-incident feed (still an assumption to verify — it is
  evaluation/tuning infrastructure, not on the safety path, so it does not block
  P0–P2 safety).

## Review findings and dispositions

| dimension | severity | disposition |
|---|---|---|
| robustness | significant | addressed — §Implementation phases (P2) & §Operating bounds (F2): T1 self-clear is now an explicit P2 entry gate contingent on the confirmation-invisible incident study, and the never-silently-dropped invariant is restated as conditional on that gate rather than unconditional. |
| simplicity | trivial | noted-and-dismissed — the review confirmed the machinery is enumerated, attributed to specific hazards, and traded explicitly against the demoted alternatives, so it is not an unstated burden; confirmed, it does not change delivery outcomes. |
| strategic alignment | trivial | noted-and-dismissed — the review confirmed the design maps correctly onto the priority order and honors the fixed-capacity constraint honestly; confirmed, the alignment argument is grounded and does not weaken delivery readiness. |
| technical feasibility | significant | addressed — §Implementation phases (P0), §Dependencies & §Operating bounds (F4): a P0 blast-radius feasibility spike with a coverage threshold is now a blocking exit condition, making fire-time server-measured blast radius a proven prerequisite rather than an assumption. |
| security | significant | addressed — §Security posture: the per-item-sign-off invariant is amended so T1 auto-resolve emits an inspectable disposition record (naming rule, evidence hash, and condition-clear signal) that must satisfy the security team's inspectability bar before T1 self-clear enables. |
| customer value | trivial | noted-and-dismissed — the review confirmed the value claim is bounded, not inflated by the synthetic E1 run, and gated on P0 real-data reproduction; confirmed, it does not weaken delivery readiness and is carried forward as the §Success metrics screening-quality gate. |
| operational impact | significant | addressed — §Operating bounds (F3), §Implementation phases (P3) & §Success metrics: a bounded time-to-contain is added whereby a detected downward mis-route auto-tightens the class toward T0 immediately, closing the up-to-a-week gap between fast detection and the slow config fix. |
| implementation risk | significant | addressed — §Implementation phases (P2), §Operating bounds (F8) & §Dependencies: a named relief-onset threshold of owner-authored, staffed, blast-bounded classes gates the declaration of relief, and the organizational prerequisites are sequenced and flagged critical-path so the system cannot run T0-dominant net-negative for an unbounded ramp. |
