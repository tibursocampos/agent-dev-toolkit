/**
 * agent-dev-toolkit OpenCode plugin (path/secrets PreToolUse + marker).
 * Path (global): ~/.config/opencode/plugins/agent-dev-toolkit-marker.js
 * RN03: hooks are JavaScript plugins only — no shell/PS1 hook parity.
 * Deny = throw from tool.execute.before (OpenCode blocks the tool).
 *
 * @see https://opencode.ai/docs/plugins/
 * @see adapters/_shared/guard-rules.md
 */

const FORBIDDEN_SDD = [
  /^(PRD|PLAN)\//i,
  /^docs\/(PRD|PLAN|backlog)\//i,
  /(^|\/)\.cursor\/plans\//i,
]

const DENIED_SEGMENTS = [
  '/.git/',
  '/node_modules/',
  '/bin/',
  '/obj/',
  '/dist/',
  '/build/',
  '/coverage/',
  '/.vs/',
  '/target/',
  '/vendor/',
]

const SDD_PREFIXES = ['features/', 'memory-bank/', 'docs/', '.cursor/sdd/']

const APP_DIR_PREFIXES = [
  'src/', 'test/', 'tests/', 'app/', 'lib/', 'pkg/', 'internal/', 'cmd/',
  'api/', 'server/', 'client/', 'backend/', 'frontend/', 'services/',
  'components/', 'pages/', 'assets/', 'public/', 'wwwroot/',
  'infrastructure/', 'application/', 'domain/', 'presentation/',
  'core/', 'scripts/', 'adapters/', 'docs-site/', '.github/',
]

const APP_EXTENSIONS = new Set([
  '.cs', '.ts', '.tsx', '.js', '.jsx', '.py', '.java', '.kt', '.go', '.rs',
  '.vue', '.svelte', '.css', '.scss', '.sass', '.less', '.html', '.htm',
  '.sql', '.razor', '.cshtml', '.fs', '.fsx', '.rb', '.php', '.swift', '.m',
  '.h', '.cpp', '.c', '.hpp', '.json', '.yaml', '.yml', '.toml', '.xml',
  '.md', '.mdc', '.ps1', '.sh', '.dart', '.ex', '.exs', '.sln', '.csproj',
  '.fsproj', '.props', '.targets', '.gradle', '.kts', '.lock', '.config',
])

