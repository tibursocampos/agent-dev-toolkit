"""Hermes plugin: path/secrets pre_tool_call guard (agent-dev-toolkit)."""

from __future__ import annotations

import os
import re
import json
from pathlib import Path
from typing import Any, Dict, List, Optional

with (Path(__file__).parent / "authorization-contract.json").open(encoding="utf-8") as _contract_file:
    AUTHORIZATION_CONTRACT = json.load(_contract_file)


def _authorized(effect: str, scope: str) -> bool:
    contract = AUTHORIZATION_CONTRACT
    if not isinstance(contract, dict) or contract.get("schemaVersion") != 1:
        return False
    entries = contract.get("authorizations")
    return isinstance(entries, list) and any(
        isinstance(entry, dict) and entry.get("effect") == effect and entry.get("scope") == scope
        for entry in entries
    )

GUARDED_TOOLS = {"terminal", "write_file", "patch"}
READ_ONLY_TOOLS = {
    "read_file", "read_many_files", "list_directory", "search_files",
    "find_files", "web_search", "web_fetch", "memory_search", "ask_user",
}

FORBIDDEN_SDD_PREFIXES = (
    "PRD/",
    "PLAN/",
    "docs/PRD/",
    "docs/PLAN/",
    "docs/backlog/",
)
DENIED_SEGMENTS = (
    "/.git/",
    "/node_modules/",
    "/bin/",
    "/obj/",
    "/dist/",
    "/build/",
    "/coverage/",
    "/.vs/",
    "/target/",
    "/vendor/",
)
ALLOWED_PREFIXES = (
    "features/",
    "memory-bank/",
    "docs/",
    ".cursor/sdd/",
    "src/",
    "test/",
    "tests/",
    "app/",
    "lib/",
    "pkg/",
    "internal/",
    "cmd/",
    "api/",
    "server/",
    "client/",
    "backend/",
    "frontend/",
    "services/",
    "components/",
    "pages/",
    "assets/",
    "public/",
    "wwwroot/",
    "infrastructure/",
    "application/",
    "domain/",
    "presentation/",
    "core/",
    "scripts/",
    "adapters/",
    "docs-site/",
    ".github/",
)
ALLOWED_EXTENSIONS = {
    ".cs",
    ".ts",
    ".tsx",
    ".js",
    ".jsx",
    ".py",
    ".java",
    ".kt",
    ".go",
    ".rs",
    ".vue",
    ".svelte",
    ".css",
    ".scss",
    ".sass",
    ".less",
    ".html",
    ".htm",
    ".sql",
    ".razor",
    ".cshtml",
    ".fs",
    ".fsx",
    ".rb",
    ".php",
    ".swift",
    ".m",
    ".h",
    ".cpp",
    ".c",
    ".hpp",
    ".json",
    ".yaml",
    ".yml",
    ".toml",
    ".xml",
    ".md",
    ".mdc",
    ".ps1",
    ".sh",
    ".dart",
    ".ex",
    ".exs",
    ".sln",
    ".csproj",
    ".fsproj",
    ".props",
    ".targets",
    ".gradle",
    ".kts",
    ".lock",
    ".config",
}

SECRET_PATTERNS = (
    ("aws_access_key", re.compile(r"AKIA[0-9A-Z]{16}")),
    ("api_key_literal", re.compile(r"(?i)api[_-]?key\s*=\s*['\"]?[a-z0-9_\-]{8,}")),
    ("github_token", re.compile(r"gh[pousr]_[A-Za-z0-9_]{20,}")),
    ("jwt", re.compile(r"eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}")),
    ("password_conn", re.compile(r"(?i)password\s*=\s*[^;\s'\"]{4,}")),
    ("private_key", re.compile(r"-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----")),
    ("azure_account_key", re.compile(r"(?i)AccountKey\s*=\s*[A-Za-z0-9+/=]{20,}")),
)
FALSE_POSITIVE = re.compile(
    r"(?i)YOUR_|example|<TOKEN>|xxx|placeholder|Configuration\[|Environment\.Get|process\.env"
)

