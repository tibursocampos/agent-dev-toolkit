## Metrics (SonarQube alignment)

| SonarQube concept | This skill | How to compute |
|-------------------|------------|----------------|
| Coverage on new code | **New code** | Line coverage on changed production files only: covered lines / coverable lines, weighted by file |
| Coverage after merge (expected) | **Overall branch** | Line % from `Summary.txt` (all included assemblies) |
| Per-file on PR | **Per-file** | Line % per changed production file from Cobertura `class`/`line` nodes |

### Parsing Cobertura for per-file / new code

1. Load `coverage.cobertura.xml` from `TestResults`.
2. For each `<class filename="...">`, map `filename` to repo-relative path.
3. Match against changed production file list from git diff.
4. Line rate = `lines-covered / (lines-covered + lines-uncovered)` from class attributes or count `<line>` hits.

If multiple Cobertura files exist (multiple test projects), merge or take the union of covered lines per source file before calculating rates.

### Threshold evaluation

| Label | Rule |
|-------|------|
| **Threshold** | User/PRD argument or default **80%** on **new code** (weighted) |
| **Target** | **100%** - report gaps for any changed file below 100% even when Pass |
| **Pass** | New code ≥ threshold |
| **Fail** | New code &lt; threshold |

---

---
