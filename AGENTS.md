# AGENTS.md

## Workspace Overview

This workspace is the packaging layer for the `nixpkg-*` family. Each local clone owns Nix packaging, wrapper behavior, lockfiles, and upstream sync logic for one tool or tool family.

## Packaging Policy

- Upstream sync is intended to point at a real upstream source, not a local folder mirror.
- Preferred remote upstreams are GitHub, npm, PyPI, crates.io, or another canonical registry/release source.
- Many vendored or GitHub-synced repos in this workspace trace back to upstreams under `RogerNavelsaker`, `Dicklesworthstone`, or `Jayminwest`.
- Package manifests should stay 1:1 with upstream metadata and source selection.
- Upstream name, version, revision, release channel, and source type should describe the real upstream artifact being packaged, not a local reinterpretation.
- Local packaging adjustments belong in Nix, wrappers, aliases, outputs, or package revision fields, not by mutating manifest identity away from upstream.
- JavaScript/TypeScript packaging should generally converge toward Bun single-executable outputs.
- `nixpkg-gemini` is the reference pattern for Bun single-binary packaging and for using a two-stage Nix build when it improves packaging reliability.
- If upstream already ships usable native binaries, package those binaries directly instead of recompiling them.
- `nixpkg-claude-code` is the reference pattern for preferring upstream compiled binaries when they are available.
- `nixpkg-codex` is the reference pattern for extracting upstream native platform binaries from npm packages using a `bundledBinaryPackageMap` and `postBuild` copy pattern.
- Two-stage Nix packaging is preferred when it makes vendoring, patching, bundling, or standalone compilation more robust.
- Two-stage Nix packaging is preferred when upstream repos carry CI, website, test, or release-only baggage that is not part of the packaged artifact.
- For Rust packages with sibling path dependencies, use a `runCommand` staging derivation to assemble all required siblings before `rustPlatform.buildRustPackage`. The `sourceRoot` attribute selects the main crate inside the assembled tree.
- For `[patch.*]` sections in `Cargo.toml` that redirect git or registry deps to local paths, every referenced sibling directory must appear as a `fetchFromGitHub` in the Nix expression and be staged alongside the main source before the build.
- Bun JS/TS apps that cannot be packaged as native binaries should use `bun build --compile` with an explicit per-platform `bunCompileTargetMap` rather than wrapping a `bun <entrypoint>` shell call.
- Packaging should narrow the build input to the minimum upstream surface needed for the artifact, so packaging correctness does not depend on upstream CI/CD assumptions.
- The repo matrix below records confirmed current state from this checkout; it does not imply every repo is already at the desired target state.

## Confirmed Repo Matrix

- `nixpkg-automated-plan-reviser-pro`
  Language: not confirmed from repo-local manifests at the workspace root.
  Packaging: Nix packaging repo for `automated_plan_reviser_pro`.
  Upstream sync: no explicit repo-root sync script confirmed.

- `nixpkg-beads-rust`
  Language: Rust confirmed via multiple `Cargo.toml` files under `upstream/` and `frankensqlite/`.
  Packaging: Nix packaging repo for `beads_rust`. Two-stage build: `fetchFromGitHub` fetches main source and `frankensqlite` sibling; `runCommand` assembles the tree; `rustPlatform.buildRustPackage` builds from `source/beads_rust`.
  Upstream sync: no explicit repo-root sync script confirmed; source pinned via `fetchFromGitHub` in `nix/package-manifest.json`.

- `nixpkg-beads-viewer`
  Language: mixed Go and Rust confirmed via `upstream/go.mod` and Rust `Cargo.toml` files.
  Packaging: Nix packaging repo for `beads_viewer`.
  Upstream sync: no explicit repo-root sync script confirmed; upstream is vendored in-tree.

- `nixpkg-canopy`
  Language: Node/Bun confirmed via root `package.json`.
  Packaging: Nix packaging repo for `@os-eco/canopy-cli`.
  Upstream sync: active lane `sync:source = bun run sync:npm-source`; alternate lane `sync:github-source`.

- `nixpkg-cass-memory-system`
  Language: Node/Bun confirmed via `upstream/package.json`.
  Packaging: Nix packaging repo for `cass_memory_system`.
  Upstream sync: no explicit repo-root sync script confirmed; upstream is vendored in-tree.

- `nixpkg-claude-agent-acp`
  Language: Node/Bun confirmed via root `package.json`.
  Packaging: local Nix packaging scaffold for `@agentclientprotocol/claude-agent-acp`.
  Upstream sync: active lane `sync:source = bun run sync:npm-source`; alternate lane `sync:github-source`.