SHELL_PATH_PATTERNS = (
    re.compile(r'(?i)(?:^|[\s;&|])(?:>{1,2})\s*["\']?([^\s"\'|&;]+)'),
    re.compile(
        r'(?i)(?:Out-File|Set-Content|Add-Content|New-Item|Copy-Item|Move-Item|Remove-Item|'
        r'\bri\b|\brm\b|\bdel\b|\berase\b|\btee\b)\s+(?:-[A-Za-z]+\s+[^\s]+\s+)*["\']?([^\s"\'|&;]+)'
    ),
    re.compile(
        r'(?i)(?:Out-File|Set-Content|Add-Content|New-Item|Copy-Item|Move-Item|Remove-Item|'
        r'Get-Content|Get-ChildItem)\s+[^\r\n]{0,400}?-(?:LiteralPath|FilePath|Path)\s+["\']?([^\s"\'|&;]+)'
    ),
    re.compile(r'(?i)-(?:LiteralPath|FilePath|Path)\s+["\']?([^\s"\'|&;]+)'),
    re.compile(r'(?i)(?:rm|rmdir|unlink|mv|cp|install)\s+(?:-[a-zA-Z0-9\-]+\s+)*["\']?([^\s"\'|&;]+)'),
    re.compile(r'(?i)(?:^|[\s;&|])(?:cat|echo|printf)\s+[^\r\n]{0,200}(?:>{1,2})\s*["\']?([^\s"\'|&;]+)'),
)

SHELL_MUTATION_PATTERN = re.compile(
    r"(?i)(?:\d?>|&>|\|\s*tee\b|(?:^|[\s;&|])(?:out-file|set-content|add-content|new-item|copy-item|move-item|remove-item|rename-item|clear-content|ri|rm|del|erase|tee|rmdir|unlink|mv|cp|touch|mkdir|install|truncate|dd|chmod|chown|sed\s+-[^\r\n]*i\b|perl\s+-[^\r\n]*i\b|git\s+(?:add|apply|checkout|clean|commit|merge|mv|reset|restore|rebase|rm)\b|npm\s+(?:install|ci|uninstall|publish)\b|dotnet\s+(?:build|publish|restore)\b|python(?:3)?\s+-c\b|node\s+-e\b))(?=\s|$)"
)
SAFE_PYTHON_PRINT_PATTERN = re.compile(
    r"(?i)^python(?:3)?\s+-c\s+([\"'])(?:print\(-?\d+(?:\.\d+)?\)|print\([\"'][^\"']*[\"']\))\1$"
)
SAFE_SED_READ_PATTERN = re.compile(
    r"(?i)^sed\s+(?:-[nE]\s+)*[\"']s/[^/]+/[^/]+/g?[\"']\s+(?:[A-Za-z0-9_.-]+[\\/])*[A-Za-z0-9_.-]+$"
)
READ_ONLY_COMMAND_PATTERN = re.compile(
    r"(?i)^(?:get-date|get-location|get-content|get-childitem|get-item|test-path|resolve-path|write-output|write-host|echo|printf|cat|head|tail|grep|rg|find|ls|dir|pwd|whoami|where|which|git\s+(?:status|diff|log|show|branch|rev-parse|ls-files))(?=\s|$)"
)

FORBIDDEN_LITERALS = (
    "PRD/",
    "PLAN/",
    "docs/PRD/",
    "docs/PLAN/",
    "docs/backlog/",
    ".cursor/plans/",
    "node_modules/",
    ".git/",
)


def _norm_rel(path: str, workspace: str) -> Optional[str]:
    """Return workspace-relative path, '' for blank, or None when outside workspace."""
    if not path:
        return ""
    raw = path.replace("\\", "/")
    try:
        full = Path(path)
        if not full.is_absolute() and workspace:
            full = Path(workspace) / path
        elif not full.is_absolute() and not workspace:
            return raw.lstrip("/")
        full = full.resolve()
        if not workspace:
            return None
        root = Path(workspace).resolve()
        try:
            rel = full.relative_to(root)
            return str(rel).replace("\\", "/")
        except ValueError:
            return None
    except Exception:
        return None


def _under_local_sdd_root(path: str) -> bool:
    if not path:
        return False
    target = Path(path).expanduser().resolve(strict=False)
    home = Path.home().resolve()
    roots = [home / name / "sdd" for name in (
        ".cursor", ".codex", ".claude", ".copilot", ".grok", ".hermes",
        ".opencode", ".zcode", ".antigravity", ".gemini", ".agents",
    )]
    roots.append(home / ".config" / "opencode" / "sdd")
    hermes_home = os.environ.get("HERMES_HOME")
    local_app_data = os.environ.get("LOCALAPPDATA")
    if hermes_home:
        roots.append(Path(hermes_home).expanduser().resolve() / "sdd")
    if local_app_data:
        roots.append(Path(local_app_data).resolve() / "hermes" / "sdd")
    for root in roots:
        try:
            lexical_root = Path(os.path.abspath(os.fspath(root)))
            canonical_root = root.resolve(strict=True) if root.exists() else lexical_root
            if canonical_root != lexical_root:
                continue  # Never trust an SDD root redirected through a symlink.
            target.relative_to(canonical_root)
            if ".git" not in {part.lower() for part in target.parts}:
                return True
        except ValueError:
            continue
    return False


