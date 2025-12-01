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

## Agent entry — outcome-and-users

## Analysis

The seed's stated want — "fewer humans spent rubber-stamping while the guarantees the approval process is supposed to provide stay intact" — bundles a means with an end. "Fewer humans spent rubber-stamping" is an input metric; the outcomes it serves are faster time-to-production for deployers and undiminished screening of dangerous changes. Those do not necessarily move together. Reviewer capacity is fixed, so offloading routine approvals frees approver time but does not itself accelerate the high-risk cohort that still requires human review — the changes where delay is arguably most justified, and possibly most painful.

Applying the organizational priority order, the seed's motive (deploy velocity, approver convenience) sits at priorities 3 and 4, while the guarantees it claims to protect sit at 1 and 2. On its face that is the right ordering — but the safety side is unquantified. The seed never names what guarantees the manual approval actually provides today, so "stay intact" has no observable meaning yet. Until that is specified, any proposed change can be defended by asserting the guarantees survived.

**Affected users the seed names or implies:**

- **Deploying teams** — wait time; the seed's primary beneficiary ("I watched a deploy sit for most of a day... The change was a copy tweak").
- **Approvers/reviewers** — fixed capacity consumed by routine clicks; attention dilution is itself a safety issue (rubber-stamping teaches reviewers not to look).
- **Security team** — the gatekeepers of priorities 1 and the audit-record constraint; the seed admits it has not asked them anything.
- **Not mentioned:** on-call/operations engineers and end users, who absorb the cost when a change slips past whatever replaces the human gate; and anyone who reads audit records after the fact (security, possibly auditors or compliance). The blast radius of a false negative lands on people absent from the seed.

**Success is therefore under-defined.** A workable outcome statement needs at least: (1) routine changes reach production faster and with fewer human touches; (2) dangerous changes are still caught with no worse accuracy than today — which requires knowing today's accuracy, unstated; (3) every deployment decision remains auditable in substance, not just in name.

## Disagreements and tensions

- **The seed treats "routine" as evidence of "low-risk."** It quotes approving "service bumps, config tweaks, the kind of change nobody expects to break anything." "Nobody expects to break anything" is a statement about expectations, not failure modes or blast radius — the very criteria the organizational context says define low-risk change, and which it also says are unresolved. Config tweaks in particular are classically high-blast-radius changes despite being routine. Repetition is about frequency; it says nothing about danger.
- **The load-bearing assumption is untested, and the seed knows it.** "The security folks would accept automated approval if the audit trail is preserved (I have not actually asked them)" — this is the single point on which ideas 1 and 2 stand or fall, and it sits exactly at priority 1. There is no basis yet to assume the audit trail is sufficient; security may additionally require a human accountable at decision time for some classes, or may reject the premise that post-hoc inspectability equals approval. This assumption must be tested before framing converges, not after.
- **"Drop the approval concept" conflicts with the organizational definitions.** The context defines approval as a human gate and requires an audit record of every deployment decision. If a qualifying deployment has no approval, the pipeline must still define what its auditable decision is (a policy evaluation? a classification result? a recorded non-event?). Idea 2 does not remove this requirement, but the seed does not acknowledge that it redefines what is being audited.
- **The seed's own open question is currently unanswerable.** "Do the CI signals we already have distinguish low-risk changes reliably enough...?" — against what definition of "low-risk" would they be tested? The criteria are unresolved, and the evidence list is suspicious: "blast radius" is listed as available pipeline evidence, but blast radius is likely what classification is meant to predict from the other inputs, not an independent input. There is a circularity risk that should be flagged now, not discovered at evaluation time.
- **Idea 3 does not obviously serve the stated outcome.** Keeping "approval as an explicit state" with an AI/policy recommendation still ends in a human decision and a click. A recommendation may reduce cognitive load, but unless the recommendation itself triggers the decision (or auto-accepts after a window), the rubber-stamping the seed complains about persists. The three ideas target materially different outcomes and are not interchangeable.
- **The seed's success axis may not exist in the priority order.** "A copy tweak" on, say, a checkout flow can be business-critical while being neither a safety nor a reliability failure in the operational sense. The priority order has no business/revenue axis. If the framing intends "low-risk" to ignore business impact, that is a decision that should be made explicitly; if it intends to include it, no one has said how that trades against velocity.

## Questions