const SECRET_PATTERNS = [
  { name: 'aws_access_key', re: /AKIA[0-9A-Z]{16}/ },
  { name: 'api_key_literal', re: /api[_-]?key\s*=\s*['"]?[a-z0-9_\-]{8,}/i },
  { name: 'github_token', re: /gh[pousr]_[A-Za-z0-9_]{20,}/ },
  { name: 'jwt', re: /eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}/ },
  { name: 'password_conn', re: /password\s*=\s*[^;\s'"]{4,}/i },
  { name: 'private_key', re: /-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----/ },
  { name: 'azure_account_key', re: /AccountKey\s*=\s*[A-Za-z0-9+/=]{20,}/i },
]

const FALSE_POSITIVE = /YOUR_|example|<TOKEN>|xxx|placeholder|Configuration\[|Environment\.Get|process\.env/i

const FORBIDDEN_LITERALS = [
  'PRD/', 'PLAN/', 'docs/PRD/', 'docs/PLAN/', 'docs/backlog/',
  '.cursor/plans/', 'node_modules/', '.git/',
]

const SHELL_PATH_PATTERNS = [
  /(?:^|[\s;&|])(?:>{1,2})\s*["']?([^\s"'|&;]+)/gi,
  /(?:Out-File|Set-Content|Add-Content|New-Item|Copy-Item|Move-Item|Remove-Item|\bri\b|\brm\b|\bdel\b|\berase\b|\btee\b)\s+(?:-[A-Za-z]+\s+[^\s]+\s+)*["']?([^\s"'|&;]+)/gi,
  /(?:Out-File|Set-Content|Add-Content|New-Item|Copy-Item|Move-Item|Remove-Item|Get-Content|Get-ChildItem)\s+[^\r\n]{0,400}?-(?:LiteralPath|FilePath|Path)\s+["']?([^\s"'|&;]+)/gi,
  /-(?:LiteralPath|FilePath|Path)\s+["']?([^\s"'|&;]+)/gi,
  /(?:rm|rmdir|unlink|mv|cp|install)\s+(?:-[a-zA-Z0-9\-]+\s+)*["']?([^\s"'|&;]+)/gi,
  /(?:^|[\s;&|])(?:cat|echo|printf)\s+[^\r\n]{0,200}(?:>{1,2})\s*["']?([^\s"'|&;]+)/gi,
]

/** @returns {string|null} relative path, '' for blank, null when outside workspace */
function normalizeRelative(filePath, workspaceRoot) {
  if (!filePath || typeof filePath !== 'string') return ''
  const trimmed = filePath.trim()
  if (!trimmed) return ''

  const isAbs = /^[A-Za-z]:[\\/]|^\\\\|^\//.test(trimmed)
  let full = trimmed
  if (!isAbs) {
    if (!workspaceRoot) return trimmed.replace(/\\/g, '/').replace(/^\/+/, '')
    full = `${workspaceRoot.replace(/[\\/]+$/, '')}/${trimmed}`
  }

  const fullNorm = full.replace(/\\/g, '/')
  if (!workspaceRoot) {
    return isAbs ? null : fullNorm.replace(/^\/+/, '')
  }

  const root = workspaceRoot.replace(/\\/g, '/').replace(/\/+$/, '')
  const fullLower = fullNorm.toLowerCase()
  const rootLower = root.toLowerCase()
  if (fullLower === rootLower) return ''
  if (fullLower.startsWith(rootLower + '/')) {
    return fullNorm.slice(root.length + 1).replace(/^\/+/, '')
  }
  // Sibling-prefix (agent-dev-toolkit-evil) and any other escape → outside
  return null
}

function isForbiddenSdd(relativePath) {
  const norm = (relativePath || '').replace(/\\/g, '/').replace(/^\/+/, '')
  return FORBIDDEN_SDD.some((re) => re.test(norm))
}

function hasDeniedSegment(relativePath) {
  const norm = '/' + (relativePath || '').replace(/\\/g, '/').replace(/^\/+|\/+$/g, '') + '/'
  return DENIED_SEGMENTS.some((seg) => norm.toLowerCase().includes(seg))
}

function isAbsoluteLooking(relativePath) {
  const n = (relativePath || '').replace(/\\/g, '/')
  if (/^[A-Za-z]:\//.test(n) || n.startsWith('//')) return true
  if (n.startsWith('/') && !n.startsWith('./')) return true
  return false
}

export function isAllowedWritePath(relativePath) {
  if (!relativePath) return false
  if (isAbsoluteLooking(relativePath)) return false
  if (isForbiddenSdd(relativePath) || hasDeniedSegment(relativePath)) return false
  const norm = relativePath.replace(/\\/g, '/').replace(/^\/+/, '').toLowerCase()
  if (SDD_PREFIXES.some((p) => norm.startsWith(p))) return true
  if (APP_DIR_PREFIXES.some((p) => norm.startsWith(p))) return true
  const dot = norm.lastIndexOf('.')
  if (dot >= 0) {
    const ext = norm.slice(dot)
    if (APP_EXTENSIONS.has(ext)) return true
  }
  return false
}

export function findSecretFindings(content) {
  const findings = []
  if (!content) return findings
  const lines = String(content).split(/\r?\n/)
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i]
    if (FALSE_POSITIVE.test(line)) continue
    for (const entry of SECRET_PATTERNS) {
      if (entry.re.test(line)) {
        findings.push({ type: entry.name, line: i + 1 })
        break
      }
    }
  }
  return findings
}

function extractPath(args) {
  if (!args || typeof args !== 'object') return ''
  for (const key of ['path', 'file_path', 'filePath', 'target_file']) {
    if (args[key] && typeof args[key] === 'string') return args[key]
  }
  return ''
}

function extractContent(args) {
  if (!args || typeof args !== 'object') return ''
  const parts = []
  for (const key of ['contents', 'content', 'new_string', 'newText', 'text', 'command']) {
    if (args[key] && typeof args[key] === 'string') parts.push(args[key])
  }
  return parts.join('\n')
}

function pathsFromShell(command) {
  const paths = []
  const seen = new Set()
  if (!command) return paths

  const add = (candidate) => {
    if (!candidate || candidate.startsWith('-')) return
    const cleaned = candidate.replace(/^["']|["']$/g, '')
    if (!cleaned) return
    if (!(/[\\/.]/.test(cleaned) || /\.(cs|ts|js|json|md|ps1|sh|yml|yaml|toml|xml|txt)$/i.test(cleaned))) {
      return
    }
    const key = cleaned.toLowerCase()
    if (seen.has(key)) return
    seen.add(key)
    paths.push(cleaned)
  }

  for (const pattern of SHELL_PATH_PATTERNS) {
    pattern.lastIndex = 0
    let match
    while ((match = pattern.exec(command)) !== null) {
      if (match[1]) add(match[1].trim())
    }
  }

  for (const literal of FORBIDDEN_LITERALS) {
    if (command.includes(literal)) add(literal.replace(/\/$/, ''))
  }

  return paths
}

function isWriteTool(tool) {
  return /^(write|edit|strreplace|search_replace|multiedit)$/i.test(tool || '')
}

function isShellTool(tool) {
  return /^(bash|shell|powershell)$/i.test(tool || '')
}

/**
 * Host-agnostic allow/deny for OpenCode write/edit/bash tools.
 * @returns {{ decision: 'allow'|'deny', reason: string }}
 */
export function evaluatePathSecretsGuard(tool, args, workspaceRoot) {
  const allow = { decision: 'allow', reason: '' }
  const write = isWriteTool(tool)
  const shell = isShellTool(tool)
  if (!write && !shell) return allow

  const paths = []
  let content = ''
  if (write) {
    const p = extractPath(args)
    if (!p) {
      return {
        decision: 'deny',
        reason: 'Hook denied write/edit because tool args have no path. Fail-closed: path is required.',
      }
    }
    paths.push(p)
    content = extractContent(args)
  } else if (shell) {
    const cmd = args && typeof args.command === 'string' ? args.command : extractContent(args)
    content = cmd
    paths.push(...pathsFromShell(cmd))
  }

  for (const raw of paths) {
    const relative = normalizeRelative(raw, workspaceRoot)
    if (relative === null) {
      return {
        decision: 'deny',
        reason: `Hook denied tool targeting '${raw}'. Paths must resolve under the workspace root; extension allowlists do not apply outside the workspace.`,
      }
    }
    const candidate = relative || raw
    if (!candidate) continue
    if (!isAllowedWritePath(candidate)) {
      return {
        decision: 'deny',
        reason: `Hook denied tool targeting '${candidate}'. SDD artifacts belong under features/; avoid legacy PRD/PLAN trees and denied segments.`,
      }
    }
  }

  const secrets = findSecretFindings(content)
  if (secrets.length > 0) {
    return {
      decision: 'deny',
      reason: `Hook denied tool because content matches secret pattern '${secrets[0].type}'. Use env var names or placeholders.`,
    }
  }
  return allow
}

export const AgentDevToolkitMarkerPlugin = async (ctx) => {
  const workspaceRoot = (ctx && (ctx.directory || ctx.worktree)) || process.cwd()
  return {
    'tool.execute.before': async (input, output) => {
      const tool = input && input.tool ? String(input.tool) : ''
      const args = output && output.args ? output.args : {}
      const verdict = evaluatePathSecretsGuard(tool, args, workspaceRoot)
      if (verdict.decision === 'deny') {
        throw new Error(verdict.reason || 'Blocked by agent-dev-toolkit path/secrets guard')
      }
    },
  }
}
