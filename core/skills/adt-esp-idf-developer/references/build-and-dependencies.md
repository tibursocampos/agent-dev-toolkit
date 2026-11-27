# ESP-IDF build and dependency workflow

## Build source of truth

Use the project's CMake files and `idf.py` workflow as the authoritative build interface. Before changing a component, inspect its existing CMake registration, source layout, include paths, and configuration dependencies. Do not add a competing build system to fill in missing context.

When the project uses CMake and the operator requests VS Code, CMake Tools may be offered as an optional editor interface. It does not replace `idf.py`, the project's CMake configuration, or the resolved ESP-IDF environment.

## Component Manager

Inspect component manifests such as `idf_component.yml`, their declared sources and constraints, and the generated/resolved lockfile. Preserve the lockfile's resolved versions and provenance. Request review before upgrading, downgrading, or replacing a component; do not infer compatibility from a board name alone.

## PowerShell and managed Python

Only provide PowerShell-specific setup when the observed host is Windows/PowerShell or the project explicitly documents that environment. Only provide ESP-IDF-managed Python activation or installation commands when the inspected project/installation uses that environment. Otherwise ask which installation is authoritative instead of inventing paths, versions, or activation commands.

The ESP-IDF version and Python/toolchain version are project evidence. A preview project's pinned version must remain local to that project's evidence and must never become a global default.