- What concrete guarantees does today's manual approval actually provide — human visibility of every change, a named accountable owner, an enforced pause before exposure, compliance or legal sign-off — and which of those must remain observable properties after the change?
- For which cohort is the outcome defined: low-risk changes only, or all deployments? Given fixed reviewer capacity, is the problem routine-approval volume, high-risk-change latency, or both — are they even the same problem?
- What is the operational definition of "low-risk" that the organization would accept, given the exact classification criteria are unresolved — and how do the seed's own examples (service bumps, config tweaks, copy tweaks) classify under it?
- Does the security team accept retrospectively inspectable automated decisions, or does it require a human accountable at decision time for some classes of change — and if so, which classes, on what criteria?
- If approval is dropped or automated, what must the audit record contain (policy version, all evidence inputs, the evaluation trace) for a third party after the fact to reconstruct why this deployment did not require a human?
- Who carries the cost of a false negative — a dangerous change auto-approved — and what maximum rate of such failures is acceptable before the priority-1 guarantee is considered lost?
- Should "low-risk" incorporate business/revenue impact at all, given the priority order only covers safety, reliability, velocity, and convenience — and where does the seed's copy-tweak example sit on that axis?
- Does reducing approver-hours actually require changing the approval concept at all, or is the problem the uniform application of one approval rule — i.e., is the deployment model the real target, as the seed half-suspects ("Maybe approval is a symptom and the deployment model is the problem")?

## Agent entry — risk-and-constraints

## Analysis

The seed names the tension correctly and then reads its own premise too lightly. "The approval step is also the only thing standing between us and a genuinely dangerous change" is the controlling fact for this project's risk, and its consequence is binary: whatever replaces or relaxes approval is not an added control, it is a *replacement of the sole control*. Today a dangerous change that passes CI still has to get past one human. Under the proposed designs, the first classification false negative reaches production having defeated nothing. The seed's requirement — "security and auditability have to survive whatever replaces it" — presumes survival is the default outcome of a good design. Against the sole-control premise, the correct requirement is stronger: the new control must be demonstrated at least as accurate as the old one *before* the old one is turned down, and the seed has no plan for that demonstration, only an untested assumption that an audit trail suffices. What makes this material is that there is no defense in depth to absorb the project's own error: the first mistake in the classifier is also the first unprotected change in production.

The seed's first assumption — "low-risk changes are identifiable from information the pipeline already has — the diff, test results, which service, blast radius" — collides with a stated constraint: the exact classification criteria for low-risk change are unresolved. Availability of inputs is not the same as identifiable criteria, and the context names only one party with standing to resolve the criteria: the security team the seed has not asked. The assumption also collides with the seed's own feasibility question. A classifier cannot be validated against "low-risk" until "low-risk" means something, and it cannot mean something until someone with authority defines it. The seed's open question is therefore downstream of an organizational decision, not ahead of it.

The evidence list hides two dependencies the seed never names. First, most listed inputs — diff, test results, service name — are author-supplied: produced by the same party the classifier is meant to constrain. No input on the list is generated independently of the deployer. A control built on self-reported inputs can be optimized against by the very people it screens, and the auditability requirement compounds this: a machine-checkable policy must be inspectable, and inspectability means the classification boundary is learnable by anyone who deploys. A rule can be understood and satisfied; a bypass learned once is reusable indefinitely. The human gate's defense is that it can be surprised. Second, the validation data the seed implicitly needs — historical deployments linked to production outcomes — appears nowhere. If the pipeline does not retain incident attribution, the seed's own open question ("do the CI signals we already have distinguish low-risk changes reliably enough...") is unanswerable in the near term, except through a shadow period that is slow, sample-poor precisely for the rare dangerous class, and that yields inferably zero velocity until cutover. Material because the project's entire feasibility gate rests on data the seed never confirms exists.

The reliability dimension is unexamined. Today, no safety-relevant decision consumes pipeline evidence: if "blast radius" metadata is wrong, the cost is a mislabeled dashboard or a misrouted build. Under auto-approval, the same metadata becomes an input to the sole control. Evidence dependability that is currently unverified — because nothing important depended on it — moves from a priority-2 nuisance to a priority-1 input the day any of these ideas ships. The seed treats "the pipeline already has" these signals as settled; the risk is that "has" says nothing about "has accurately."

The constraints generate further dependencies the seed does not mention:

