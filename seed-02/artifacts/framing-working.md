---
state: stale
superseded_by: framing-v2
derived_from:
  - raw-thought
---

# Framing working artifact

Working material for Framing v2. Messy by design: entries may contradict the
seed and each other. The compaction step distills this into the authoritative
framing.

## Seed

---
state: working
generation: 1
---

# On-call alert fatigue — loose notes

Our on-call rotation is unsustainable. Engineers are getting paged multiple
times per shift for things that either resolve themselves automatically or
aren't real incidents. The person on call last week received over forty alerts
across a Friday evening; maybe six required any action at all.

The problem is that we treat "a service health check failed once" the same as
"the payment processor is down." Both generate an immediate interruption to
whoever is on call.

I suspect a large proportion of alert volume is noise — transient conditions
the platform recovers from on its own, or spikes that stay within acceptable
operational bounds. But I don't have numbers to prove this because we have
never measured which alerts actually lead to engineer actions versus which ones
auto-resolve or get dismissed without any response.

What I want: engineers paged for real incidents and not for noise, without us
silently dropping real ones. The "without dropping real ones" part is
non-negotiable — I would rather have the current situation than miss a
production-down event.

Ideas floating around:

- Threshold-based suppression: only alert if the condition persists for N
  minutes rather than triggering on the first occurrence
- Alert deduplication: collapse repeated alerts about the same probable root
  cause into a single page instead of a cascade
- Severity tiering: classify alerts as critical/warning/info and only page
  on-call for critical; the rest go to dashboards or async channels
- AI-based anomaly detection: replace static thresholds with learned baselines
  that adapt to service behavior over time
- Better runbooks: not a reduction in volume, but faster triage — engineers
  know within minutes whether a page requires action

Things I am not sure about:

- Whether the problem is too many alerts or too many ambiguous alerts. Cutting
  volume without improving signal quality may just leave us with fewer but
  equally confusing pages.
- Whether our static thresholds are calibrated at all. Some were set at
  service deployment years ago and may never have been revisited.
- Whether routing is correct. Some alerts might be going to the wrong team or
  the wrong tier of on-call, compounding the noise.
- Whether any of the above requires changing the alerting infrastructure, or
  whether it is a configuration and process problem that the current tooling
  can solve.

Open question: do we have enough data on which alerts lead to engineer actions
to know the actual noise ratio? If we cannot measure that baseline, we cannot
evaluate whether any change made things better or worse.

## Agent entry — outcome-and-users

## Analysis

The seed's real subject is not "too many alerts" — it is an unmeasured signal-to-noise ratio. The author states this himself: "we have never measured which alerts actually lead to engineer actions versus which ones auto-resolve or get dismissed." That admission reframes the whole thing. The primary desired outcome here is not fewer pages; it is **a measured baseline of alert actionability**, because without it no later change can be evaluated as better or worse. Everything else the seed lists (suppression, dedup, tiering, anomaly detection) is a solution proposal that cannot be judged until that baseline exists.

The success condition the author actually cares about is stated crisply and asymmetrically: "engineers paged for real incidents and not for noise, without us silently dropping real ones," and "I would rather have the current situation than miss a production-down event." This is a clear, correctly-ordered outcome. Missing a real incident is a reliability-and-operability failure (priority 2); being over-paged is a developer-velocity and convenience cost (priorities 3–4). The seed's non-negotiable maps cleanly onto the priority order: never trade away detection of a real production-down event to buy quieter shifts. That constraint should govern every downstream trade-off.

**Affected users**, in order of the stakes they carry:

- **On-call engineers** — the population whose sustainability is failing now. The seed anchors on them ("over forty alerts... maybe six required any action").
- **The users of the services being monitored** — invisible in the seed but the highest-priority party. A dropped real alert means degraded or down service for customers. Any framing that measures success only by engineer experience omits the people the alerts exist to protect.
- **Teams that own the alerting rules** — the seed hints some thresholds "were set at service deployment years ago." Whoever owns those rules is affected by, and accountable for, recalibration.
- **Incident responders / adjacent teams** — the routing question ("going to the wrong team or the wrong tier") implies affected parties beyond the single on-call person.

