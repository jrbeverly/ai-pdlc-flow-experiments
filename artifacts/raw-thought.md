---
state: stale
superseded_by: framing-v2
generation: 1
---

# Deployment approvals — loose notes

Deployment approvals are slowing teams down. Every deploy waits on the same
manual approval no matter what it touches, and most of what gets approved is
routine — service bumps, config tweaks, the kind of change nobody expects to
break anything.

I watched a deploy sit for most of a day waiting on a click. The change was a
copy tweak.

A large proportion of approvals may be repetitive enough to automate. My
concern is that the approval step is also the only thing standing between us
and a genuinely dangerous change, so removing it wholesale is not on the
table — security and auditability have to survive whatever replaces it.

What I want out of this: fewer humans spent rubber-stamping while the
guarantees the approval process is supposed to provide stay intact.

Ideas floating around:

- classify changes by risk and auto-approve the low-risk ones
- drop the approval concept for qualifying deployments and enforce the
  guarantees entirely in automated policy
- keep approval as an explicit state but let an AI or policy system recommend it

Assumptions I'm making:

- low-risk changes are identifiable from information the pipeline already
  has — the diff, test results, which service, blast radius
- the security folks would accept automated approval if the audit trail is
  preserved (I have not actually asked them)

It is not yet clear whether the problem should be solved through automated
approval, better policy enforcement, or a different deployment model
altogether. Maybe approval is a symptom and the deployment model is the
problem.

Open question: do the CI signals we already have distinguish low-risk changes
reliably enough to classify on? If not, none of the ideas above work.
