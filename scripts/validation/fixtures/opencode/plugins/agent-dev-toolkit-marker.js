/**
 * agent-dev-toolkit OpenCode marker plugin (MVP).
 * Path (global): ~/.config/opencode/plugins/agent-dev-toolkit-marker.js
 * RN03: hooks are JavaScript plugins only — no shell/PS1 hook parity.
 * RN04: this file is the published plugin surface; smoke asserts filesystem presence only
 * (OpenCode runtime is not required in CI).
 *
 * @see https://opencode.ai/docs/plugins/
 */
export const AgentDevToolkitMarkerPlugin = async () => {
  return {
    // Empty hooks object: marker for sync/validate; no runtime side effects in smoke.
  }
}
