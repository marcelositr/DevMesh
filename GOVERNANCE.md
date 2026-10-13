# DevMesh Governance

**Status:** Initial policy  
**Version:** 0.1  
**Last updated:** 2026-10-13

This document defines how the DevMesh project is maintained and how project decisions are made. It is intentionally concise; technical contribution steps belong in [CONTRIBUTING.md](CONTRIBUTING.md), security reporting belongs in [SECURITY.md](SECURITY.md), and the project license defines copyright and software-use permissions.

## 1. Mission and scope

DevMesh is an independent, community-oriented MQTT infrastructure project intended to support Meshtastic-compatible radio networks, with room for Brazilian public-service integrations, APIs, and bots.

DevMesh is not an official Meshtastic project and must not imply endorsement by Meshtastic or any other third party.

## 2. Governance principles

Project governance follows these principles:

- **Transparency:** significant decisions and their rationale are recorded publicly whenever doing so does not expose security-sensitive information or personal data.
- **Community participation:** anyone may propose improvements, report problems, and participate respectfully in public discussions.
- **Accountability:** maintainers must explain significant decisions and manage conflicts of interest.
- **Security and privacy:** public participation does not entitle anyone to access credentials, private user data, production systems, or administrative permissions.
- **Proportionality:** requirements should protect the project without creating unnecessary process for routine work.
- **Continuity:** project knowledge, access recovery, and succession must not depend solely on undocumented personal arrangements.

## 3. Roles and authority

### Founder and project lead

During the initial stage, the founder acts as project lead and is responsible for project direction, releases, repository administration, and appointing additional maintainers. The project lead must document significant decisions and follow the protected-change process in Section 5.

This initial arrangement is not a permanent entitlement to control every future community service. As the project gains active maintainers, responsibilities should be delegated under documented criteria.

### Maintainers

Maintainers are trusted contributors explicitly invited to take on ongoing responsibilities. Their scope of authority must be stated when appointed, for example code review, releases, infrastructure, documentation, or security response.

Maintainers should review changes within their assigned scope, disclose relevant conflicts of interest, and avoid approving their own high-impact changes when an independent review is reasonably available.

### Contributors and community members

Anyone may contribute through public issues, discussions, documentation, testing, or pull requests. Participation does not automatically grant maintainer status or administrative access.

## 4. Decision-making

- Routine, reversible changes may be handled through the normal contribution workflow.
- Significant technical or operational decisions should have a written rationale and record of alternatives considered.
- Decisions affecting security, privacy, network access, community rules, or project direction require extra care and an opportunity for public feedback when disclosure is safe.
- Maintainers should seek consensus where practical. When consensus is not reached, the responsible decision-maker must explain the outcome and rationale.
- Emergency actions may be taken to protect users or infrastructure. The action and rationale should be documented afterward as soon as it is safe to do so.

Decision records belong in [docs/decisions/](docs/decisions/). Each record should link to relevant discussions rather than copying them.

## 5. Protected changes to governance

Changes to this document or to the project's fundamental governance principles must not be merged as routine edits.

A proposed change must:

1. Be announced in a public issue or discussion, with the exact proposed change and its rationale.
2. Remain open for community comment for at least 14 calendar days, except when a narrowly scoped urgent change is required to address an immediate security or legal risk.
3. Summarize material objections and explain how they were addressed.
4. Receive explicit approval from the project lead during the founder-led stage.
5. Once a maintainer group has been formally established, also receive approval from at least two-thirds of active maintainers, rounded up, in addition to project-lead approval. An emergency exception must be documented and reviewed afterward.

The project must not describe a change as community-approved unless the required process actually took place. GitHub permissions and branch protections should be configured to support this policy where the available plan and repository settings permit them.

## 6. Appointing and removing maintainers

Appointments must be explicit, accepted by the person appointed, and documented with their responsibilities.

A maintainer may step down at any time. Access may be suspended immediately when reasonably necessary to contain a security incident or prevent harm. Other removals should include a documented reason and a fair opportunity to respond when doing so is safe and appropriate.

Where the person affected is the project lead, the succession and dispute-handling arrangements should be followed rather than treating the project lead as exempt from accountability.

## 7. Conflicts of interest and disputes

People participating in decisions should disclose material conflicts of interest. Disagreements should focus on evidence, project goals, and consequences rather than personal attacks.

Reports of misconduct should be handled discreetly and fairly. Security reports, personal information, and sensitive allegations must not be forced into public issues.

## 8. Continuity and succession

The project should maintain a succession plan that covers:

- recovery of repository and essential service access;
- secure storage and rotation of credentials outside the repository;
- backups of critical configuration and project records;
- delegation of emergency maintenance to trusted people;
- transfer or recovery of operational responsibilities if the project lead becomes unavailable.

This document does not itself transfer ownership of a GitHub account, domain, hosting account, trademark, or other asset. Those assets require appropriate access and recovery arrangements outside this document. No passwords, tokens, private keys, or recovery codes may be committed to the repository.

Until a successor or delegated maintainer has explicitly accepted responsibility, no person should be assumed to have authority merely because they contributed to the project.

## 9. Relationship to other policies

- [README.md](README.md): public-facing project overview.
- [CONTRIBUTING.md](CONTRIBUTING.md): contribution workflow.
- [SECURITY.md](SECURITY.md): vulnerability reporting and response.
- [TRADEMARKS.md](TRADEMARKS.md): name and identity usage.
- [License](LICENSE): copyright and software licensing terms.

If policies conflict, legal license terms govern software permissions; security-sensitive matters should be handled through the security process; governance decisions should be interpreted consistently with this document and applicable law.

## 10. Amendments and review

This is the initial governance policy. It should be reviewed after the first practical prototype, when additional maintainers are appointed, and whenever the project’s operational risks change materially. Reviews must not be used to bypass Section 5.
