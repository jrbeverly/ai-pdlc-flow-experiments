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


