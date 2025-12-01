---
state: stale
superseded_by: framing-v2
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