- `nixpkg-claude-code`
  Language: Node/Bun dispatcher packaging confirmed via root `package.json`; packaged output is upstream native per-platform binaries.
  Packaging: Nix packaging repo for `@anthropic-ai/claude-code`, exposing `claude` and `cc`.
  Upstream sync: active lane `sync:source = bun run sync:npm-source`; alternate lane `sync:github-source`.

- `nixpkg-code-intel-rust`
  Language: Node/Bun packaging scaffold confirmed via root `package.json`; upstream tool language is not confirmed from the root manifest alone.
  Packaging: Nix packaging repo for Rust code-intelligence tooling.
  Upstream sync: no explicit repo-root sync script confirmed.

- `nixpkg-code-intel-ts`
  Language: Node/Bun packaging scaffold confirmed via root `package.json`.
  Packaging: Nix packaging repo for TypeScript code-intelligence tooling.
  Upstream sync: no explicit repo-root sync script confirmed.

- `nixpkg-codex`
  Language: Node/Bun dispatcher packaging confirmed via root `package.json`; packaged output includes upstream native artifacts.
  Packaging: Nix packaging repo for `@openai/codex`.
  Upstream sync: active lane `sync:source = bun run sync:npm-source`; alternate lane `sync:github-source`.

- `nixpkg-codex-acp`
  Language: Node/Bun confirmed via root `package.json`.
  Packaging: local Nix packaging scaffold for `@zed-industries/codex-acp`.
  Upstream sync: active lane `sync:source = bun run sync:npm-source`; alternate lane `sync:github-source`.

- `nixpkg-coding-agent-account-manager`
  Language: mixed Go and Node confirmed via `upstream/go.mod` and `upstream/web/dashboard/package.json`.
  Packaging: Nix packaging repo for `coding_agent_account_manager`.
  Upstream sync: no explicit repo-root sync script confirmed; upstream is vendored in-tree.

- `nixpkg-coding-agent-session-search`
  Language: mixed Rust, Python, and Node confirmed via `Cargo.toml`, `pyproject.toml`, and `package.json` files in-tree.
  Packaging: Nix packaging repo for `coding_agent_session_search`. Two-stage build: `fetchFromGitHub` fetches main source plus `frankensqlite` and `franken_agent_detection` siblings (required by `[patch.*]` sections); `runCommand` assembles the tree; `rustPlatform.buildRustPackage` builds from `source/upstream`.
  Upstream sync: no explicit repo-root sync script confirmed; source pinned via `fetchFromGitHub` in `nix/package-manifest.json`.

- `nixpkg-context-mode-cli`
  Language: Node/Bun confirmed via `upstream/package.json`.
  Packaging: thin Nix packaging repo for `context-mode-cli`.
  Upstream sync: `scripts/sync-from-upstream.sh` currently syncs from local or cloned `@runtime-intel/context-mode-cli` Git source; target policy prefers a configurable remote upstream instead of a local-folder default.

- `nixpkg-context-mode-mcp`
  Language: Node/Bun package shape confirmed by Bun-based flake and generated lock workflow; root upstream manifest is managed through `bun.lock`/`bun.nix`.
  Packaging: thin Nix packaging repo for `context-mode-mcp`.
  Upstream sync: `scripts/sync-from-upstream.sh` syncs the latest GitHub tag from the owner/repo stored in `nix/package-manifest.json`.

- `nixpkg-cross-agent-session-resumer`
  Language: Rust confirmed via `upstream/Cargo.toml`.
  Packaging: Nix packaging repo for `cross_agent_session_resumer`.
  Upstream sync: no explicit repo-root sync script confirmed; upstream is vendored in-tree.

- `nixpkg-destructive-command-guard`
  Language: Rust confirmed via `upstream/Cargo.toml`.
  Packaging: Nix packaging repo for `destructive_command_guard`.
  Upstream sync: no explicit repo-root sync script confirmed; upstream is vendored in-tree.

- `nixpkg-gemini`
  Language: Node/Bun confirmed via root `package.json`.
  Packaging: Nix packaging repo for Gemini CLI.
  Upstream sync: active lane `sync:source = bun run sync:github-source`; npm lane remains available as `sync:npm-source`.

- `nixpkg-jcodemunch`
  Language: Python package consumption confirmed indirectly via `uvx jcodemunch-mcp` in `flake.nix`.
  Packaging: thin Nix wrapper for the `jcodemunch-mcp` server.
  Upstream sync: no repo-local sync script; upstream package is resolved at runtime via `uvx`.

