# AI PDLC Flow Experiments

> [!WARNING]
> **AI-authored:** This change was autonomously planned and implemented by an AI software factory from a human-authored specification, with possible subsequent human review or modification.

> [!WARNING]
> This experiment is effectively abandoned. The generated material is retained primarily as a research artifact.

PoC of the AI-guided framing and compaction framework in `VISION.md`: a seed raw thought driven through framing, design, and experimentation into an authoritative artifact, with agents realized as direct LLM invocations.

Artifacts are files under `artifacts/`. The current understanding is whichever artifact carries `state: authoritative` — `framing-v2.md` for the framing, `proposed-design-v1.md` for the design.

```text
WORKING
   ↓ compaction
AUTHORITATIVE
   ↓ superseded
STALE
   ↓ retention
ARCHIVED
```

- **WORKING → AUTHORITATIVE** — compaction creates a new generation of the authoritative artifact; the working material it drew on is marked superseded.
- **AUTHORITATIVE → STALE** — a later compaction replaces it. It remains available for reference but is no longer the source of truth.
- **STALE → ARCHIVED** — after an appropriate retention period; naming the state by convention is enough here, no automation.

Exploration and evidence are working material. The authoritative artifact is state. Compaction moves information from the first two into the third.

## Notes

- experimenting with PDLC flow models; previous versions mostly unstructured / happenstance / cobbled together
- wanted factory to bootstrap an AI-guided framing + compaction framework
- core concept intended to be simple; one working Markdown file; multiple agents act on it by appending analysis; periodic compaction back into a coherent state
- concept is portable (e.g. Atlassian Rovo) across AI-integrated tools; even where automated in-place editing is unavailable, append operations may be enough to support the flow
- experiment goal was initial scaffold only; see whether factory could bootstrap enough of the concept to explore it
- original specification effectively one-shot / lightly specified; assumed concept simple enough that factory could infer the intended shape
- intended interaction model; write idea down; one AI analyzes business value; another analyzes project / delivery flow; another performs decomposition; additional agents add other perspectives; compaction consolidates accumulated work
- actual result substantially overbuilt; massive write-up; framework-oriented rather than illustrating the small interaction loop
- likely inherited patterns from other orchestration / planning systems in my environment; robustness; failsafes; framework construction; heavier system design
- mismatch may partly come from asking it to "build a framework"; encouraged infrastructure around the process rather than demonstrating the process itself
- factory still weak at this kind of higher-order intent inference; performs better when my specifications are already opinionated and structurally constrained
- useful lesson; factory can execute a defined system well; less reliable when expected to infer the conceptual product / workflow from a loose description
- experiment outcome; not worth pursuing in current form
- likely better approach later; manually define the minimal agent flow and state transitions first; use factory for implementation rather than discovery of the interaction model
