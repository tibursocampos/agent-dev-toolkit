/**
 * agent-dev-toolkit OpenCode plugin (path/secrets PreToolUse + marker).
 * Path (global): ~/.config/opencode/plugins/agent-dev-toolkit-marker.js
 * RN03: hooks are JavaScript plugins only — no shell/PS1 hook parity.
 * Deny = throw from tool.execute.before (OpenCode blocks the tool).
 *
 * @see https://opencode.ai/docs/plugins/
 * @see adapters/_shared/guard-rules.md
 */

import path from 'node:path'
import fs from 'node:fs'

const AUTHORIZATION_CONTRACT = JSON.parse(fs.readFileSync(new URL('./authorization-contract.json', import.meta.url), 'utf8'))

export function evaluateAuthorization(effect, scope) {
  if (!AUTHORIZATION_CONTRACT || AUTHORIZATION_CONTRACT.schemaVersion !== 1 || !Array.isArray(AUTHORIZATION_CONTRACT.authorizations)) return false
  return AUTHORIZATION_CONTRACT.authorizations.some((entry) => entry.effect === effect && entry.scope === scope)
}

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
const LOCAL_SDD_ROOTS = [
  '.cursor/sdd', '.codex/sdd', '.claude/sdd', '.copilot/sdd', '.grok/sdd',
  '.hermes/sdd', '.opencode/sdd', '.zcode/sdd', '.antigravity/sdd',
  '.gemini/sdd', '.agents/sdd', '.config/opencode/sdd',
]

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