On **priorities**: the seed already sorts its own ideas well. "Better runbooks" is explicitly flagged as not reducing volume but improving triage speed — that is a convenience/velocity improvement, and honestly labeled as such. The riskier proposals (threshold suppression, AI anomaly detection) all introduce a mechanism that can *withhold* a page, which directly threatens the non-negotiable. Under the priority order, any suppression mechanism must be evaluated first for its false-negative behavior (could it drop a real one?) before its noise-reduction benefit is even considered.

## Disagreements and tensions

- **The framing conflates two outcomes the author himself separates.** He asks "whether the problem is too many alerts or too many ambiguous alerts," then notes "cutting volume without improving signal quality may just leave us with fewer but equally confusing pages." I'll go further than the seed does: reducing *volume* is a convenience outcome; improving *signal quality* (each page is trustworthy and actionable) is a reliability-and-operability outcome. These rank differently in the priority order, and treating them as one goal will produce changes that optimize the lower-priority one. The desired outcome should be stated as signal quality, with volume reduction as a likely by-product — not the reverse.

- **Every suppression-flavored idea trades against the stated non-negotiable, and the seed does not confront this.** "Only alert if the condition persists for N minutes" *is* a deliberate delay in detecting a real incident that happens to resolve-then-recur, or one that is catastrophic within minute one (a payment processor going down does not become less urgent by waiting N minutes). Dedup that collapses "the same probable root cause" can collapse two genuinely distinct incidents if the root-cause guess is wrong. These are not neutral noise filters; they are detection-sensitivity reductions. Under priority order, they cannot be adopted on velocity grounds alone.

- **The success criterion is measurable in principle but has no defined threshold.** "Paged for real incidents and not for noise" needs a target: what false-negative rate is acceptable (the author implies zero for production-down), and what false-positive rate counts as "fixed"? Without both numbers the outcome is untestable, which contradicts the author's own closing insight that an unmeasurable change cannot be evaluated.

- **The seed under-weights the customer/service-user as an affected party.** The entire problem is framed through engineer experience. But the priority order puts safety and reliability above developer velocity precisely because the alerts protect someone downstream. A framing that measures only "engineer interruptions" risks optimizing engineer comfort at the cost of the people the on-call rotation exists to serve. The affected-users set must include them explicitly, or the trade-offs will be scored wrong.

## Questions

- What is the acceptable false-negative rate for a real production-affecting incident — is the author's "zero missed production-down events" literal, or is there a tolerated detection delay?
- For the top-severity services (e.g. the payment processor named in the seed), is *any* suppression or delay acceptable, or must those page immediately on first occurrence regardless of the general policy?
- Do we already retain enough historical data (alert fired → engineer action / auto-resolve / dismissed) to reconstruct the noise ratio, or does measuring the baseline itself require new instrumentation first?
- Who owns the alerting rules today, and do they have the authority and capacity to recalibrate thresholds — i.e., is this a config/process problem within one team's control or a cross-team one?
- Is on-call engineer sustainability the success measure, service reliability the success measure, or both — and if both, which governs when a change improves one at the expense of the other?
- What counts as "the same probable root cause" for deduplication purposes, and who is accountable if that grouping collapses two distinct incidents into one page?

## Agent entry — risk-and-constraints

## Analysis

My remit is risks, constraints, dependencies, and assumptions — so I read this seed against the organizational constraints the pipeline is told to honor, even though those constraints are written in deployment/approval language. They transfer cleanly: a *suppression* here is functionally an *automated approval* (a machine deciding a human need not be involved), an alert-config change is a *change* through the shared pipeline, and on-call engineers are the fixed-capacity *reviewers*. Once you map it that way, several of the seed's ideas collide with non-negotiable constraints the seed never mentions.

**The binding constraints, applied:**