- **The proposal changes the pipeline, and the change to approval is itself the dangerous change the project defines.** "Maybe approval is a symptom and the deployment model is the problem" is a scope question with an ownership answer: a deployment-model change is a change to the shared pipeline, which this team may not own. And under the project's own criteria, the first deployment of the new approval system is high-risk — it alters the outcome of every future deployment. Who approves the change that changes approval? By the old rules, with what evidence, accountable to whom? The mechanism being proposed has no stated room for its own rollout.
- **"All deployments go through the shared pipeline; there is no side channel" cuts both ways.** The rollback of a mis-auto-approved change is itself a deployment and therefore transits the same classifier. A false negative is compounded if the remedy waits on the same misjudging mechanism — and if an emergency path is exempted, that exemption is the new side channel. The seed's designs say nothing about the revert path.
- **Fixed reviewer capacity includes the maintainers of the new system.** The seed counts hours freed by automation and not hours moved: policy authorship, refinement, and drift control are claimed against the same fixed pool. A policy that decays without maintenance fails silently and in the most audit-constrained way possible — every decision remains recorded, while the policy that made the decisions goes stale. The audit record stays complete in form while the safety property degrades unobserved, unless someone is explicitly assigned to watch the policy itself.
- **"Inspectable after the fact" is doing more work than the seed grants it.** For a third party to reconstruct why a deployment required no human, the audit record must pin the policy version, every evidence input at decision time, and a deterministic evaluation trace. "The audit trail is preserved" assumes preservation is the hard part; reproducibility is the hard part, and it is what the security team's stated precondition actually demands. Idea 3's "AI" makes this acute: a recorded verdict of "the model said so" is not reconstructable, so if a recommendation ever becomes the decision — including auto-accept after a timeout — the audit constraint and the mechanism begin to conflict.
- **The sequencing is a dependency cycle.** Security sign-off requires a demonstrated safety case; the demonstration requires a definition of low-risk; the definition requires the security team. Asking security is not a later step in this project — it is the first step, and every design artifact produced before that conversation is at risk of being re-done after it. The seed lists the unasked-stakeholder assumption second and treats it as one of several; risk-wise it is the gate through which ideas 1 and 2 must pass to exist at all.

## Disagreements and tensions

- **"A large proportion of approvals may be repetitive enough to automate" is the wrong hook.** Repetition is frequency, not safety, and the dangerous class is rare: a policy that approves everything is already highly "accurate" while failing every case that matters. The only metric that proves the guarantee survived is the false-negative rate on the rare, dangerous class — not overall accuracy, and not agreement with past human approvals. Agreement with humans is a measure of the rubber stamp itself: humans approved essentially everything that deployed, because only approved things deploy. Built on that signal, the system would reproduce the very behavior the seed complains about, now with a policy document attached.
- **The seed says "guarantees ... have to survive," but survival is not a measurable property of an unmeasured baseline.** The earlier entry noted the guarantees are unquantified; the risk framing presses further: today's manual approval is a control with an unknown detection rate. If the baseline is unmeasured, "survive" can only mean preserving the process — which is the one thing the project necessarily discards — or asserting an unverifiable equivalence. The framing must commit to measuring the baseline (what has manual approval actually blocked, from what records?) before any replacement design can claim parity, otherwise the project is replacing an unmeasured control with an unmeasured control and will be unable to say whether safety was traded for velocity.
- **Idea 2 is worse than its framing suggests, and the earlier agent understated the risk by noting only the audit-record redefinition.** "Enforce the guarantees entirely in automated policy" quietly reduces the guarantee to whatever is expressible as machine-checkable rules at the time the policy is written. Guarantees that are judgment calls — undocumented coupling, deployer intent, off-runbook risk — have no policy encoding. The seed asserts the guarantees survive without enumerating a single one; idea 2 requires that enumeration to be *complete*, which is strictly harder than preserving it. This is the one design whose failure mode is silent by construction: a policy gap is not an error recorded anywhere.
- **The seed's own open question is unanswerable, and not for engineering reasons.** It asks whether CI signals distinguish low-risk changes, but there is no definition of low-risk to test the signals against — the context says the criteria are unresolved. Spending effort on signal analysis before the definition exists validates unknowns against unknowns. The binding constraint is definitional and organizational, and the only named authority that can resolve it is the party the seed has not asked. The framing should not let the technical path run ahead of the stakeholder conversation it depends on.
- **The seed's "ideas floating around" are not equidistant from the constraint set.** Idea 3 keeps a human decision and an explicit state, so it is compatible with the constraints as written today; it just does not obviously deliver the outcome, as the earlier entry noted. Ideas 1 and 2 require first resolving constraints that the context marks as unresolved — the classification criteria, and what an auditable deployment decision is when no human makes one. Presenting them as parallel options understates that two of the three are only reachable through renegotiation with the security team, which has not begun.

