# Project Continuity and Succession

## Purpose

This document describes how DevMesh can continue operating if the project lead or a maintainer becomes unavailable, loses access, or steps down. It complements [GOVERNANCE.md](../GOVERNANCE.md); it does not replace GitHub's account recovery procedures or grant access to any account.

## Principles

Continuity decisions should protect the project and its community while preserving transparency, security, and the applicable software license.

- Do not make any person the sole holder of essential project knowledge or operational instructions where this can reasonably be avoided.
- Never store passwords, recovery codes, access tokens, private keys, or other credentials in this repository.
- Grant access only to people who need it, using the least privilege available.
- Record significant transfers of responsibility without publishing confidential security details or personal information.
- Do not assume that GitHub or another service can restore access to an account.

## Planned Responsibilities

The project lead initially coordinates project direction, governance, and access administration. As maintainers are appointed, responsibilities should be divided and documented, including who can maintain code, manage releases, handle security reports, and administer essential services.

The project should maintain an up-to-date, non-sensitive record of:
- Roles and the responsibilities assigned to them.
- Essential services and their operational owners.
- Where authoritative operational instructions are maintained.
- Which responsibilities still depend on one person and need a continuity plan.

Do not publish private contact details or sensitive infrastructure information without a clear need and permission.

## Temporary Unavailability

If the project lead is temporarily unavailable, maintainers should continue routine, reversible work within their assigned responsibilities. They should defer major governance changes, transfers of ownership, and other irreversible decisions unless urgent action is necessary to prevent significant harm.

For urgent security or service incidents, the available maintainers may take proportionate protective action within their existing access and authority. They should document the action and rationale when doing so is safe.

## Resignation or Permanent Unavailability

If the project lead steps down or is permanently unable to serve:

1. Determine which maintainers are available and willing to assume responsibilities.
2. Review the current governance rules and any recorded succession arrangements.
3. Select an interim project lead from willing, trusted maintainers through a documented decision.
4. Communicate the change publicly when it is appropriate and safe to do so.
5. Review repository, service, release, and security-report responsibilities, transferring access through the relevant platforms' supported mechanisms.
6. Record the decision and any unresolved risks without exposing credentials or sensitive personal information.

If no suitable maintainer is available, the project should state that its leadership is unresolved rather than implying that a successor has been appointed. Routine activity may be paused until responsible leadership can be established.

Permanent changes to governance or the long-term leadership model must follow [GOVERNANCE.md](../GOVERNANCE.md), including its enhanced process for protected governance changes.

## Account and Service Recovery

Recovery must use each provider's official account recovery and access-management mechanisms. Do not attempt to bypass access controls or take over another person's account.

Where supported, the project should:
- Maintain more than one appropriately authorized administrator for critical shared resources.
- Use individual accounts rather than shared personal credentials.
- Enable available account security protections.
- Keep recovery instructions in an access-controlled location outside this public repository.
- Periodically verify that designated maintainers can perform necessary administrative tasks.
- Remove or revise access promptly when a person's role ends, while preserving legitimate project continuity.

The repository itself must not contain recovery codes, secrets, private keys, personal identity documents, or instructions that would expose an account or service to compromise.

## Disagreements and Safeguards

A succession decision should be documented and handled under the project's governance process. Anyone with a direct conflict of interest should disclose it and, where practical, avoid being the sole decision-maker.

No continuity document can guarantee access to a personal account, hosting provider, domain, or external service. The project should reduce single-person dependencies over time and be transparent about limitations it has not yet resolved.

## Review

Review this document when maintainers are appointed, critical services are introduced, access arrangements change, or a succession event occurs. See also [GOVERNANCE.md](../GOVERNANCE.md), [SECURITY.md](../SECURITY.md), and [CONTRIBUTING.md](../CONTRIBUTING.md).
