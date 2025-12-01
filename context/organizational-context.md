# Organizational Context

Static context the pipeline agents read when evaluating trade-offs.
Hand-written for this PoC; it does not come from a real organization.

## Terminology

- **deployment** — a change moving into production
- **approval** — a human gate a deployment must pass before proceeding
- **change** — one deployable unit (code, configuration, service update)
- **low-risk change** — a change whose failure modes and blast radius are
  well understood; the exact classification criteria are unresolved
- **evidence** — pipeline-generated information about a change (diff, test
  results, affected service, blast radius)
- **policy** — machine-checkable rules that encode when approval is required
- **audit record** — a retained record of each deployment decision

## Priority order

1. Safety and security
2. Reliability and operability
3. Developer velocity
4. Convenience

When objectives conflict, resolve them in this order.

## Known constraints

- Every deployment decision must remain auditable; audit records are not
  negotiable.
- All deployments go through the shared pipeline; there is no side channel.
- Reviewer capacity is fixed and does not scale with deployment volume.
- Any automated approval must be inspectable after the fact by the security
  team.
