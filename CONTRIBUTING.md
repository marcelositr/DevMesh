# Contributing to DevMesh

Thank you for considering a contribution to DevMesh. We welcome bug reports, documentation improvements, testing, ideas, and code.

DevMesh is an independent, community-oriented MQTT infrastructure project intended to support Meshtastic-compatible radio networks and future integrations. It is not an official Meshtastic project. See [README.md](README.md) for the project overview and [GOVERNANCE.md](GOVERNANCE.md) for decision-making and roles.

## Before you contribute

1. Search existing issues and discussions to avoid duplicating work.
2. For a substantial change, open an issue or discussion first so its purpose and scope can be discussed.
3. Keep contributions focused. Prefer small, understandable changes over unrelated changes bundled together.
4. Do not include passwords, access tokens, private keys, recovery codes, personal data, or other secrets in issues, commits, logs, or test fixtures.
5. For suspected vulnerabilities, do not open a public issue. Follow [SECURITY.md](SECURITY.md) once the security reporting process is available; until then, contact the project lead privately through an appropriate channel.

## Issues and proposals

When reporting a bug, include the observed behavior, expected behavior, steps to reproduce, and relevant environment details. Remove secrets and personal data from logs before sharing them.

When proposing a feature, explain the problem it solves, who benefits, possible alternatives, and any effect on privacy, security, network traffic, or compatibility.

An issue or discussion is a proposal, not a commitment to implement the change.

## Pull requests

- Explain what changed and why.
- Link related issues or decision records where applicable.
- Update documentation when behavior, setup, configuration, or user expectations change.
- Include tests or reproducible verification steps when practical. Do not claim tests passed unless they were actually run.
- Identify known limitations and any behavior that still needs testing.
- Keep each pull request focused and make it easy to review.
- Be prepared to revise a contribution in response to review.

Do not introduce a new dependency, protocol behavior, public API, or breaking change without explaining the need and alternatives.

## Technical and network considerations

Because DevMesh is intended to work with MQTT and radio networks, contributions should consider:

- unnecessary message volume and potential LoRa airtime impact;
- packet formats, compatibility, and encryption boundaries;
- authentication and topic-level authorization;
- privacy-sensitive metadata and logging;
- failure handling, reconnect behavior, and duplicate messages.

These are review considerations, not claims that all controls or technical designs have already been implemented. The project will document verified behavior as testing progresses.

## Review and decisions

Contributions are reviewed according to [GOVERNANCE.md](GOVERNANCE.md). Submitting a pull request does not guarantee acceptance. Maintainers may request changes, defer work, or close a proposal with an explanation.

Significant technical decisions should be recorded in [docs/decisions/](docs/decisions/), linking to the relevant discussion instead of repeating it.

Please follow the project's [Code of Conduct](CODE_OF_CONDUCT.md). If that policy has not yet been published, participate respectfully and avoid harassment, threats, discrimination, or personal attacks.

## Licensing and attribution

By submitting a contribution, you agree that it may be distributed under the project's applicable license, currently intended to be **GNU AGPL v3.0 or later**, subject to the license files and the rights you hold in the contribution. Only submit material you have the right to contribute, and identify third-party material and its license.

The project's license and governance are distinct. See [LICENSE](LICENSE) and [GOVERNANCE.md](GOVERNANCE.md). If licensing terms or the status of a contribution are unclear, ask before submitting it.

## Current project stage

DevMesh is in an early planning and validation stage. Some technical choices, test procedures, and operational policies are not final. Please distinguish verified results from assumptions, and do not describe proposed features as implemented.
