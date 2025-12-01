# AI-Guided Experimental Framing and Compaction Framework

The purpose of this framework is to provide a lightweight, AI-assisted way of turning incomplete human ideas into progressively clearer and more authoritative working artifacts.

It is not intended to be a perfect product-development methodology or a rigid document workflow. Instead, it demonstrates a model in which humans can begin with loosely structured thoughts, use multiple AI agents to explore and challenge those thoughts, and periodically compact what has been learned into a new authoritative representation.

The core principle is that **conversation is temporary, while compacted artifacts represent the current state of understanding**.

## Starting with raw thought

The process begins with very little structure.

A user should be able to write down concerns, observations, ideas, assumptions, desired outcomes, questions, or partial solutions without first translating them into a formal template.

For example:

> Deployment approvals appear to be slowing teams down. A large proportion of approvals may be repetitive enough to automate, although there are concerns about security and auditability. It is not yet clear whether the problem should be solved through automated approval, better policy enforcement, or a different deployment model altogether.

At this stage, the objective is not to produce a specification.

The initial artifact exists primarily to capture the user's current understanding before information is lost or prematurely formalized.

## AI-guided framing

AI agents then help develop the raw input into a clearer framing of the problem.

Different agents can approach the material from different perspectives. For example, one agent might focus on executive or organizational value, while another identifies underlying technical or operational primitives.

Other agents might examine:

- desired outcomes;
- assumptions;
- constraints;
- priorities;
- affected users;
- risks;
- dependencies;
- ambiguity;
- unresolved decisions;
- alternative interpretations.

The agents can ask the user targeted questions where additional information would materially improve the framing.

The goal is not simply to generate more text. The goal is to increase the quality of the underlying understanding.

Agents can also be provided with organizational context in advance. This might include established terminology, strategic priorities, engineering principles, risk tolerance, or known constraints.

For example, an organization might define its priority ordering as:

1. Safety and security
2. Reliability and operability
3. Developer velocity
4. Convenience

AI agents evaluating proposals can use this hierarchy when identifying trade-offs rather than treating every objective as equally important.

## Working artifacts

During exploration, the working page will naturally become messy.

It may contain:

- the original idea;
- questions and answers;
- AI analysis;
- rejected assumptions;
- corrections;
- alternative approaches;
- new constraints;
- partial conclusions;
- contradictions;
- notes from additional reviewers.

This is expected.

The working artifact is effectively the equivalent of an AI conversation history around a problem. It contains useful evidence, but it is not necessarily the best representation of the current understanding.

The system therefore periodically performs **compaction**.

## Compaction

Compaction is a first-class operation in the framework.

It should not be treated as ordinary summarization.

A summary attempts to produce a shorter representation of existing material.

Compaction instead creates a **new generation of the authoritative artifact**.

The compaction agent considers the existing working material and produces a clean document representing what is currently believed to be true.

A compacted framing might contain:

- problem statement;
- desired outcome;
- relevant context;
- core primitives;
- priorities;
- constraints;
- assumptions;
- decisions already made;
- important alternatives considered;
- unresolved questions;
- confidence or uncertainty where appropriate.

For example:

> **Problem**
> Low-risk deployment changes currently require the same manual approval workflow as changes carrying materially greater operational or security risk.
>
> **Desired Outcome**
> Reduce unnecessary human approval activity while preserving the guarantees currently provided by the approval process.
>
> **Core Primitives**
> Change classification, evidence generation, policy evaluation, approval state, and audit records.
>
> **Priority Order**
> Preserve safety guarantees, preserve auditability, reduce human intervention, and reduce deployment latency.
>
> **Open Questions**
> Determine whether existing CI evidence provides enough information to classify low-risk changes reliably.

Once this artifact is created, it becomes the new authoritative representation.

The previous working material is retained but marked as superseded.

This creates an important distinction:

**Historical conversations and drafts are evidence. The compacted artifact is state.**

## Artifact lifecycle

Artifacts can use a deliberately simple lifecycle:

```text
WORKING
   ↓
AUTHORITATIVE
   ↓ superseded
STALE
   ↓
ARCHIVED
```

A working artifact contains active exploration.

A successful compaction creates an authoritative artifact.

When another compaction later replaces it, the previous authoritative artifact becomes stale. It remains available for reference but is no longer treated as the current source of truth.

After an appropriate retention period, stale artifacts can be moved into archival storage.

This allows historical reasoning to remain recoverable without forcing every future AI or human participant to repeatedly process the complete history.

## Generational artifacts

Compaction naturally creates generations.

For example:

```text
Framing v1
    ↓
Framing exploration
    ↓
Framing v2
    ↓
Design exploration
    ↓
Proposed Design v1
    ↓
Experiment results
    ↓
Proposed Design v2
```