## Questions

- What has today's manual approval actually blocked, and does a record exist — denied changes, reworked deploys, production incidents attributed to specific deployments — from which the baseline control's detection rate can be measured?
- Who owns the shared pipeline and the approval logic inside it, and can this team change the decision mechanism at all — and who approves the change that changes the approval process, under which rules, with what evidence?
- What is the revert path for a mis-auto-approved deployment: does the rollback itself require approval from the same classifier, is "revert" a class the system recognizes, and if an emergency path bypasses approval, what stops that path from becoming a side channel in violation of the stated constraint?
- How observable will the classification rules be to deployment authors, and does the security team accept a control whose bypass surface can be enumerated by reading the inspectable policy — given that auditability and gameability are the same property?
- Which classifier inputs are author-supplied versus independently generated, and does the inspectability condition require provenance of the evidence inputs, or only that their recorded values are replayed?
- If no historical deployment-to-outcome data exists, by what means and over what period will the classifier be validated as no worse than the baseline before it gates production, and what does the shadow period cost the velocity outcome it exists to serve?
- Who owns the policy after launch, out of which fixed capacity pool, and is the policy's own version and change history part of the audit record — who approves changes to the policy that decides approvals?
- Who decides the maximum acceptable false-negative rate of the new control, and against what incident data, given the baseline control's rate will presumably still be unknown at that point?
- What does the security team mean by "inspectable after the fact" — replayable by whom, over every decision or sampled exceptions — and has anyone secured their capacity to actually inspect, given audit records are non-negotiable and inspection is the stated precondition?
- Is the deployment-model redesign the seed half-proposes ("Maybe approval is a symptom...") in scope for this framing at all, or is it a second project with its own risk surface and its own pipeline-authority dependencies?

## Agent entry — ambiguity-and-decisions

## Analysis

The seed is unusual in that it states its own central ambiguity outright: "It is not yet clear whether the problem should be solved through automated approval, better policy enforcement, or a different deployment model altogether." The three "ideas floating around" are therefore not design options inside one shared framing — they are outputs of at least four different readings of what the problem *is*. The framing's job on this dimension is to keep the readings distinct until a decision selects among them, because each reading changes what the framing is about, which constraints are load-bearing, and which stakeholders hold the deciding vote.

**Reading 1 — efficiency problem.** Approval is a queue, arrivals exceed a fixed-capacity service point ("Reviewer capacity is fixed"), and "a large proportion of approvals may be repetitive enough to automate." Framing object: the decision procedure for low-risk changes. Success axis: throughput and approver-hours at held-constant safety. This reading commits the framing to what the org context says is unresolved — the classification criteria for "low-risk change" — and makes the seed's untested second assumption ("the security folks would accept automated approval if the audit trail is preserved") the gate the whole reading stands on. The seed's own open question ("do the CI signals... distinguish low-risk changes reliably enough to classify on?") is this reading's feasibility test. Note: the question is only phrased neutrally; it presupposes the machine consumer.

**Reading 2 — control-quality problem, not control-existence problem.** The seed's observed fact is uniformity, not humanity: "Every deploy waits on the same manual approval no matter what it touches." Under this reading, the thing to fix is the undifferentiated gate and the rubber-stamping it produces; the design space includes differentiated review tiers, approver routing, batch handling, better pre-review evidence — none of which automate a decision. Idea 3 ("keep approval as an explicit state but let an AI or policy system recommend it") belongs here, but so do non-AI options the seed never lists. This reading preserves every org constraint without renegotiation (approval stays a human gate; the audit record trivially unchanged) — its structural advantage. Its cost: it cannot deliver the windfall of approver-hours the seed's stated want implies. It also redefines the resource: the efficiency reading optimizes hours, this reading optimizes *attention*, which "rubber-stamping" is exactly a complaint about.

**Reading 3 — deployment-model problem.** The seed floats it itself: "Maybe approval is a symptom and the deployment model is the problem." Framing object: why a copy tweak and a genuinely dangerous change share a gate at all. Two incompatible sub-readings hide here, and the constraint set decides between them. If it means a separate fast lane, it collides head-on with "All deployments go through the shared pipeline; there is no side channel." If it means restructuring *inside* the pipeline — the auditable decision becomes the classification or the staged rollout, not a human gate — the constraint survives but the meaning of "approval" in the org terminology is rewritten. The seed uses the hedge to avoid choosing; the framing cannot.