- *"Any automated approval must be inspectable after the fact by the security team"* and *"every deployment decision must remain auditable."* Every suppression, dedup-collapse, or "stays within bounds so don't page" decision is a machine deciding not to interrupt a human. Under these constraints that decision **must generate an audit record of what was withheld and why**. The seed proposes all three suppression mechanisms with no mention of recording what they suppress. This is the crux: the author's non-negotiable is *"without us silently dropping real ones,"* yet the proposed mechanisms are exactly what makes a drop *silent* — no record means you cannot later discover the miss. The constraint the org already has (auditability) is the direct answer to the author's fear, and the seed doesn't connect them.

- *"Reviewer capacity is fixed and does not scale with deployment volume."* On-call capacity is likewise fixed. This reframes the problem from "nice to tune" to structurally unsustainable, but it also constrains the solutions: *"the rest go to dashboards or async channels"* assumes someone watches those channels — that is still human capacity, merely relabeled and less accountable. Any option that shifts triage rather than removing it competes for the same fixed capacity.

- *"All deployments go through the shared pipeline; there is no side channel."* If alerting-config changes are governed changes, then recalibrating those stale thresholds is not a free config tweak — it is a change requiring approval and an audit record. That bounds how fast the author can iterate on tuning, which matters because measurement-then-adjustment is inherently iterative.

**Dependencies the seed does not name:**

1. **A suppression audit trail** — the mechanism that turns a "silent drop" into a recoverable one. Prerequisite to adopting *any* suppression idea safely.
2. **Alert → engineer-action instrumentation** — the whole plan rests on measuring *"which alerts actually lead to engineer actions."* If this linkage isn't already retained, building it is the first change and is itself work, not a precondition you already hold.
3. **A current service-criticality catalog** — severity tiering requires a trusted map of alert → severity → route. The seed admits thresholds *"were set at service deployment years ago and may never have been revisited"* and routing *"might be going to the wrong team."* Tiering built on that metadata inherits its staleness.
4. **Rule ownership with change authority** — who can recalibrate, and can they do so within the governed pipeline.

## Disagreements and tensions

- **The prior agent classes volume reduction as "convenience" — that understates it.** The outcome-and-users agent wrote that *"reducing volume is a convenience outcome; improving signal quality... is a reliability-and-operability outcome."* Signal quality is indeed reliability, but volume is not merely convenience. An engineer taking *"over forty alerts across a Friday evening"* has degraded judgment and slower response to the one real page buried in the noise. Alert fatigue is itself a **reliability risk** (priority 2), not a comfort issue (priority 4). Material because: filing volume under convenience lets a downstream trade-off deprioritize it below where it belongs — the fatigue is actively eroding the detection the non-negotiable depends on.

- **AI-based anomaly detection is the single highest-risk idea, and not only for false negatives.** A learned baseline that decides *"this is normal, don't page"* is the least inspectable of the options. The constraint *"any automated approval must be inspectable after the fact by the security team"* is a hard gate, and a model that withholds pages resists exactly that reconstruction. Under priority 1 (safety and security), this idea conflicts with a non-negotiable constraint before its noise-reduction benefit is even weighed. It should be ranked last, not listed as a peer of the others. Additionally, an *"adaptive"* baseline can drift into suppressing a slowly-degrading real condition (a boiling-frog failure) precisely because it learned the degradation as normal.

- **The measurement the whole plan rests on is contaminated by the problem it measures.** The seed proposes distinguishing alerts that *"lead to engineer actions"* from those that *"get dismissed without any response."* But dismissal-without-response is ambiguous: under alert fatigue, a dismissed alert may be a *real one an overwhelmed engineer ignored*, not noise. The very fatigue being measured corrupts the negatives in the dataset. Material because: if you compute a noise ratio from dismissals and then tune suppression to match, you may train the system to drop the class of alerts fatigued engineers were already wrongly ignoring — automating a human failure. Neither the seed nor the prior agent flags that dismissals are not clean negatives.

