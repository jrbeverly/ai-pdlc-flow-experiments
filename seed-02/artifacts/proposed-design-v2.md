---
state: stale
superseded_by: authoritative-workstream
generation: 4
supersedes: proposed-design-v1
derived_from:
  - proposed-design-v1
  - evidence-e1
confidence: 0.68
---

# Proposed Design v2

## Amendments from v1

- **Unresolved questions for experimentation (core value-proposition / A5 entry).**
  E1's entry moves from *open* to *partially answered*: a mock replay
  (`scripts/run-experiment.sh`, artifact `evidence-e1`) matched the success
  signal — brief-assisted review showed a higher anchored-denial rate (66% vs.
  50%) and zero subsequent rework (vs. 33%) at materially lower review time
  (7.0 vs. 18.7 min). Why the evidence justifies it: the run tested the
  screening-quality half of A5 (that attention quality serves screening
  quality, not merely speed) and produced a directional positive rather than
  the accuracy-for-speed trade the failure signal named. The entry is not
  closed because the data is synthetic and carries no statistical weight; the
  next experiment is the same test reproduced on P0 real data.

- **Confidence.** The claim that A5 is *unevidenced* is retired and replaced
  with "one weak, non-generalizable positive indicator, `evidence-e1`." Why the
  evidence justifies it: A5's screening-quality corner now has a first data
  point pointing the right way; but because the run is synthetic and does not
  touch the two largest uncertainties (unmeasured baseline, batch
  rubber-stamping), the numeric confidence is unchanged.

## Chosen design

The chosen direction is **differentiated human review with a deterministic risk
router and an advisory (non-authoritative) evidence layer**. No machine ever
decides that a human need not be interrupted. Instead, the pipeline
re-engineers the *attention* around every alert — how, when, in what grouping,
and with what pre-attached evidence a human is reached — while the *whether* of
interruption always terminates in a named human sign-off. The two automated
directions (a supervised classifier that auto-approves; a deterministic policy
that auto-withholds) are absorbed and demoted: the classifier becomes advisory
evidence with no authority, and the deterministic policy engine becomes the
routing engine, applied to *latency tier* rather than to *suppression*.

The load-bearing property is: **a routing error degrades to a bounded latency
cost — a real alert seen at a slower tier — never to a silently dropped
incident.**

### Approach

Suppression/dedup was defined in the framing as "a machine deciding a human
need not be interrupted; functionally an automated approval." This design
refuses that decision to a machine. It attacks the three *drivers* of the
fatigue hazard the framing names — interrupt count, per-decision cost, and
trust erosion — none of which equals raw decision count. The machine reshapes
those three; the human retains the decision on every alert.

The distinction the design rests on is **routing vs. suppression**. Suppression
decides a human is *never* interrupted (the machine owns the outcome). Routing
decides *how and when* a human is interrupted and *with what evidence* (the
human still owns the outcome). Because the human always signs off, the machine
never needs a cutover gate, a statistical miss-rate proof, a safety-critical
exclusion set, or a shadow-then-cutover lifecycle — and the framing's AI gate
("a model that cannot explain a specific suppression is likely inadmissible"),
which targets a model that *withholds*, does not bind an advisory that only
*suggests to a human who withholds nothing without signing off*.

Two hard commitments: **opt-in, never opt-out** — nothing is approved by a
human's silence, the default is always page/escalate; and **every non-immediate
channel is a named, scheduled obligation with escalation, never a passive
dashboard** — this closes the framing's open async-watcher question by
construction rather than inheriting it.

### System primitives

- **Evidence record** — the feature vector extracted at fire time (origin
  service, tier, error class, blast-radius signals, correlated deploys,
  downstream health, recurrence within window). Content-addressed and retained.
  Sole machine input.
- **Pre-review evidence bundle** — the advisory layer's output attached to an
  alert: suggested triage tier + class + confidence, matched policies/floors,
  blast-radius summary, correlated deploy, recurrence, matched runbook, and a
  plain-language rationale. It carries a suggestion, never an authority.
- **Advisory classifier** — a model mapping evidence → suggested tier/class. It
  holds no authority, so it need not be a mandatory-interpretable form; it must
  still emit a human-readable rationale to guard against automation bias.
- **Interrupt tier** — the latency budget for reaching a human: `T0
  immediate-page`, `T1 coalesce-then-page(window)`, `T2 batched-review(SLA)`.
  Set by policy, never by the model alone.