**Reading 4 — information problem (not floated by the seed).** "I watched a deploy sit for most of a day waiting on a click. The change was a copy tweak." Nothing in this anecdote failed a classifier; a human with a moment and enough signal could have decided in seconds. Under this reading the bottleneck is decision latency and evidence presentation, not decision existence: the fix is making the informed human decision fast, not replacing it. This reading changes the seed's open question materially — the consumer of classification becomes a human deciding quickly (bar: enough signal for fast, confident judgment) rather than a machine deciding autonomously (bar: rare-class reliability at scale). The seed's first assumption ("low-risk changes are identifiable from information the pipeline already has") is weak-for-the-machine and ordinary-for-the-human; its difficulty is a function of the unchosen reading.

Because the readings have different stakeholders, "who must be asked" depends on the selection. Open decisions and who holds them:

- **D1 — the reading selection itself.** Owner: the seed's author as framing sponsor. This is not a decision the framing can make on the sponsor's behalf; the most the framing can do is present the readings and their consequences. But sequencing matters: security's answer to D2 kills or licenses Reading 1, so D1 cannot be responsibly finalized before that conversation.
- **D2 — the seed's second assumption, restated as a decision.** "I have not actually asked them" identifies the owner by omission: the security team decides whether retrospectively inspectable automation is acceptable, for which classes, with what conditions. Until they decide, Readings 1 and 2's policy variant are hypothetical, and any artifact built before the answer is at risk of rework.
- **D3 — ownership of the "low-risk" criteria.** The org context says the criteria "are unresolved" and names no owner. Security has standing under the priority order, but the context does not actually assign them the definition — assigning someone to own the definition is itself a decision, currently unmade, and the seed's feasibility question cannot be answered while it is. Relatedly: whether "low-risk" includes business/revenue impact. The priority order has no such axis; someone must decide if that absence is deliberate.
- **D4 — interpretation of "no side channel."** Does a risk-tiered gate inside the shared pipeline violate it, or does the constraint only forbid a pipeline that bypasses audit? The constraint's author — in this fiction, the platform/pipeline owner — holds this decision, and it determines whether Readings 1 and 3 are constraint-compatible in any form.
- **D5 — scope of the deployment-model redesign.** The seed included it among the floating ideas, which puts it in scope until a decision takes it out. Taking it out, or committing to it as a second project, is a sponsor + pipeline-owner decision. Until made, every framing claim about "the pipeline" is quietly conditional.
- **D6 — accountability for non-human decisions.** The org context requires auditable *decisions*, not accountable *humans*. The seed names security and auditability as guarantees but never names accountability. Under Readings 1 and 2-policy, someone is accountable for an auto-approved deployment — the deploying author, the policy owner, security-by-retrospective-inspection, or nobody. That is a decision with engineering leadership and security jointly, and it is absent from the seed and from the org context.
- **D7 — the baseline-measurement commitment.** "Guarantees... have to survive whatever replaces it" is unverifiable against an unmeasured baseline. The decision whether to measure what today's gate actually blocks (and from what records) before any replacement ships is made by the sponsor, with security holding standing to require it. It is a commitment decision, not an engineering detail.

## Disagreements and tensions

