# Decision 0001: Initial governance model

- **Status:** Accepted
- **Date:** 2026-10-13
- **Decision owner:** Project lead
- **Related policy:** [GOVERNANCE.md](../../GOVERNANCE.md)

## Context

DevMesh is at an early stage. It needs clear responsibility and a practical way to make decisions now, while leaving room for broader community participation as the project grows.

## Decision

Adopt a founder-led hybrid model for the initial stage:

- The founder acts as project lead and is accountable for significant decisions.
- Additional maintainers may be appointed with explicit, documented scopes.
- Community members may participate and propose changes without automatically receiving administrative privileges.
- Fundamental governance changes require a public proposal, at least 14 calendar days for comment, a summary of material objections, and explicit approval under the rules in GOVERNANCE.md.
- Once a maintainer group is formally established, protected governance changes additionally require approval from at least two-thirds of active maintainers, rounded up.
- Succession and access recovery must be planned from the beginning, not postponed until an incident.

## Alternatives considered

1. **Permanent unilateral founder control:** simple initially, but creates continuity and accountability risks.
2. **Collective governance from day one:** premature while there are no established maintainers and responsibilities.
3. **Founder-led hybrid governance:** provides clear initial responsibility while defining a path toward shared responsibility.

## Consequences

- The project can make early decisions without pretending a community council already exists.
- Important decisions must be documented and the governance process must be followed in practice.
- Repository permissions, recovery procedures, backups, and security practices still need to be configured separately; this decision record does not enforce them by itself.
- Governance rules should be reviewed after practical testing and when the project grows.

## Follow-up

- Configure appropriate branch protection and review requirements when repository settings and plan allow.
- Write CONTRIBUTING.md, SECURITY.md, and TRADEMARKS.md without duplicating this policy.
- Establish a practical succession and credential-recovery procedure without storing secrets in Git.