def _forbidden_sdd(rel: str) -> bool:
    n = rel.replace("\\", "/").lstrip("/")
    if re.match(r"^(PRD|PLAN)/", n):
        return True
    if re.match(r"^docs/(PRD|PLAN|backlog)/", n):
        return True
    if "/.cursor/plans/" in f"/{n}/" or n.startswith(".cursor/plans/"):
        return True
    return False


def _denied_segment(rel: str) -> bool:
    n = "/" + rel.replace("\\", "/").strip("/") + "/"
    return any(seg in n for seg in DENIED_SEGMENTS)


def _is_absolute_looking(rel: str) -> bool:
    n = rel.replace("\\", "/")
    if re.match(r"^[A-Za-z]:/", n) or n.startswith("//"):
        return True
    if n.startswith("/") and not n.startswith("./"):
        return True
    return False


def _allowed_path(rel: str) -> bool:
    if not rel:
        return False
    if _is_absolute_looking(rel):
        return False
    if _forbidden_sdd(rel) or _denied_segment(rel):
        return False
    n = rel.replace("\\", "/").lstrip("/").lower()
    if any(n.startswith(p) for p in ALLOWED_PREFIXES):
        return True
    ext = Path(n).suffix
    return ext in ALLOWED_EXTENSIONS


def _extract_path(args: Optional[Dict[str, Any]]) -> str:
    if not isinstance(args, dict):
        return ""
    for key in ("path", "file_path", "filePath", "target_file", "TargetFile"):
        val = args.get(key)
        if isinstance(val, str) and val.strip():
            return val
    return ""


def _extract_content(args: Optional[Dict[str, Any]]) -> str:
    if not isinstance(args, dict):
        return ""
    parts: list = []
    for key in ("contents", "content", "new_string", "newText", "text", "command"):
        val = args.get(key)
        if isinstance(val, str) and val.strip():
            parts.append(val)
    return "\n".join(parts)


def _paths_from_shell(command: str) -> List[str]:
    if not command:
        return []
    found: List[str] = []
    seen = set()
    for pattern in SHELL_PATH_PATTERNS:
        for match in pattern.finditer(command):
            candidate = match.group(1).strip().strip("\"'")
            if not candidate or candidate.startswith("-"):
                continue
            if ("/" in candidate or "\\" in candidate or "." in candidate) or re.search(
                r"\.(cs|ts|js|json|md|ps1|sh|yml|yaml|toml|xml|txt)$", candidate, re.I
            ):
                key = candidate.lower()
                if key not in seen:
                    seen.add(key)
                    found.append(candidate)
    for literal in FORBIDDEN_LITERALS:
        if literal in command:
            token = literal.rstrip("/")
            key = token.lower()
            if key not in seen:
                seen.add(key)
                found.append(token)
    return found


def _shell_is_read_only(command: str) -> bool:
    if SAFE_PYTHON_PRINT_PATTERN.fullmatch(command.strip()):
        return True
    for segment in re.split(r";|&&|\|\||\|", command):
        text = segment.strip()
        if not text:
            continue
        if SAFE_PYTHON_PRINT_PATTERN.fullmatch(text) or SAFE_SED_READ_PATTERN.fullmatch(text):
            continue
        if not READ_ONLY_COMMAND_PATTERN.match(text):
            return False
    return True


def _secret_hit(content: str) -> Optional[str]:
    if not content:
        return None
    for line in content.splitlines():
        if FALSE_POSITIVE.search(line):
            continue
        for name, pattern in SECRET_PATTERNS:
            if pattern.search(line):
                return name
    return None


def _workspace_root() -> str:
    return os.environ.get("HERMES_WORKSPACE") or os.getcwd()


def _block_path(check: str) -> Dict[str, str]:
    return {
        "action": "block",
        "message": (
            f"Hook denied tool targeting '{check}'. "
            "SDD artifacts belong under features/; avoid legacy PRD/PLAN trees and denied segments. "
            "Paths outside the workspace are denied; extension allowlists do not apply outside the workspace."
        ),
    }


def _check_path(path: str, workspace: str, effect: str) -> Optional[Dict[str, str]]:
    rel = _norm_rel(path, workspace)
    if rel is None:
        if _under_local_sdd_root(path) and _authorized(effect, "local_sdd"):
            return None
        return _block_path(path)
    check = rel or path.replace("\\", "/")
    if not _allowed_path(check):
        return _block_path(check)
    if _forbidden_sdd(check) or any(lit.rstrip("/") in check for lit in FORBIDDEN_SDD_PREFIXES):
        if not _allowed_path(check):
            return _block_path(check)
    return None


def evaluate_tool_call(tool_name: str, args: Optional[Dict[str, Any]]) -> Optional[Dict[str, str]]:
    """Leave tool authorization to Hermes and its configured native controls."""
    return None
def register(ctx: Any) -> None:
    """Keep plugin discovery compatible without registering an authorization hook."""
    del ctx
    return None