- **Risk router** — the deterministic, priority-ordered, *total* policy engine
  (adopted from the policy-replaces-approval direction) that maps (tier floor +
  verified catalog + evidence + advisory suggestion) → interrupt tier, with hard
  floors to T0 the advisory can never override; terminal fall-through is
  default-page.
- **Scheduled review obligation** — a named reviewer role, cadence, SLA, and
  completion tracking for T1/T2; non-completion is itself an escalating alert.
- **Named accountable sign-off** — the human identity attached to every
  decision (T0 ack, T1 group ack, each T2 item), preserving the framing's "the
  on-call engineer is the accountable party."
- **Decision / audit record** — action + firing router rule/version + evidence
  hash + interrupt tier + advisory suggestion shown + human sign-off identity +
  timestamp. Two linked, retained events: the routing event and the human
  decision event.
- **Confirmed-incident feed** — independently-confirmed incidents (tickets, SLO
  breaches, customer-impact). Used only as a **routing-quality (latency)
  monitor** and for tuning — never as a safety substrate.
- **Outcome instrumentation** — the framing's acted/auto-resolved/dismissed/
  no-response linkage. Used to *evaluate* fatigue reduction and tune routing,
  never as a safety substrate.

### Architecture

```
alert fires
   │
   ▼
[evidence extraction] ──► evidence record (content-addressed, retained)
   │
   ▼
[advisory layer] ─► pre-review evidence bundle (suggested tier+class+rationale)
   │                NO decision, NO withholding
   ▼
[risk router] — deterministic, total; advisory is an INPUT, never an authority
   │
   ├─ tier == top-tier ──────────────────────────► T0   (Track A floor)
   ├─ evidence incomplete / out-of-catalog / OOD ─► T0   (fail-safe UP)
   ├─ blast radius > tier tolerance ─────────────► T0
   ├─ confirmable, low blast ────────────────────► T1   coalesce-then-page(window)
   ├─ owner-classified low-risk, bounded blast ──► T2   batched-review(SLA)
   └─ no match ──────────────────────────────────► T0   (default-page)
   │
   ▼
delivery to a NAMED human at the routed tier, evidence bundle attached
   ├─ T0: immediate push page ──► human ack/act
   ├─ T1: window coalesces dupes into ONE page (grouping visible pre-dismiss);
   │       independent self-clear within window ─► auto-resolved + audit, no page;
   │       persistence past window ─► page ─► human ack/act
   └─ T2: appears in owner's scheduled review session; each item signed off
           individually; item aging past SLA OR blast-radius change ─► escalate
   │
   ▼
[decision] = action + router rule/version + evidence hash + tier
           + advisory shown + HUMAN sign-off identity + timestamp
   ├─► audit record (routing event + human decision event, both retained)
   ├─► outcome instrumentation  [evaluation only]
   ▼
[routing-quality monitor] ── reads confirmed-incident feed ──►
   any confirmed incident routed below T0 → routing defect + retune
   (bounded latency already incurred; NOT a silent drop)
```

Single-path per "no side channel." Every leaf terminates in a human sign-off;
the router chooses only the *path*. Fail-safe is always *up* toward T0. Router
rules and tier assignments are versioned under the shared change process.

### User workflows

- **On-call, T0 (critical / top-tier):** immediate page, first occurrence, no
  suppression, no batching, ever — Track A honored directly. What changes is the
  *cost* per page: the evidence bundle arrives with the page, so triage starts
  briefed instead of from a bare timestamp. Ack is the audit sign-off.
- **On-call, T1 (coalesce-then-page):** a burst of same-origin/same-error alerts
  within the window coalesces into one page whose body lists every member —
  grouping is visible *before* dismissal, honoring the framing's requirement.
  The engineer is accountable for the coalesced group. Independent self-clear
  within the window records auto-resolved (an independent condition-clear
  signal, never a dismissal); persistence pages.
- **On-call / service-team reviewer, T2 (scheduled batch review):** a scheduled
  obligation with a named owner, cadence, and owner-set SLA — not a dashboard.
  Non-completion past SLA pages the reviewer, then the escalation contact.
  Sign-off is **per item**, not per batch. Batch size is bounded (overflow
  escalates to T1, never grows unbounded); a random forced sample requires
  written rationale; dwell-time is instrumented as a rubber-stamp signal; any
  item whose blast radius or recurrence changes escalates out of the batch.