- **The risk-and-constraints entry conducts its entire analysis inside the replacement frame without arguing for it.** Its controlling claim — "whatever replaces or relaxes approval is not an added control, it is a *replacement of the sole control*" — is only fully true under Readings 1 and 2-policy. Under Reading 3, dangerous changes may transit a different structure of controls, not a replaced one; under Reading 4, nothing is replaced, and "the correct requirement is stronger... before the old one is turned down" simply does not apply because nothing is turned down. The entry picked the automation reading as the problem's identity and then measured the seed's ideas against it; the selection itself was the unmade decision.
- **The outcome-and-users entry's proposed success statement quietly commits to Reading 1's cohort split.** "(1) routine changes reach production faster...; (2) dangerous changes are still caught..." assumes the population should be divided into cohorts at all. That division requires exactly the taxonomy the org context says is unresolved, and under Reading 3 the cohort taxonomy is the thing on trial — the pipeline's uniformity *is* the problem. The entry presents a reading-dependent outcome as the natural shape of the problem.
- **Both entries answered the seed's open question as asked, without noticing the question embeds an unchosen reading.** The outcome entry's circularity point ("blast radius" as both input and criterion) and the risk entry's unanswerability point (no definition to test against) are both correct *for the machine-consumer reading*. For a human deciding quickly, the evidence bar collapses and the question is materially easier. Answering "can we classify?" without naming the classifier validated the seed's presupposition instead of surfacing it — which is precisely the ambiguity work that was left undone.
- **The seed presents the three ideas as parallel options; they are not answers to the same question.** Ideas 1/2 replace the decision-maker; idea 3 keeps the human but changes their inputs; the deployment-model hedge changes which question is being asked entirely. And idea 3 is itself a family name containing an unmade decision the earlier entries noticed but didn't formalize: "recommend" spans advisory UI (outcome unchanged, as the outcome entry argued) to default-approve-with-window (a de facto human machine hybrid). Advisory vs. binding is a design-level decision that sits inside the reading; until made, "approval remains an explicit state" is compatible with both more and fewer rubber stamps. The seed's own closing hedge — "It is not yet clear whether the problem should be solved through..." — is, in this light, not indecision but accuracy: the menu is of framings, not solutions. The framing should preserve that distinction.
- **A definitions gap neither entry assigned an owner to: what is a "deployment decision"?** The org context makes "Every deployment decision must remain auditable" non-negotiable, and the terminology section defines approval and audit record but is silent on whether a policy evaluation with no human in the loop counts as a "deployment decision." Under idea 2, qualifying deployments may contain no decision in any current sense of the terminology. Deciding what the auditable unit is belongs to whoever owns the terminology — security, most plausibly — and that definitions decision precedes any audit-record design.

## Questions

- Is the framing's deliverable a single selected reading, or a decision document presenting the readings to the sponsor — and if the former, does the sponsor accept that selection cannot precede the security conversation (D2)?
- Is the seed's open question about CI signal adequacy being asked for a machine classifier, a human deciding quickly, or both — and has the consumer choice actually been made, or is the question smuggling Reading 1 in as neutral?
- Does "no side channel" mean a single gate applied uniformly to all changes, or a single pipeline whose internal gates may differ by class of change — and who has authority to interpret the constraint for this project?
- Does the security team accept retrospective inspectability as a substitute for a human accountable at decision time, and if so, with what conditions — because their answer kills or licenses two of the three floating ideas as stated?
- For a policy-only (idea 2) deployment, is the policy evaluation itself the "deployment decision" the audit record must capture, or must a human decision exist somewhere in the chain — and who decides what the auditable unit is?
- Is human accountability a guarantee the seed intends to preserve, given the org context requires auditable decisions but not accountable humans — and who, under each feasible reading, is the accountable party for an auto-approved change?
- Under Reading 3, which party holds the authority to amend the pipeline constraints the reading collides with, and is that party in the room — because "no side channel" and "all deployments go through the shared pipeline" are the only constraints that decide the reading's fate?
- Does the sponsor commit to measuring the baseline gate's actual detection/blocking performance before any replacement claims the guarantees "survived," or will parity be asserted on argument alone — and does security hold a veto over that choice?
- Does the seed's stated want — "fewer humans spent rubber-stamping" — accept a solution that reduces attention waste without reducing approver-hours much, i.e., is Reading 4's ceiling of hours-saved acceptable, or do the hours themselves have to come down for the outcome to count?

## Human answers

# Framing questions

Collected from the framing agents. This file is the only human input the
stage requires: answer each question under its `**Answer:**` line, then run
the compaction step.


## From: outcome-and-users

- What concrete guarantees does today's manual approval actually provide — human visibility of every change, a named accountable owner, an enforced pause before exposure, compliance or legal sign-off — and which of those must remain observable properties after the change?
- For which cohort is the outcome defined: low-risk changes only, or all deployments? Given fixed reviewer capacity, is the problem routine-approval volume, high-risk-change latency, or both — are they even the same problem?
- What is the operational definition of "low-risk" that the organization would accept, given the exact classification criteria are unresolved — and how do the seed's own examples (service bumps, config tweaks, copy tweaks) classify under it?
- Does the security team accept retrospectively inspectable automated decisions, or does it require a human accountable at decision time for some classes of change — and if so, which classes, on what criteria?
- If approval is dropped or automated, what must the audit record contain (policy version, all evidence inputs, the evaluation trace) for a third party after the fact to reconstruct why this deployment did not require a human?
- Who carries the cost of a false negative — a dangerous change auto-approved — and what maximum rate of such failures is acceptable before the priority-1 guarantee is considered lost?
- Should "low-risk" incorporate business/revenue impact at all, given the priority order only covers safety, reliability, velocity, and convenience — and where does the seed's copy-tweak example sit on that axis?
- Does reducing approver-hours actually require changing the approval concept at all, or is the problem the uniform application of one approval rule — i.e., is the deployment model the real target, as the seed half-suspects ("Maybe approval is a symptom and the deployment model is the problem")?