- `nixpkg-jdocmunch`
  Language: Python package consumption confirmed indirectly via `uvx jdocmunch-mcp` in `flake.nix`.
  Packaging: thin Nix wrapper for the `jdocmunch-mcp` server.
  Upstream sync: no repo-local sync script; upstream package is resolved at runtime via `uvx`.

- `nixpkg-lean-ctx`
  Language: Rust confirmed via `rustPlatform.buildRustPackage` and `sourceRoot = "source/rust"` in `flake.nix`.
  Packaging: Nix packaging repo for `lean-ctx`.
  Upstream sync: `scripts/update-upstream.sh` syncs from GitHub releases/tags on `yvgude/lean-ctx`.

- `nixpkg-linehash-edit`
  Language: Rust confirmed via `buildRustPackage` in `flake.nix`.
  Packaging: Nix packaging repo for `linehash-edit`, exposing `linehash-edit` and `le`.
  Upstream sync: no repo-local sync script; source is pinned directly as flake input `github:RogerNavelsaker/linehash-edit`.

- `nixpkg-mcp-agent-mail-rust`
  Language: mixed Rust and Node confirmed via many `Cargo.toml` files and in-tree `package.json` files.
  Packaging: Nix packaging repo for `mcp_agent_mail_rust`. Two-stage build: `fetchFromGitHub` fetches main source plus `asupersync`, `beads_rust`, `frankensqlite`, `frankentui`, and `sqlmodel_rust` siblings (all required by `[patch.crates-io]` sections); `runCommand` assembles the tree; `rustPlatform.buildRustPackage` builds from `source/upstream`.
  Upstream sync: no explicit repo-root sync script confirmed; source pinned via `fetchFromGitHub` in `nix/package-manifest.json`.

- `nixpkg-mcp-communicator-telegram`
  Language: Node/Bun confirmed via root `package.json`.
  Packaging: Nix packaging repo for `mcp-communicator-telegram`.
  Upstream sync: active lane `sync:source = bun run sync:npm-source`; alternate lane `sync:github-source`.

- `nixpkg-mcp-nixos-cli`
  Language: Node/Bun confirmed via `upstream/package.json`.
  Packaging: thin Nix packaging repo for `nixos-cli`.
  Upstream sync: `scripts/sync-from-upstream.sh` currently syncs from local or cloned `@runtime-intel/nixos-cli` Git source; target policy prefers a configurable remote upstream instead of a local-folder default.

- `nixpkg-meta-skill`
  Language: Rust confirmed via `upstream/Cargo.toml`.
  Packaging: Nix packaging repo for `meta_skill`.
  Upstream sync: no explicit repo-root sync script confirmed; upstream is vendored in-tree.

- `nixpkg-mulch`
  Language: Node/Bun confirmed via root `package.json`.
  Packaging: Nix packaging repo for `@os-eco/mulch-cli`.
  Upstream sync: active lane `sync:source = bun run sync:npm-source`; alternate lane `sync:github-source`.

- `nixpkg-named-tmux-manager`
  Language: mixed Go and Node confirmed via `upstream/go.mod` and `upstream/package.json`.
  Packaging: Nix packaging repo for `ntm`.
  Upstream sync: no explicit repo-root sync script confirmed; upstream is vendored in-tree.

- `nixpkg-overstory`
  Language: Node/Bun confirmed via root `package.json`.
  Packaging: Nix packaging repo for `@os-eco/overstory-cli`.
  Upstream sync: active lane `sync:source = bun run sync:npm-source`; alternate lane `sync:github-source`.

- `nixpkg-pi-coding-agent`
  Language: Node/Bun confirmed via root `package.json`.
  Packaging: Nix packaging repo for `@mariozechner/pi-coding-agent`.
  Upstream sync: active lane `sync:source = bun run sync:npm-source`; alternate lane `sync:github-source`.

- `nixpkg-pi-coding-agent-rust`
  Language: Rust confirmed via `upstream/Cargo.toml`.
  Packaging: Nix packaging repo for `pi_agent_rust`.
  Upstream sync: no explicit repo-root sync script confirmed; upstream is vendored in-tree.

- `nixpkg-process-triage`
  Language: Rust confirmed via `upstream/Cargo.toml`.
  Packaging: Nix packaging repo for `process_triage`.
  Upstream sync: no explicit repo-root sync script confirmed; upstream is vendored in-tree.

- `nixpkg-repo-map`
  Language: Node/Bun packaging scaffold confirmed via root `package.json`.
  Packaging: Nix packaging repo for repository mapping tooling.
  Upstream sync: no explicit repo-root sync script confirmed.