- **Service owner:** sets, per service, which classes may route to T1/T2 and the
  **latency tolerance** for each tier. This realizes the framing's "the
  authority belongs to the service owners" as a latency budget (how long a human
  decision may wait), not a miss rate (how often an incident may be dropped) —
  because nothing is dropped. Owners cannot route their own top-tier below T0.
- **Platform / SRE:** owns the router, the T0 floors, catalog verification, the
  digest-obligation scheduling/escalation, the advisory model, and the
  routing-quality monitor. Accountable on routing-config and default-page
  decisions.
- **Security team:** pulls any decision and reads two non-interpretive facts —
  the router rule that assigned the tier, and the named human who signed off.
  Inspectability is a lookup of *who decided*, not a model attribution.

### Failure modes

- **Batch rubber-stamping (the catastrophic one, and the price of keeping the
  human).** The fatigue hazard reappears inside the T2 digest — a reviewer
  signs off a large session unread. Layered defense: bounded batch size with
  overflow-to-T1; forced-sample mandatory rationale; dwell-time instrumentation;
  blast-radius/recurrence escalation out of the batch; and the eligibility rule
  that only owner-classified, blast-bounded classes reach T2 at all, so a
  rubber-stamp's residual cost is bounded by the tier tolerance. **Honest
  limit:** if *actionable* volume alone exceeds capacity, no attention-routing
  fixes it — that is a staffing/architecture problem, named not papered over.
- **Mis-routing a real incident downward.** Via a wrong advisory suggestion or
  stale catalog. The human still sees it, just late; damage is bounded by the
  tier latency tolerance; the routing-quality monitor catches the class
  systematically; blast-radius escalation catches the acute case mid-window. A
  latency defect to tune, not a silent drop.
- **Automation bias.** Reviewers defer to the advisory. Mitigation: floors are
  human-set policy the advisory cannot override; the bundle presents evidence +
  rationale and periodically withholds the suggested class on sampled items;
  dwell-time and agreement-rate monitoring flag reviewers who never diverge.
- **Confirmation-invisible incident (T1).** A degradation that self-clears
  within the window and never re-fires is recorded auto-resolved and never
  paged. This is the ceiling on the T1 window; it is why windows are short,
  owner-set within SLA, and blast-bounded.
- **Catalog error.** A mis-tiered top-tier service escapes the T0 floor.
  Mitigated by the blocking verification prerequisite and by treating tier
  assignment as a privileged, audited change.
- **Confirmed-incident feed outage.** The routing-quality monitor goes blind.
  Because nothing is withheld from a human, routing need not be suspended; a
  monitoring-degraded alert is raised and newly-classified low-risk routing
  tightens toward T0 until the feed recovers.

### Operational complexity