- **A uniform "persist for N minutes" rule violates the priority order across services.** The prior agent noted persist-suppression can miss a resolve-then-recur or a minute-one catastrophe. The constraint angle sharpens it: a single N applied platform-wide embeds an identical detection delay regardless of blast radius, yet the seed's own example — *"the payment processor is down"* — is a high-blast-radius service where any delay is a safety cost. A per-service delay tolerance is required, which reintroduces the criticality-catalog dependency above.

## Questions

- Does the current tooling already record *what a suppression/dedup rule withheld and why*, or would adopting any suppression idea first require building that audit trail to satisfy the inspectability constraint?
- Is the alert → engineer-action linkage already retained in queryable form, or is the first deliverable instrumentation that does not yet exist?
- Are alerting-config changes governed by the same shared-pipeline approval-and-audit process, and if so what is the iteration latency on tuning a threshold?
- For dismissed-without-response alerts, is there any way to distinguish "noise correctly ignored" from "real alert missed under fatigue," or must those be treated as an unresolved measurement hazard?
- Does a trusted, current service-criticality mapping exist that severity tiering and per-service delay tolerances could be built on, or is that metadata as stale as the thresholds the seed distrusts?
- What retention and inspectability requirement would the security team place on an automated page-withholding decision — i.e., is an anomaly-detection model that cannot explain a specific suppression admissible at all?

## Agent entry — ambiguity-and-decisions

## Analysis

My remit is the ambiguity and the open decisions, so I want to resist the direction both prior agents have already pushed: toward a single "the real problem is X" framing. The seed is genuinely under-determined, and it is the pipeline's job to *name* the live readings, not to pick one. There are at least five distinct problems hiding under "alert fatigue," and each one changes the success metric, the owner, and which of the floated ideas is even relevant.

**Reading 1 — Volume problem.** The problem is the raw count: "over forty alerts across a Friday evening." Success = fewer pages per shift. This reading legitimizes suppression and dedup directly, and it makes the baseline optional — you can just cut volume and see if shifts feel survivable. This is the shallowest reading and the one most of the "ideas floating around" implicitly assume.

**Reading 2 — Signal-quality / ambiguity problem.** The seed floats this itself: "whether the problem is too many alerts or too many ambiguous alerts... cutting volume without improving signal quality may just leave us with fewer but equally confusing pages." Under this reading, success = every page is trustworthy and actionable, and volume is incidental. This is the reading the outcome-and-users agent adopted. It promotes runbooks and tiering and *demotes* suppression, because a suppressed alert improves neither trust nor actionability of the ones that remain.

**Reading 3 — Measurement / epistemic problem.** "We have never measured which alerts actually lead to engineer actions." Under this reading the problem is that *you cannot currently frame the problem* — noise ratio is unknown, so no success metric can be defined and no change evaluated. Both prior agents elevated this to primary. It is a legitimate reading, but note what it changes: it makes the first deliverable *instrumentation*, defers every other idea, and reframes the seed from "reduce noise" to "become able to reason about noise at all."

**Reading 4 — Calibration / config-debt problem.** Thresholds "were set at service deployment years ago and may never have been revisited." Under this reading nothing is structurally wrong; the parameters are just stale. Success = recalibrated thresholds, and the fix is bounded, per-service, and needs no new mechanism.

**Reading 5 — Routing / organizational problem.** "Some alerts might be going to the wrong team or the wrong tier of on-call, compounding the noise." Under this reading the pages are fine but pointed at the wrong humans; success = correct routing, and the owner is whoever holds the on-call topology, not whoever tunes thresholds.

**The org-context readings the seed also floats, mapped.** The risk-and-constraints agent established the mapping (suppression ≈ automated approval, alert-config ≈ change, on-call ≈ fixed-capacity reviewers). Extending it to the three framings I was asked to name explicitly:

- **Automate the gate.** Threshold-suppression and AI anomaly detection are "let a machine decide a human need not be interrupted" — the direct analogue of *automating an approval*. Adopting this reading makes the central question *where the automation boundary sits and what it must record*, and it drags in "any automated approval must be inspectable after the fact by the security team." Under this reading the design problem is auditability of a withholding decision, not noise math.