**Answer:**

1. The two guarantees I can name today: a human has looked at every change, and there is a recorded sign-off with a name attached. No enforced pause beyond the queue itself, no compliance sign-off. Those two — human visibility and a named decision — are what must survive in observable form. I can't name more without asking the approvers.
2. The outcome is about routine-change throughput for deployers and attention waste for reviewers. I am not claiming the high-risk path gets faster — it may get slower when reviewers stop rubber-stamping. Routine-approval volume is the problem; high-risk latency is a different problem I'm not solving here.
3. No accepted definition exists. I'd build it from failure mode and blast radius (what breaks, who's affected, how fast it's caught), not change type. By that test the seed's own examples split: service bumps and copy tweaks are low; config tweaks are NOT automatically low — feature flags, traffic routing, and security settings have wide blast radius. My notes lumped them together; that was wrong.
4. I have not asked them. That is the first conversation. The framing must treat this as open with both answers live, not assumed.
5. My bar: enough to reconstruct the decision — policy version, every evidence input, the evaluation trace, and a named accountable party. Reproducibility, not just a log line. I agree with the risk entry on this.
6. On-call and users absorb the cost. No rate has been set. I can't set it alone — security owns that threshold, and it should be set against the baseline's measured rate, not a guess.
7. Yes — the copy tweak shows why: operationally trivial can be business-critical. But the priority order has no business axis, so this needs either an explicit addition or a documented "deliberately excluded" decision. Unresolved until someone owns it.
8. No, it doesn't require it. Tiering, routing, and batching could reclaim attention without touching the approval concept. I suspect uniformity is the root cause but I'm not committing the framing to that — keep the deployment-model question as a reading, not a decision.


## From: risk-and-constraints

- What has today's manual approval actually blocked, and does a record exist — denied changes, reworked deploys, production incidents attributed to specific deployments — from which the baseline control's detection rate can be measured?
- Who owns the shared pipeline and the approval logic inside it, and can this team change the decision mechanism at all — and who approves the change that changes the approval process, under which rules, with what evidence?
- What is the revert path for a mis-auto-approved deployment: does the rollback itself require approval from the same classifier, is "revert" a class the system recognizes, and if an emergency path bypasses approval, what stops that path from becoming a side channel in violation of the stated constraint?
- How observable will the classification rules be to deployment authors, and does the security team accept a control whose bypass surface can be enumerated by reading the inspectable policy — given that auditability and gameability are the same property?
- Which classifier inputs are author-supplied versus independently generated, and does the inspectability condition require provenance of the evidence inputs, or only that their recorded values are replayed?
- If no historical deployment-to-outcome data exists, by what means and over what period will the classifier be validated as no worse than the baseline before it gates production, and what does the shadow period cost the velocity outcome it exists to serve?
- Who owns the policy after launch, out of which fixed capacity pool, and is the policy's own version and change history part of the audit record — who approves changes to the policy that decides approvals?
- Who decides the maximum acceptable false-negative rate of the new control, and against what incident data, given the baseline control's rate will presumably still be unknown at that point?
- What does the security team mean by "inspectable after the fact" — replayable by whom, over every decision or sampled exceptions — and has anyone secured their capacity to actually inspect, given audit records are non-negotiable and inspection is the stated precondition?
- Is the deployment-model redesign the seed half-proposes ("Maybe approval is a symptom...") in scope for this framing at all, or is it a second project with its own risk surface and its own pipeline-authority dependencies?

**Answer:**