Lighter than the ML direction on the safety-critical axis (no
shadow-then-cutover lifecycle, no per-service statistical cutover gate, no
safety-critical exclusion set — the advisory can go live immediately because its
worst error is routing latency). Lighter than the deterministic-suppression
direction at the merge bar (a routing rule's merge test is "does it keep blast
radius within the tier's latency tolerance," not "prove it never withholds any
confirmed incident"). What this design *adds* is real, ongoing **human-process**
complexity: scheduled-review-obligation machinery (rostering, cadence, SLA
tracking, completion verification, non-completion escalation); batch-fatigue
instrumentation (dwell-time, agreement-rate, forced sampling, batch-size
governance); and advisory-model + router config under the shared change process
(2–5 business-day latency), plus the routing-quality monitor.

Reviewer-capacity accounting (honest): this design does **not** free raw
capacity — it reshapes it. Total human-minutes may be roughly unchanged; ~40
push-interrupts collapse to a handful of T0/T1 pages plus one or two batched
sessions. The fatigue mechanism (interrupt overload → distrust → missed real
page) is broken by cutting interrupt count and per-decision cost even with fixed
headcount. High-frequency structured noise batches well; long-tail one-offs stay
paging at T1 — the intended safe outcome.

### Security implications

- **The router is a bypass-of-*urgency* control, not a bypass-of-*human*
  control.** An actor can at worst shape an alert to a slower tier — delaying a
  human, never eliminating one; a materially smaller surface than either
  automated approach. Routing-down predicates must depend only on
  forgery-resistant, server-measured evidence (measured blast radius, downstream
  health, correlated deploys), never self-asserted metadata; T0 floors sit above
  the advisory so the highest-value paths cannot be reached by evidence-shaping.
- **The advisory model is low-privilege by construction.** Poisoning it degrades
  routing, not decisions — it cannot grant an approval, because only a human
  grants one. This removes the gate-equivalent privileged training-data asset
  the automated approaches must guard; the training set still merits integrity
  controls (systematic bias drives systematic mis-routing) but is not a
  gate-equivalent secret.
- **Human sign-off is the security anchor and is preserved.** The audit answers
  *who decided* with a person. Because nothing is withheld from a human, this
  design does **not** need to build the novel withholding-audit trail the
  framing flags as a hard prerequisite; the existing human-decision audit path
  carries the load, and the framing's flagged gap ("a suppression audit trail
  does not exist today") is sidestepped rather than filled.
- **New privileged assets** are the routing config and the digest-obligation
  roster (two-party review, access control) — but their compromise buys *delay
  bounded by tier SLA and caught by the routing-quality monitor*, not indefinite
  silent suppression.
- **Fail-safe posture:** every gap — incomplete evidence, OOD, out-of-catalog,
  blast-radius change, expired rule, feed outage, unmet review SLA — resolves
  *upward* toward T0.

### Implementation constraints

- **Catalog verification is a blocking prerequisite for tier routing.** Until
  the catalog is verified authoritative, the router runs restricted: T0-dominant,
  with T1/T2 permitted only for explicit, owner-authored, blast-bounded classes.
- **The advisory holds no authority — a hard invariant.** No model output may
  route below a human-set floor.
- **Every non-immediate tier is a named scheduled obligation with escalation.** A
  T1/T2 channel without an owning reviewer, an SLA, and non-completion escalation
  may not ship.
- **Opt-in, never opt-out.** No decision is approved by silence; `no-response`
  escalates, never approves.
- **Per-item sign-off and audit retention are non-negotiable** at every tier,
  including coalesced T1 groups and each T2 item.
- **Batch-fatigue instrumentation must ship with T2, not after.** T2 without
  dwell-time, forced sampling, and batch-size governance recreates the original
  fatigue and is not admissible.
- **Safety-path dependencies are the lightest of the three:** only evidence
  extraction and a verified catalog. The outcome instrumentation and the
  confirmed-incident feed are needed for *evaluation and tuning*, not safety —
  so the design's safety does not block on a data feed the framing has not
  confirmed is queryable. Confirmed-incident-feed queryability remains an
  assumption to verify, but it is not safety-blocking.

## Why this design was chosen

Against the organization's priority order (1 safety/security, 2
reliability/operability, 3 velocity, 4 convenience) and the framing's hard
constraint that detection of a real production-affecting incident is never
traded away, the decisive fact is that **both automated directions concede an
irreducible silent-drop**: classify-and-auto-approve admits the failure "is
never driven to zero for novel incident shapes," and policy-replaces-approval
admits its conformance backstop "will not save the specific incident that
slipped." Priority 1 does not say *minimize* silent drops; it says never trade
away detection. A design that structurally converts the worst failure from
*seen never* to *seen late* is the only one that honors priority 1 as written.
The cost of that conversion is paid entirely in priority 3 (velocity) —
smaller load relief — which is exactly the sacrifice the priority order
prescribes.

It wins over classify-and-auto-approve because that proposal built an entire ML
safety apparatus — shadow phase, per-service statistical cutover gate,
exclusion set, permanent hold-out sampling, a privileged training-data asset —
whose whole purpose is to bound a silent-drop risk this design refuses to take.
That proposal's own analysis concedes its statistical gate "may be statistically
unreachable" (≈600 zero-miss confirmed incidents for a 0.5% bound) and that the
constructive exclusion set, not the statistics, carries the safety weight.
Demoting the classifier to advisory retains its full *evidence* value (briefed
triage, suggested tier) while dissolving the shadow/cutover/gate lifecycle and
its gate-equivalent training-data attack surface.

It wins over policy-replaces-approval because that proposal overrides a decision
the framing explicitly made — "the on-call engineer is the accountable party" —
relocating accountability to a rule owner and accepting, in its own words, that
"one bad or malicious withhold rule silently suppresses an entire class
indefinitely" with a blast radius that "grows." Under priority 1 an
indefinite-silent-suppression failure mode is not acceptable when a
bounded-latency alternative exists. This design keeps the deterministic policy
engine's rigor — it *is* the risk router — but points it at latency tier
instead of suppression, so its worst compromise buys delay bounded by tier SLA
and caught by the routing-quality monitor.

