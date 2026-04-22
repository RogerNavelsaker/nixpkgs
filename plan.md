# Bun Packaging Migration Plan

Scope: review the following packaging repos one by one for either:
- an improved Bun standalone compile command with explicit per-platform targets
- a two-step Nix build split (`prepare` upstream output first, then package/compile)

Reference pattern from `nixpkg-gemini`:
- explicit Bun target mapping instead of generic `--target=bun`
- standalone compile from the real packaged entrypoint
- use a two-step build only when raw upstream source or workspace structure makes direct compile brittle

## Decision Rules

- Use `improved Bun compile command` when the repo currently wraps runtime Bun with:
  - `exec ${lib.getExe' bun "bun"} "$entrypoint" "$@"`
  - or `bunx ...` launch flow
- Use `two-step build` when upstream source is fetched separately and direct standalone compile is likely to fail without a prepare/build phase.
- Keep current packaging when upstream already ships native binaries and Nix should just package those artifacts.

## Repo-by-Repo Plan

### 1. `nixpkg-trellis`

- Current state:
  - Uses `bun2nix.writeBunApplication`
  - Fetches upstream GitHub source directly
  - Final launcher runs Bun against `src/index.ts`
- Recommendation:
  - Try improved Bun standalone compile first
  - Be prepared to move to a two-step build if direct compile from `src/index.ts` is unstable
- Plan:
  1. Identify the best compile entrypoint from upstream source
  2. Add Bun target mapping for Linux/macOS x64/arm64
  3. Replace runtime Bun wrapper with compiled binary
  4. If compile fails on source-layout/workspace issues, split into `prepare` and `package`
- Priority: highest

### 2. `nixpkg-overstory`

- Current state:
  - Uses `bun2nix.writeBunApplication`
  - Fetches upstream GitHub source directly
  - Final launcher runs Bun against `src/index.ts`
- Recommendation:
  - Same path as `nixpkg-trellis`
  - Strong candidate for two-step build if direct compile is noisy
- Plan:
  1. Probe direct standalone compile from real CLI entrypoint
  2. Add explicit Bun target mapping
  3. Fall back to two-step build only if upstream source shape requires it
- Priority: highest

### 3. `nixpkg-seeds`

- Current state:
  - Uses `bun2nix.writeBunApplication`
  - Fetches upstream GitHub source directly
  - Final launcher runs Bun against `./src/index.ts`
- Recommendation:
  - Same class as `trellis` and `overstory`
  - Likely direct compile first, two-step if needed
- Plan:
  1. Test direct compile from actual CLI entrypoint
  2. Add explicit Bun target mapping
  3. Introduce prepare/package split only if compile breaks on source/workspace assumptions
- Priority: highest

### 4. `nixpkg-codex`

- Current state:
  - Uses `bun2nix.writeBunApplication`
  - Packages npm release `@openai/codex`
  - Final launcher runs Bun against `bin/codex.js`
- Recommendation:
  - Improved Bun compile command only
  - Two-step build probably unnecessary because this packages a release artifact, not an upstream source workspace
- Plan:
  1. Compile from `bin/codex.js`
  2. Add per-system Bun target mapping
  3. Preserve alias output `cod`
- Priority: high

### 5. `nixpkg-canopy`

- Current state:
  - Uses `bun2nix.writeBunApplication`
  - Packages npm release `@os-eco/canopy-cli`
  - Final launcher runs Bun against `src/index.ts`
- Recommendation:
  - Improved Bun compile command first
  - Two-step build unlikely unless npm payload is incomplete for standalone compile
- Plan:
  1. Test compile from packaged CLI entrypoint
  2. Add explicit Bun target mapping
  3. Keep alias output `cn`
- Priority: high

### 6. `nixpkg-mulch`

- Current state:
  - Uses `bun2nix.writeBunApplication`
  - Packages npm release `@os-eco/mulch-cli`
  - Final launcher runs Bun against `src/cli.ts`
- Recommendation:
  - Improved Bun compile command only unless direct compile exposes missing-build issues
- Plan:
  1. Compile from `src/cli.ts`
  2. Add per-platform target mapping
  3. Keep alias output `ml`
- Priority: medium-high

### 7. `nixpkg-pi-coding-agent`

- Current state:
  - Uses `bun2nix.writeBunApplication`
  - Packages npm release `@mariozechner/pi-coding-agent`
  - Final launcher runs Bun against `dist/cli.js`
- Recommendation:
  - Improved Bun compile command first
  - Two-step build unlikely because the package already exposes `dist/cli.js`
- Plan:
  1. Compile from `dist/cli.js`
  2. Add explicit Bun target mapping
  3. Preserve alias outputs `pi`, `gmi`, `cc`, `cod`
- Priority: medium-high

### 8. `nixpkg-claude-code`

- Current state:
  - Uses `bun2nix.writeBunApplication`
  - Packages npm release `@anthropic-ai/claude-code`
  - Final launcher runs Bun against `cli.js`
- Special case:
  - Upstream distributes pre-built binaries per platform
  - This repo should prefer packaging upstream binaries for Nix instead of Bun-compiled output
  - Preserve the `cc` alias output as a wrapper around `claude`
- Recommendation:
  - Do not follow the Bun compile migration by default
  - Replace current runtime Bun wrapper with platform-specific upstream binary packaging
- Plan:
  1. Inspect upstream distributed binary matrix and artifact layout
  2. Map Nix systems to upstream binary assets
  3. Package the upstream binaries directly
  4. Keep `claude` as the primary output
  5. Preserve `cc` as:
     `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=true claude --dangerously-skip-permissions "$@"`
- Priority: separate track, do after the Bun-compile repos

## Execution Order

1. `nixpkg-trellis`
2. `nixpkg-overstory`
3. `nixpkg-seeds`
4. `nixpkg-codex`
5. `nixpkg-canopy`
6. `nixpkg-mulch`
7. `nixpkg-pi-coding-agent`
8. `nixpkg-claude-code`

## Expected Output Per Repo

- `nix/package.nix` updated away from runtime Bun wrapper
- explicit Bun target mapping for:
  - `x86_64-linux` -> `bun-linux-x64`
  - `aarch64-linux` -> `bun-linux-arm64`
  - `x86_64-darwin` -> `bun-darwin-x64`
  - `aarch64-darwin` -> `bun-darwin-arm64`
- `nix build .#default` passes
- alias outputs preserved unless intentionally removed
- for `nixpkg-claude-code`, upstream prebuilt binaries replace Bun runtime packaging and `cc` remains as a wrapper alias with `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=true`