1. No systematic record exists. Approvals are logged (who, when), but denials, reworks, and incident attribution are not queryable. The baseline detection rate is currently unmeasurable without new instrumentation — a gap I hadn't seen.
2. The platform/pipeline team owns the pipeline; this team builds on it. Changing the approval mechanism goes through their change process. And by our own logic the rollout of a new gate is itself a high-risk change — it gets human approval under the current rules before it replaces them. I hadn't thought about our own rollout; you're right.
3. Reverts go through the same pipeline and the same gate. Emergency revert today is ad hoc — no defined override path. Under automation the override path must be explicit and audited or it becomes the side channel. Needs designing.
4. I'd keep the policy readable by deployers — transparency is part of trust — but gameability is real and I don't have a position beyond "rules must be inspectable; whether authors get pre-deploy feedback is open". This is a security-team question, not mine alone.
5. Diff, test results, and service identity are author-supplied; pipeline stage/environment metadata and (if built) a blast-radius graph are independently generated. The audit record should capture input values and their source. Mixing in independent signals is a design constraint.
6. We don't have historical deployment-to-outcome data. So: a shadow period — classify alongside the human gate, compare, cut over only when false-negative performance on the rare class is demonstrated. It delays the velocity gain; I accept that. Safety first.
7. The policy needs a named owner, not silent absorption into the reviewer pool. Policy version must be pinned in every audit record, and policy changes get their own approval. I'd propose security co-owns policy changes. Unassigned today.
8. Security decides, with the measured baseline as input — not me alone and not without measurement.
9. I don't know what they mean precisely — that's part of the first conversation. I have not secured their capacity to inspect; I should book that before proposing anything.
10. In scope as a reading to be evaluated, not a committed direction. If it wins it becomes its own workstream with the pipeline team. For this stage: on the table, not designed.


## From: ambiguity-and-decisions

- Is the framing's deliverable a single selected reading, or a decision document presenting the readings to the sponsor — and if the former, does the sponsor accept that selection cannot precede the security conversation (D2)?
- Is the seed's open question about CI signal adequacy being asked for a machine classifier, a human deciding quickly, or both — and has the consumer choice actually been made, or is the question smuggling Reading 1 in as neutral?
- Does "no side channel" mean a single gate applied uniformly to all changes, or a single pipeline whose internal gates may differ by class of change — and who has authority to interpret the constraint for this project?
- Does the security team accept retrospective inspectability as a substitute for a human accountable at decision time, and if so, with what conditions — because their answer kills or licenses two of the three floating ideas as stated?
- For a policy-only (idea 2) deployment, is the policy evaluation itself the "deployment decision" the audit record must capture, or must a human decision exist somewhere in the chain — and who decides what the auditable unit is?
- Is human accountability a guarantee the seed intends to preserve, given the org context requires auditable decisions but not accountable humans — and who, under each feasible reading, is the accountable party for an auto-approved change?
- Under Reading 3, which party holds the authority to amend the pipeline constraints the reading collides with, and is that party in the room — because "no side channel" and "all deployments go through the shared pipeline" are the only constraints that decide the reading's fate?
- Does the sponsor commit to measuring the baseline gate's actual detection/blocking performance before any replacement claims the guarantees "survived," or will parity be asserted on argument alone — and does security hold a veto over that choice?
- Does the seed's stated want — "fewer humans spent rubber-stamping" — accept a solution that reduces attention waste without reducing approver-hours much, i.e., is Reading 4's ceiling of hours-saved acceptable, or do the hours themselves have to come down for the outcome to count?

**Answer:**

1. A decision document presenting the readings and what each commits us to. Selection waits on the security conversation — D1 is deferred until D2 is answered.
2. I had implicitly assumed the machine consumer. The consumer choice is NOT made. The framing should carry the seed's open question with both consumers explicit — the bar is far lower for a human deciding quickly.
3. I read it as: everything transits the one pipeline and every decision is audited. Whether the internal gate may differ by change class is not mine to interpret — the platform/pipeline team owns that. Open.
4. Unanswered — I have not asked. Their answer licenses or kills ideas 1 and 2 as stated. First conversation.
5. My instinct: the policy evaluation must count as the decision, with a recorded accountable owner (policy owner plus deployer) — otherwise idea 2 manufactures unauditable non-decisions. But the definition of "deployment decision" is security's terminology to own.
6. Yes — I intend a named accountable party for every deployment, including automated ones. The org context requires only auditable decisions; accountability-to-nobody is a regression I'm not willing to accept, so it's a guarantee I want kept.
7. The platform/pipeline team — and no, they're not in the room yet. A stakeholder to add before Reading 3 can be evaluated honestly.
8. Yes, I commit to measuring the baseline before any replacement claims the guarantees survived. Parity on argument alone isn't acceptable. Security holding a veto over that choice: I'd give them one — they own priority 1.
9. Yes. "Fewer humans spent rubber-stamping" was about wasted attention, not a quota of hours. Same hours with better attention is a win. Hours are a proxy, not the goal.