Finally, it best fits the framing's largest stated uncertainty: the noise
baseline is unmeasured and the one available signal (dismissals/non-responses)
is contaminated by the very fatigue under study. Both automated designs must
place a data feed on the safety path; this design places its safety on only
evidence extraction and a verified catalog, and uses the contaminated
instrumentation and the unconfirmed incident feed for evaluation only — the
one direction whose safety does not rest on a number the framing cannot yet
trust.

## Trade-offs accepted

- **The organization accepts relieving the least raw reviewer load.** Total
  human-minutes are roughly unchanged; no headcount capacity is freed. This is a
  consequence the org takes on deliberately, not a risk to monitor: it is the
  velocity price of a failure mode that is bounded latency rather than silent
  drop. Where suppression would have removed a human decision, this design
  reshapes it instead.
- **The organization accepts standing human-process operational complexity** —
  reviewer rostering, SLA tracking, non-completion escalation, and batch-fatigue
  instrumentation — as permanent operating cost, in place of the standing ML or
  policy-maintenance cost of the automated directions.
- **The organization accepts that long-tail one-off noise keeps paging.**
  Batching is not worth a rule/tier for one-offs, so they continue to interrupt
  at T1. This is the intended safe outcome, and it means the "40 pages, 6
  actionable" problem is improved but not eliminated for unstructured noise.
- **The organization accepts a new, self-inflicted failure surface —
  batch rubber-stamping** — as the price of never removing the human. The design
  spends real instrumentation to contain it, but the fatigue hazard is relocated
  into the digest, not abolished.

## Designs considered and not chosen

- **Classify-and-auto-approve (supervised classifier that auto-approves noise,
  shadow-then-cutover, per-service statistical miss-rate gate + exclusion
  set).** Not chosen: it accepts an irreducible silent-drop for novel incident
  shapes, which priority 1 forbids when a bounded-latency alternative exists; its
  statistical gate may be unreachable for genuinely rare production-down classes,
  meaning the rarest (highest-stakes) services may never earn cutover; and it
  introduces a gate-equivalent privileged training-data asset and a
  contaminated-label death-spiral surface. Its genuine value — evidence-rich
  triage suggestions — is preserved here by demoting the model to advisory.
- **Policy-replaces-approval (deterministic rules that auto-withhold with no
  human watcher, merge-time backtest + runtime conformance monitor).** Not
  chosen as a *suppression* mechanism: it overrides the framing's explicit
  accountability decision, and its own conformance backstop cannot save the
  specific slipped incident, leaving an indefinite-silent-suppression failure
  mode. Its determinism and rigor are retained — the risk router *is* a
  deterministic, total, first-match policy engine — but applied to latency tier,
  where a bad rule costs bounded delay rather than silent suppression.
- **Sub-alternatives within the chosen direction, considered and rejected:**
  advisory-only (keep all 40 interrupts) — rejected, leaves the interrupt storm
  intact; default-approve-with-a-window (opt-out) — rejected as automated
  approval with a human fig leaf, exactly the contaminated `no-response` path;
  pure async dashboard with no obligation — rejected as the framing's unresolved
  unwatched channel; letting the advisory set the tier autonomously — rejected,
  reinstates a de facto decision-maker and the inspectability problem.

## Unresolved questions for experimentation