const READ_ONLY_TOOLS = new Set([
  'read', 'glob', 'grep', 'list', 'webfetch', 'websearch', 'codesearch',
  'lsp', 'todoread', 'question', 'skill',
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

function isUnderLocalSddRoot(filePath) {
  if (!filePath || typeof filePath !== 'string') return false
  const home = process.env.USERPROFILE || process.env.HOME
  if (!home) return false
  const target = resolveThroughExistingAncestor(filePath)
  if (!target) return false
  const rootCandidates = LOCAL_SDD_ROOTS.map((entry) => path.resolve(home, entry))
  if (process.env.HERMES_HOME) rootCandidates.push(path.resolve(process.env.HERMES_HOME, 'sdd'))
  if (process.env.LOCALAPPDATA) rootCandidates.push(path.resolve(process.env.LOCALAPPDATA, 'hermes/sdd'))
  const roots = rootCandidates.filter((root) => {
    const resolved = resolveThroughExistingAncestor(root)
    return resolved && path.resolve(resolved).toLowerCase() === path.resolve(root).toLowerCase()
  })
  const normalized = target.replace(/\\/g, '/').toLowerCase()
  return roots.filter(Boolean).some((root) => { const r = root.replace(/\\/g, '/').toLowerCase(); return normalized === r || normalized.startsWith(r + '/') })
}

function resolveThroughExistingAncestor(candidate) {
  const absolute = path.resolve(candidate)
  let probe = absolute
  const suffix = []
  while (!fs.existsSync(probe)) {
    const parent = path.dirname(probe)
    if (parent === probe) return null
    suffix.unshift(path.basename(probe))
    probe = parent
  }
  try { return path.resolve(fs.realpathSync.native(probe), ...suffix) } catch { return null }
}

function isPhysicallyWithinWorkspace(candidate, workspaceRoot) {
  const resolvedRoot = resolveThroughExistingAncestor(workspaceRoot)
  const resolvedCandidate = resolveThroughExistingAncestor(path.resolve(workspaceRoot, candidate))
  if (!resolvedRoot || !resolvedCandidate) return false
  const root = path.resolve(resolvedRoot).toLowerCase()
  const target = path.resolve(resolvedCandidate).toLowerCase()
  return target === root || target.startsWith(`${root}${path.sep}`)
}

function hasProtectedSddSegment(filePath) {
  return /(^|[\\/])\.git([\\/]|$)/i.test(filePath)
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
    for (const entry of SECRET_PATTERNS) {
      const flags = entry.re.flags.includes('g') ? entry.re.flags : `${entry.re.flags}g`
      const matcher = new RegExp(entry.re.source, flags)
      let match
      while ((match = matcher.exec(line)) !== null) {
        if (!isSecretCandidateFalsePositive(match[0])) {
          findings.push({ type: entry.name, line: i + 1 })
          break
        }
        if (match[0] === '') matcher.lastIndex++
      }
      if (findings.length > 0 && findings[findings.length - 1].line === i + 1) {
        break
      }
    }
  }
  return findings
}

function isSecretCandidateFalsePositive(candidate) {
  if (!candidate || typeof candidate !== 'string') return false
  const value = candidate.replace(/^.*?=\s*/is, '').trim().replace(/^['"]|['"]$/g, '')
  return /^(YOUR_[A-Z0-9_]+|<TOKEN>|x{3,}|placeholder(?:[_-][A-Z0-9_-]+)?)$/i.test(value)
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

function shellCommandMutates(command) {
  if (!command || typeof command !== 'string') return false
  if (/(?:\d?>|&>|\|\s*tee\b)/i.test(command)) return true
  return /(?:^|[\s;&|])(?:out-file|set-content|add-content|new-item|copy-item|move-item|remove-item|rename-item|clear-content|ri|rm|del|erase|tee|rmdir|unlink|mv|cp|touch|mkdir|install|truncate|dd|chmod|chown|sed\s+-[^\r\n]*i\b|perl\s+-[^\r\n]*i\b|git\s+(?:add|apply|checkout|clean|commit|merge|mv|reset|restore|rebase|rm)\b|npm\s+(?:install|ci|uninstall|publish)\b|dotnet\s+(?:build|publish|restore)\b|python(?:3)?\s+-c\b|node\s+-e\b)(?=\s|$)/i.test(command)
}

function shellCommandIsReadOnly(command) {
  if (!command || typeof command !== 'string') return false
  for (const segment of command.split(/;|&&|\|\||\|/)) {
    const text = segment.trim()
    if (!text) continue
    if (!/^(?:get-date|get-location|get-content|get-childitem|get-item|test-path|resolve-path|write-output|write-host|echo|printf|cat|head|tail|grep|rg|find|ls|dir|pwd|whoami|where|which|git\s+(?:status|diff|log|show|branch|rev-parse|ls-files))(?=\s|$)/i.test(text)) return false
  }
  return true
}

function isWriteTool(tool) {
  return /^(write|edit|strreplace|search_replace|multiedit)$/i.test(tool || '')
}

function isShellTool(tool) {
  return /^(bash|shell|powershell)$/i.test(tool || '')
}

function isPatchTool(tool) {
  return /^apply_patch$/i.test(tool || '')
}

/**
 * Host-agnostic allow/deny for OpenCode write/edit/bash tools.
 * @returns {{ decision: 'allow'|'deny', reason: string }}
 */
export function evaluatePathSecretsGuard(tool, args, workspaceRoot) {
  const allow = { decision: 'allow', reason: '' }
  const write = isWriteTool(tool)
  const shell = isShellTool(tool)
  const patch = isPatchTool(tool)
  if (!write && !shell && !patch) {
    if (READ_ONLY_TOOLS.has(String(tool || '').toLowerCase())) return allow
    return { decision: 'deny', reason: `Hook denied unclassified tool surface: ${tool || '(missing name)'}` }
  }

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
  } else if (patch) {
    const patchText = args && (args.patchText || args.patch || args.command)
    if (typeof patchText !== 'string' || !patchText.trim()) {
      return { decision: 'deny', reason: 'Hook denied apply_patch because its patch payload is missing.' }
    }
    content = patchText
    for (const match of patchText.matchAll(/(?:\*\*\*\s+(?:Add|Update|Delete)\s+File:\s+|diff --git a\/)([^\r\n ]+)/gi)) {
      paths.push(match[1])
    }
    if (paths.length === 0) {
      return { decision: 'deny', reason: 'Hook denied apply_patch because no target path could be classified.' }
    }
  } else if (shell) {
    const shellKeys = ['command', 'cmd', 'shell_command', 'script', 'CommandLine']
    const shellKey = args && typeof args === 'object' ? shellKeys.find((key) => Object.prototype.hasOwnProperty.call(args, key)) : undefined
    const cmd = shellKey && typeof args[shellKey] === 'string' ? args[shellKey] : ''
    if (!cmd.trim()) {
      return { decision: 'deny', reason: 'Hook denied shell execution because its command is missing, empty, or malformed.' }
    }
    content = cmd
    const shellMutates = shellCommandMutates(cmd)
    paths.push(...pathsFromShell(cmd))
    if (shellMutates && paths.length === 0) {
      return { decision: 'deny', reason: 'Hook denied shell execution because a write-capable command had no safely classified target path.' }
    }
    if (!shellMutates && !shellCommandIsReadOnly(cmd)) {
      return { decision: 'deny', reason: 'Hook denied shell execution because its effect could not be classified as read-only.' }
    }
  }

  for (const raw of paths) {
    const effect = patch ? 'file.patch' : shell ? 'shell.mutate' : /^(delete|remove)$/i.test(String(tool || '')) ? 'file.delete' : 'file.write'
    const relative = normalizeRelative(raw, workspaceRoot)
    if (relative === null) {
      if (isUnderLocalSddRoot(raw) && !hasProtectedSddSegment(raw) && evaluateAuthorization(effect, 'local_sdd')) continue
      return {
        decision: 'deny',
        reason: `Hook denied tool targeting '${raw}'. Paths must resolve under the workspace root; extension allowlists do not apply outside the workspace.`,
      }
    }
    const candidate = relative || raw
    if (relative !== null && !isPhysicallyWithinWorkspace(candidate, workspaceRoot)) {
      return {
        decision: 'deny',
        reason: `Hook denied tool targeting '${raw}'. The physical destination resolves outside the workspace root.`,
      }
    }
    if (!evaluateAuthorization(effect, 'workspace')) return { decision: 'deny', reason: 'Effect/scope is not authorized by portable contract.' }
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
