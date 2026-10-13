# Security Policy

## Project Status

DevMesh is an early-stage project. Security practices and infrastructure may change as the project develops. Do not assume that a dedicated security team, private reporting system, bug bounty, or guaranteed response time is available.

Before production use or a broader public launch, the project maintainers should publish a working private channel for reporting vulnerabilities and identify who is responsible for receiving and coordinating reports.

## Reporting a Vulnerability

Please do not publish details of an unpatched vulnerability in a public issue, discussion, pull request, or community channel.

Use a private contact method explicitly published by the project lead or a designated maintainer, if one is available. If no private reporting method has been published, do not post exploit details publicly. Ask the project lead or a maintainer for a private reporting route without including sensitive technical details in that request.

When a private route is available, include only the information needed to assess the report:

- Affected component, version, commit, or configuration, if known.
- A concise description of the potential security impact.
- Reproduction steps or a proof of concept, where safe and necessary.
- Relevant logs or evidence, with credentials, tokens, personal data, and unrelated information removed.
- A way to contact you for clarification, if you want to provide one.

Do not attach secrets, private keys, access tokens, real users' personal data, or full production datasets.

## Safe and Authorized Testing

Only test systems, devices, networks, and services that you own or are explicitly authorized to assess. Do not exploit, disrupt, access, or modify third-party systems or other people's devices while investigating a potential issue.

Avoid tests that could cause radio-frequency interference, unnecessary LoRa traffic, service disruption, data exposure, or damage. Use a controlled test environment whenever practical.

## Triage and Disclosure

When a report is received through an available private channel, the project lead or designated maintainer should:

1. Acknowledge receipt when reasonably possible. No fixed response time is promised at this stage.
2. Assess the report's validity, severity, affected versions, and potential impact.
3. Coordinate investigation and mitigation with the relevant maintainers.
4. Keep report details limited to people who need them while the issue is being handled.
5. Coordinate public disclosure after a fix or mitigation is available, where practical and appropriate.
6. Publish relevant security guidance or an advisory when warranted and feasible.

The project does not currently promise a bug bounty, a CVE assignment, or a particular disclosure deadline. These may be considered later, but must not be assumed to exist.

Researchers will be credited in a public advisory only when appropriate and with their consent. Please do not disclose another person's identity or report details without permission, except where disclosure is required by law.

## Scope and Governance

Security reports are distinct from reports about community conduct. For community-related concerns, see the [Code of Conduct](CODE_OF_CONDUCT.md).

Project decisions about security handling and maintainer responsibilities should follow [Governance](GOVERNANCE.md). For general contributions, see [Contributing](CONTRIBUTING.md). DevMesh's licensing information is in [LICENSE](LICENSE).

This policy will be reviewed as the project gains maintainers, infrastructure, and operational experience.