- **Does routing actually break the fatigue hazard against the measured
  baseline? (E1 — the A5 core claim: does attention quality serve screening
  quality, not merely speed?)** — **partially answered; a weak positive first
  indicator, not settled.**
  Hypothesis: converting the ~40-page shift into a few T0/T1 pages plus one or
  two T2 sessions reduces interrupt count and per-decision cost enough to restore
  trust in pages — and the attached brief improves screening quality rather than
  trading accuracy for speed.
  Experiment: build the alert→outcome instrumentation (the framing's first
  deliverable), then replay one to two weeks of historical alerts through a
  simulated router and measure resulting interrupt count and dwell-time per tier.
  Success signal: T0/T1 interrupt count falls to near the actionable count (~6)
  without any confirmed incident landing below T0. Failure signal: interrupt
  count barely moves, or confirmed incidents routinely route below T0.
  **Signal to date (mock, `evidence-e1`):** a synthetic-data proxy testing the
  screening-quality half of A5 — brief-assisted vs. undifferentiated review —
  matched its success signal: anchored-denial rate 66% (brief) vs. 50%
  (no-brief), rework 0% vs. 33%, review time 7.0 vs. 18.7 min. This is a **weak
  positive**: it points the right way (attention quality helped detection, not
  just speed) but rests on twelve hardcoded records with no statistical weight
  and does not touch the interrupt-count-against-measured-baseline half of the
  question. **What it means:** A5's screening-quality corner moves from open to
  partially answered; the question overall stays open. **Next experiment:**
  reproduce E1 on P0 real data against the measured baseline before any design
  decision rests on it — same test, real records, both halves measured.
- **Does the T2 digest recreate the fatigue it is meant to cure
  (rubber-stamping)?**
  Hypothesis: bounded batch size + forced-sample rationale + dwell-time flags let
  reviewers reliably catch a real incident seeded into a batch.
  Experiment: construct historical T2 digests, seed a known past confirmed
  incident into a session, and run live review sessions with on-call engineers.
  Success signal: seeded incidents are detected and escalated within SLA;
  dwell-time on real items is non-trivial. Failure signal: seeded incidents pass
  sign-off, or dwell-time is uniformly near zero.
- **Does T1 coalescing collapse multi-component cascades into one page?** (The
  framing flagged this hazard for the same-origin/same-error/5-minute grouping
  intuition.)
  Hypothesis: coalescing same-origin/same-error alerts within a short window does
  not merge distinct cascading failures into a single dismissible group.
  Experiment: replay historical multi-component cascade incidents through the
  coalescing logic. Success signal: cascades surface as distinct groups or
  escalate via blast-radius change. Failure signal: a multi-component cascade
  collapses into one page a reviewer could dismiss as a single event.
- **How common are confirmation-invisible incidents (only trace is the alert
  itself)?** — this bounds how aggressive T1 self-clear may be.
  Hypothesis: real production-affecting incidents nearly always leave an
  independent trace (ticket, SLO breach, customer impact) beyond the alert.
  Experiment: audit historical confirmed incidents for independent traces
  correlated to their originating alerts. Success signal: near all confirmed
  incidents have an independent trace, so the routing-quality monitor is
  effective and T1 self-clear is low-risk. Failure signal: a material fraction
  are alert-only, tightening or eliminating the T1 self-clear allowance.
- **Does the advisory suggestion induce automation bias that degrades review
  quality?**
  Hypothesis: showing the suggested class does not make reviewers stop
  independently judging.
  Experiment: A/B the review session with and without the suggested class shown
  (rationale-only), measuring divergence rate and detection of seeded
  mis-suggestions. Success signal: reviewers diverge from wrong suggestions at a
  healthy rate. Failure signal: agreement approaches 100% including on injected
  wrong suggestions.

(Questions only a stakeholder can answer are held in the proposal's constraints,
not here: the per-tier latency tolerances and eligibility classes — owner-set;
the security team's specific inspectability bar; and the criticality-catalog
verification, which is a blocking prerequisite task rather than an experiment.)

## Confidence

0.68 — unchanged from v1. The direction is well-aligned with the priority order,
honors Track A and the accountability, audit, and grouping-visibility decisions
of the framing, and resolves the framing's open async-watcher question by
construction. The A5 assumption — that attention quality actually serves
screening quality — is **no longer wholly unevidenced**: the E1 mock experiment
(`evidence-e1`) matched its success signal, with brief-assisted review showing a
higher anchored-denial rate and zero rework at materially lower review time.
This is why the confidence did **not** rise: the run is synthetic (twelve
hardcoded records, metrics by awk, no LLM), so it carries no statistical weight
and cannot generalize; it exercises the experimentation *loop* and gives a
directional first indicator, nothing more. It also leaves untouched the two
largest sources of uncertainty — the core value proposition remains unproven
against an *unmeasured* baseline (E1's interrupt-count half), and the
self-inflicted batch-rubber-stamping hazard could still reproduce the fatigue it
targets inside the T2 digest. Both remain addressable only after the framing's
instrumentation exists and E1 is reproduced on P0 real data, which is why that
reproduction and the rubber-stamping test are the gating experiments for the
next stage.