- `nixpkg-repo-updater`
  Language: not confirmed from repo-local manifests at the workspace root.
  Packaging: Nix packaging repo for `repo_updater`.
  Upstream sync: no explicit repo-root sync script confirmed.

- `nixpkg-seeds`
  Language: Node/Bun confirmed via root `package.json`.
  Packaging: Nix packaging repo for `@os-eco/seeds-cli`.
  Upstream sync: active lane `sync:source = bun run sync:github-source`; npm lane remains available as `sync:npm-source`.

- `nixpkg-simultaneous-launch-button`
  Language: Go confirmed via `upstream/go.mod`.
  Packaging: Nix packaging repo for `simultaneous_launch_button`.
  Upstream sync: no explicit repo-root sync script confirmed; upstream is vendored in-tree.

- `nixpkg-toolflow-mcp`
  Language: Node/Bun packaging lane confirmed via Bun-based flake and `nix/package.nix`.
  Packaging: thin Nix packaging repo for `toolflow-mcp` and the `toolflow`/`tf` binaries.
  Upstream sync: `scripts/sync-from-upstream.sh` syncs the latest GitHub tag from the owner/repo stored in `nix/package-manifest.json`.

- `nixpkg-toon-rust`
  Language: Rust confirmed via `upstream/Cargo.toml`.
  Packaging: Nix packaging repo for `toon_rust`.
  Upstream sync: no explicit repo-root sync script confirmed; upstream is vendored in-tree.

- `nixpkg-trellis`
  Language: Node/Bun confirmed via root `package.json`.
  Packaging: Nix packaging repo for `@os-eco/trellis-cli`.
  Upstream sync: active lane `sync:source = bun run sync:github-release`; alternate lanes `sync:github-source` and `sync:npm-source`.

- `nixpkg-ultimate-bug-scanner`
  Language: Python confirmed via `upstream/pyproject.toml`; test fixtures also include Go and Rust.
  Packaging: Nix packaging repo for `ultimate_bug_scanner`.
  Upstream sync: no explicit repo-root sync script confirmed; upstream is vendored in-tree.

## Local Clone Status

Confirmed: every top-level `nixpkg-*` folder currently present in this workspace is a local git clone.

Confirmed local git clones from the workspace inventory:

- `nixpkg-automated-plan-reviser-pro`
- `nixpkg-beads-rust`
- `nixpkg-beads-viewer`
- `nixpkg-canopy`
- `nixpkg-cass-memory-system`
- `nixpkg-claude-agent-acp`
- `nixpkg-claude-code`
- `nixpkg-code-intel-rust`
- `nixpkg-code-intel-ts`
- `nixpkg-codex`
- `nixpkg-codex-acp`
- `nixpkg-coding-agent-account-manager`
- `nixpkg-coding-agent-session-search`
- `nixpkg-context-mode-cli`
- `nixpkg-context-mode-mcp`
- `nixpkg-cross-agent-session-resumer`
- `nixpkg-destructive-command-guard`
- `nixpkg-gemini`
- `nixpkg-jcodemunch`
- `nixpkg-jdocmunch`
- `nixpkg-lean-ctx`
- `nixpkg-linehash-edit`
- `nixpkg-mcp-agent-mail-rust`
- `nixpkg-mcp-communicator-telegram`
- `nixpkg-mcp-nixos-cli`
- `nixpkg-meta-skill`
- `nixpkg-mulch`
- `nixpkg-named-tmux-manager`
- `nixpkg-overstory`
- `nixpkg-pi-coding-agent`
- `nixpkg-pi-coding-agent-rust`
- `nixpkg-process-triage`
- `nixpkg-repo-map`
- `nixpkg-repo-updater`
- `nixpkg-seeds`
- `nixpkg-simultaneous-launch-button`
- `nixpkg-toolflow-mcp`
- `nixpkg-toon-rust`
- `nixpkg-trellis`
- `nixpkg-ultimate-bug-scanner`

## Notes For Agents

- Use this workspace as the meta-layer, not the source-of-truth for every underlying package implementation.
- Repo-local `README.md`, `flake.nix`, lockfiles, `nix/package.nix`, and sync scripts are the authoritative packaging references for each child repo.
- Where `Language` says `not confirmed`, that means I did not find a repo-local manifest that proves the implementation language from this checkout alone.
- Where `Upstream sync` says `no explicit repo-root sync script confirmed`, that means I did not find a repo-local sync script that cleanly identifies the active upstream lane.
- Treat the `Packaging Policy` section as the desired convergence target when evolving these repos.