- **Replace judgment with policy.** Severity tiering is "critical/warning/info" encoded as machine-checkable rules for *when to page* — the analogue of *replacing approval with policy*. This reading turns the problem into a governance one: who authors the policy, who ratifies it, how it is versioned. The strength of this reading is that policy is inspectable in a way a learned model is not; its cost is that it inherits the stale-metadata dependency (Reading 4) — a tiering policy is only as good as the criticality catalog under it.

- **Change the paging model.** "The rest go to dashboards or async channels" is not a filter — it is a *change to the delivery model*, from push-interrupt to pull-monitor for a class of signals. This reading changes *who is accountable for noticing* a non-critical-but-real condition, and it competes for the same fixed human capacity (risk agent's point) while making that watching less accountable.

The single ambiguity beneath all of these is definitional, and the organizational context names its twin exactly: "low-risk change — a change whose failure modes and blast radius are well understood; **the exact classification criteria are unresolved**." The seed has the same hole for "noise": there is no agreed definition of what separates a real incident from noise. Every reading above is downstream of that one unresolved classification. Until it is decided, "paged for real incidents and not for noise" is not a spec — it is a placeholder for a decision nobody has made yet.

## Disagreements and tensions

- **Both prior agents settle the volume-vs-signal question by decree; it is not theirs to settle.** The outcome-and-users agent asserts "volume reduction is a convenience outcome... signal quality is a reliability outcome"; the risk agent rebuts that "alert fatigue is itself a reliability risk." They are arguing about which reading is correct — but the seed poses this *as an open question the author has not answered* ("whether the problem is too many alerts or too many ambiguous alerts"). The framing's job here is to surface that these are two readings with two different success metrics and hand the choice back to the author, not to litigate it internally and present a winner. Material because a downstream agent reading only the outcome agent's entry would inherit "signal quality is the goal, volume is a by-product" as settled, when it is a decision the author explicitly flagged as open.

- **The "measure first" consensus quietly forecloses a competing sequencing reading.** Both agents treat building the baseline as the necessary first step. But the risk agent's own observation — fatigue is "actively eroding the detection the non-negotiable depends on" — implies urgency that cuts the other way: there is a defensible reading where the obviously-protectable top tier (the named payment processor) gets protected *now*, before any baseline exists, and measurement covers only the ambiguous middle. "Measure everything first" and "protect the obvious now, measure the rest" are two different plans with different risk profiles, and neither prior agent acknowledges the second exists. This sequencing is itself an open decision, not a settled prerequisite.

- **Both agents treat the non-negotiable as the author's to declare, but the decision-owner is ambiguous.** The author writes "I would rather have the current situation than miss a production-down event." The outcome agent correctly notes the customer is the highest-priority affected party — which means the acceptable-miss-rate is a business/reliability risk decision that the *service owners and whoever owns the SLA* have standing in, not a preference the seed's author can set alone. The prior entries accept the author's framing of the non-negotiable without asking whose decision it actually is. That ownership question is exactly the kind of thing my remit exists to raise.

## Questions

- Which reading is the author actually committing to — volume reduction, signal quality, measurement-first, recalibration, or routing — given that each defines a different success metric and a different first deliverable?
- Who owns the definition of "real incident vs noise," the classification that every proposed mechanism depends on and that the seed leaves as open as the org context leaves "low-risk change"?
- Who has the authority to set the acceptable missed-real-incident rate — the seed's author, the service owners, or whoever holds the SLA — since the "I would rather keep the current situation" trade-off is currently asserted by one person?
- Is protecting the obvious top-tier services (the named payment processor) allowed to proceed *before* the baseline exists, or must every change wait on measurement — i.e., is this one plan or two?
- Which of the floated ideas is a configuration/process change within one team's authority versus a change to alerting infrastructure requiring broader sign-off, given the seed's own uncertainty about "whether any of the above requires changing the alerting infrastructure"?
- If the "change the paging model" reading is chosen (non-critical alerts to dashboards/async), who becomes accountable for watching those channels, and does that accountability get recorded the way an on-call page implicitly is?

## Human answers


# Framing questions

Collected from the framing agents. This file is the only human input the
stage requires: answer each question under its `**Answer:**` line, then run
the compaction step.


## From: outcome-and-users

- What is the acceptable false-negative rate for a real production-affecting incident — is the author's "zero missed production-down events" literal, or is there a tolerated detection delay?
- For the top-severity services (e.g. the payment processor named in the seed), is *any* suppression or delay acceptable, or must those page immediately on first occurrence regardless of the general policy?
- Do we already retain enough historical data (alert fired → engineer action / auto-resolve / dismissed) to reconstruct the noise ratio, or does measuring the baseline itself require new instrumentation first?
- Who owns the alerting rules today, and do they have the authority and capacity to recalibrate thresholds — i.e., is this a config/process problem within one team's control or a cross-team one?
- Is on-call engineer sustainability the success measure, service reliability the success measure, or both — and if both, which governs when a change improves one at the expense of the other?
- What counts as "the same probable root cause" for deduplication purposes, and who is accountable if that grouping collapses two distinct incidents into one page?

**Answer:**

1. Not literally zero, but close. For the payment processor and anything touching financial settlement, I want paging on first occurrence with no suppression. For internal services and non-customer-facing infrastructure, I'd accept a one-to-two-minute confirmation window before a page fires — if the condition clears in that window it was noise. I don't have a formal SLA number; the answer is "as fast as possible for critical, confirmation-delay acceptable for non-critical."
2. No suppression, ever, for the payment processor and top-tier customer-facing services. I would rather accept all false positives on those than risk a missed event. For lower-tier services, delay policies are negotiable.
3. We do not have alert-to-action linkage in queryable form. We have raw alert timestamps from the alerting platform but no record of whether an engineer acted, dismissed, or whether the condition auto-resolved. Measuring the baseline requires building that instrumentation first. This is the constraint everything else depends on.
4. It is a cross-team problem. The alerting platform is owned by the platform team; service-specific thresholds are owned by individual service teams; nobody holds the complete picture. Any change to tiering or routing logic goes through the platform team's process. Threshold recalibration is within each service team's authority, but they don't do it because nobody has surfaced the data that would tell them a threshold is wrong.
5. Engineer sustainability is the leading indicator. If on-call engineers stop trusting the system — start dismissing pages without investigation — we lose reliability regardless of what the dashboards say. Service reliability is the goal, but it cannot be achieved through an unsustainable rotation. When they conflict, engineer sustainability governs the short term; service reliability governs the long term. I'm not willing to trade the former for a metric on the latter.
6. I don't have a formal definition. My working intuition is: same origin service, same error type, within a five-minute window. But I acknowledge that collapses multi-component cascades into one alert when the real problem is in the dependency. The accountable party for a dismissed grouped alert would be the on-call engineer, which means the deduplication grouping logic needs to be visible to them before they dismiss — not a black box.


## From: risk-and-constraints

- Does the current tooling already record *what a suppression/dedup rule withheld and why*, or would adopting any suppression idea first require building that audit trail to satisfy the inspectability constraint?
- Is the alert → engineer-action linkage already retained in queryable form, or is the first deliverable instrumentation that does not yet exist?
- Are alerting-config changes governed by the same shared-pipeline approval-and-audit process, and if so what is the iteration latency on tuning a threshold?
- For dismissed-without-response alerts, is there any way to distinguish "noise correctly ignored" from "real alert missed under fatigue," or must those be treated as an unresolved measurement hazard?
- Does a trusted, current service-criticality mapping exist that severity tiering and per-service delay tolerances could be built on, or is that metadata as stale as the thresholds the seed distrusts?
- What retention and inspectability requirement would the security team place on an automated page-withholding decision — i.e., is an anomaly-detection model that cannot explain a specific suppression admissible at all?

**Answer:**

1. The current tooling does not log what it withheld and why. No audit trail for suppressed or deduplicated alerts exists. This means any suppression or deduplication policy that doesn't first build that logging is not acceptable — we'd be making invisible decisions with no way to reconstruct whether a real incident was held back.
2. It does not exist in queryable form. Alert timestamps exist; engineer response records do not. The first deliverable is instrumentation: a system that links an alert to what happened next (acted, auto-resolved, dismissed, no response in N minutes). Without that, we're calibrating against a baseline we cannot measure.
3. Threshold changes go through a change review process owned by each service team with a platform team sign-off for changes to shared alerting infrastructure. A threshold change for one service takes roughly two to five business days from proposal to deployed. That iteration latency is meaningful for any approach that requires threshold tuning to produce results.
4. We cannot distinguish them. An alert that fired at 2 AM and received no response within twenty minutes is ambiguous — was it noise the on-call correctly ignored, or did they miss it because they were already handling three other pages? That ambiguity is a measurement hazard that will affect any noise-ratio estimate and must be named in the instrumentation design.
5. There is an informal service-criticality mapping, but it is partially documented, not authoritative, and I would not trust it for automated routing decisions without a verification pass. If severity tiering depends on a criticality map, the map needs to be audited and confirmed as a prerequisite.
6. I don't know what the security team would require. An anomaly-detection model that cannot explain why a specific page was suppressed strikes me as a problem for the same reason a black-box approval decision in deployments would be — you cannot audit it after an incident. That is the first conversation to have before committing to AI-based anomaly detection.


## From: ambiguity-and-decisions

- Which reading is the author actually committing to — volume reduction, signal quality, measurement-first, recalibration, or routing — given that each defines a different success metric and a different first deliverable?
- Who owns the definition of "real incident vs noise," the classification that every proposed mechanism depends on and that the seed leaves as open as the org context leaves "low-risk change"?
- Who has the authority to set the acceptable missed-real-incident rate — the seed's author, the service owners, or whoever holds the SLA — since the "I would rather keep the current situation" trade-off is currently asserted by one person?
- Is protecting the obvious top-tier services (the named payment processor) allowed to proceed *before* the baseline exists, or must every change wait on measurement — i.e., is this one plan or two?
- Which of the floated ideas is a configuration/process change within one team's authority versus a change to alerting infrastructure requiring broader sign-off, given the seed's own uncertainty about "whether any of the above requires changing the alerting infrastructure"?
- If the "change the paging model" reading is chosen (non-critical alerts to dashboards/async), who becomes accountable for watching those channels, and does that accountability get recorded the way an on-call page implicitly is?

**Answer:**

1. Measurement-first. I am not committing to any noise-reduction mechanism before we know the noise ratio and have a baseline for what the system currently misses. The first reading that applies is: instrument first, then decide which reduction approach the data supports. Any other ordering is guesswork.
2. Nobody owns it today. Service owners would be the right people, with SRE oversight on the cross-service definition — the payment processor's "real incident" threshold is different from an internal caching service's. That ownership needs to be assigned as a precondition of any tiering or suppression policy, not figured out during implementation.
3. The service owners hold that authority — they own the SLAs. My "I would rather keep the current situation" was one person's assertion, not an organizational policy. The acceptable missed-incident rate needs to be set by the people accountable for each service's SLA, with input from whoever holds the on-call engineering capacity budget.
4. Yes, this can be two tracks. Top-tier services (the payment processor and equivalents) can have their policy confirmed immediately: no suppression, page on first occurrence, period. That does not require the baseline. Everything else — threshold recalibration, tiering, deduplication — waits on the instrumentation and the noise-ratio data.
5. Threshold recalibration is a configuration change within each service team's authority. Severity tiering, deduplication logic, and AI-based anomaly detection all touch shared alerting infrastructure and require the platform team's process. The boundary is: if it lives in a service team's alert config, it's theirs; if it lives in the shared alerting platform or routing layer, it needs broader sign-off.
6. Unresolved. If non-critical alerts move to an async channel, someone has to be accountable for watching that channel during the service's operating hours. That accountability needs to be explicit, recorded, and verifiable — not an informal assumption that someone will notice. If we cannot name who watches the async channel and when, this reading is not ready to implement.