Each authoritative artifact can retain lightweight provenance metadata:

```yaml
state: authoritative
generation: 3
supersedes: framing-v2

derived_from:
  - original-idea
  - framing-qa-01
  - framing-qa-02
  - architecture-review
  - risk-review

confidence: 0.82
```

The purpose of this metadata is not to create an elaborate knowledge-management system.

It simply makes it possible to determine what the current artifact is, what it replaced, and what information contributed to it.

## Moving from framing into design

Once the framing becomes sufficiently stable, the type of AI analysis changes.

Framing agents are primarily concerned with questions such as:

- What problem are we actually trying to solve?
- Why does it matter?
- What outcome are we seeking?
- What constraints apply?

Design agents can instead explore:

- possible solutions;
- system primitives;
- architecture;
- user workflows;
- failure modes;
- operational complexity;
- security implications;
- implementation constraints;
- alternative approaches.

Multiple designs should be allowed to coexist during exploration.

For example:

**Design A:** classify deployments by risk and automatically approve low-risk changes.

**Design B:** eliminate the approval concept for qualifying deployments and enforce required guarantees entirely through automated policy.

**Design C:** retain approval as an explicit state while allowing AI or policy systems to recommend approval automatically.

At this stage, disagreement between agents is useful. The purpose is to expose the solution space rather than converge immediately.

Eventually another compaction operation produces a proposed design representing the strongest current understanding.

## Experimentation as a confidence-building mechanism

The framework should avoid assuming that design naturally progresses directly into implementation.

Where uncertainty remains, the next question should often be:

> What is the cheapest experiment that would materially increase or decrease our confidence?

For example:

> **Hypothesis**
> Most low-risk deployment approvals can be derived mechanically from information already available in the deployment pipeline.
>
> **Experiment**
> Replay ninety days of historical deployment decisions through a proposed classification model.
>
> **Success Signal**
> The model reproduces reviewer decisions for at least 95% of qualifying low-risk changes.
>
> **Failure Signal**
> Significant disagreement occurs in categories where the system cannot identify a reliable distinguishing signal.

Experiment results then become new evidence.

They can lead to amendments, additional questioning, a change in direction, or another compaction.

The design process therefore becomes a loop:

```text
Design
   ↓
Hypothesis
   ↓
Experiment
   ↓
Evidence
   ↓
Amendment
   ↓
Compaction
   ↺
```

This allows confidence to develop through evidence rather than simply through repeated discussion.

## Promotion into delivery

At some point, the artifact should become sufficiently mature to move from exploration into delivery.

Promotion could create a more formal object such as a product brief, initiative, or workstream.

That artifact can then undergo broader AI review for dimensions such as:

- robustness;
- simplicity;
- strategic alignment;
- technical feasibility;
- security;
- customer value;
- operational impact;
- implementation risk.

Any significant findings can return to the working artifact for remediation.

Once those findings have been addressed, another compaction creates the authoritative workstream or delivery artifact.

That object can then feed downstream execution systems such as epics, implementation tasks, agents, pull requests, and deployment workflows.

A simplified end-to-end flow therefore looks like:

```text
Raw Thought
    ↓
Framing Q&A
    ↓
Working Framing
    ↓
Compaction
    ↓
Authoritative Framing
    ↓
Design / Brainstorming / Challenge
    ↓
Working Design
    ↓
Compaction
    ↓
Proposed Design
    ↓
Experiments
    ↕
Evidence / Amendments
    ↓
Compaction
    ↓
Product Brief / Proposed Workstream
    ↓
Multi-Agent Review
    ↓
Authoritative Workstream
    ↓
Epics
    ↓
Execution Tasks
    ↓
Implementation
```

## The important architectural idea

The framework is ultimately less about individual AI agents than about controlling the lifecycle of understanding.

A traditional process often assumes that humans will create increasingly formal documents manually.

An AI-native process can instead allow significant amounts of exploration to occur conversationally while periodically distilling the result into durable state.

That creates three distinct forms of information:

**Exploration** contains thoughts, questions, alternatives, disagreement, and unfinished reasoning.

**Evidence** contains observations, experiment results, reviews, and information that may affect decisions.

**Authoritative artifacts** contain the organization's current understanding of the problem, design, or intended outcome.

Compaction is the mechanism that moves information from the first two categories into the third.

The framework can therefore be understood as a form of **source control for organizational thought**.

Rather than preserving every conversation as though it were equally important, the system preserves history while continually creating a clean representation of the present state of understanding.

This makes it possible for humans and AI agents to repeatedly refine an idea without requiring future participants to reconstruct the entire chain of reasoning that produced it.
