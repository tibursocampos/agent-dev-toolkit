# Security and dependencies

## Protect secrets and trust boundaries

- Never place credentials, tokens, private keys, signing material, or device secrets in versioned source, examples, fixtures, logs, or evidence.
- Use non-sensitive placeholders and document the approved provisioning boundary without recording secret values.
- Identify who authenticates whom, what is protected in transit or at rest, and how failure is handled.
- Do not call an encrypted channel authenticated unless peer identity and certificate or equivalent verification are also established for the selected platform.
- Treat debug, recovery, update, and provisioning paths as security-sensitive; their availability and irreversibility vary by target and bootloader.

Security features such as secure boot, flash protection, signed update, rollback, debug lock, or key storage are platform-qualified claims. Require the selected target, bootloader, version, threat model, recovery plan, and authoritative source before recommending them. Do not universalize a feature or imply that enabling it is reversible.

## Review dependencies

For each runtime, framework, library, tool, or firmware component used by the project, record:

- exact name and version or revision;
- source, provenance, license, and integrity mechanism when available;
- supported targets and known limitations;
- update, rollback, and vulnerability-response path;
- whether the dependency is present in the declared project configuration or only in a local environment.

Version pinning improves reproducibility but does not prove that a dependency is trustworthy, secure, or compatible with the target. Do not add a dependency merely to fill in missing target context.

## Safe reporting

Separate facts from recommendations. A security review may be `planned` or `assumed`; it is `verified` only for the named target, configuration, threat model, and test scenario. Do not infer physical, boot, radio, or recovery security from host tests or compilation.
