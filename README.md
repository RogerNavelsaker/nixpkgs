# nixpkgs

Meta-project for the Nix packaging repos under `RogerNavelsaker/*`.

This repo is the shared workspace entrypoint for the packaging layer. The underlying projects keep their own release cycle, Nix packaging logic, and upstream tracking, while this repo provides the cross-repo shell, workspace file, and bootstrap scripts.

## Repositories

| Repository | Focus |
| --- | --- |
| [nixpkg-canopy](https://github.com/RogerNavelsaker/nixpkg-canopy) | Packaging repo for `@os-eco/canopy-cli` |
| [nixpkg-automated-plan-reviser-pro](https://github.com/RogerNavelsaker/nixpkg-automated-plan-reviser-pro) | Packaging repo for `automated_plan_reviser_pro` |
| [nixpkg-beads-rust](https://github.com/RogerNavelsaker/nixpkg-beads-rust) | Packaging repo for `beads_rust` |
| [nixpkg-beads-viewer](https://github.com/RogerNavelsaker/nixpkg-beads-viewer) | Packaging repo for `beads_viewer` |
| [nixpkg-cass-memory-system](https://github.com/RogerNavelsaker/nixpkg-cass-memory-system) | Packaging repo for `cass_memory_system` |
| [nixpkg-coding-agent-account-manager](https://github.com/RogerNavelsaker/nixpkg-coding-agent-account-manager) | Packaging repo for `coding_agent_account_manager` |
| [nixpkg-coding-agent-session-search](https://github.com/RogerNavelsaker/nixpkg-coding-agent-session-search) | Packaging repo for `coding_agent_session_search` |
| [nixpkg-claude-code](https://github.com/RogerNavelsaker/nixpkg-claude-code) | Packaging and wrapper repo for Claude Code |
| `nixpkg-claude-agent-acp` | Local packaging scaffold for `@agentclientprotocol/claude-agent-acp` (not published yet) |
| [nixpkg-code-intel-rust](https://github.com/RogerNavelsaker/nixpkg-code-intel-rust) | Packaging repo for Rust code-intelligence tooling |
| [nixpkg-code-intel-ts](https://github.com/RogerNavelsaker/nixpkg-code-intel-ts) | Packaging repo for TypeScript code-intelligence tooling |
| [nixpkg-codex](https://github.com/RogerNavelsaker/nixpkg-codex) | Packaging and wrapper repo for Codex |
| `nixpkg-codex-acp` | Local packaging scaffold for `@zed-industries/codex-acp` (not published yet) |
| [nixpkg-context-mode-cli](https://github.com/RogerNavelsaker/nixpkg-context-mode-cli) | Packaging repo for `context-mode-cli` |
| [nixpkg-context-mode-mcp](https://github.com/RogerNavelsaker/nixpkg-context-mode-mcp) | Packaging repo for `context-mode-mcp` |
| [nixpkg-cross-agent-session-resumer](https://github.com/RogerNavelsaker/nixpkg-cross-agent-session-resumer) | Packaging repo for `cross_agent_session_resumer` |
| [nixpkg-destructive-command-guard](https://github.com/RogerNavelsaker/nixpkg-destructive-command-guard) | Packaging repo for `destructive_command_guard` |
| [nixpkg-gemini](https://github.com/RogerNavelsaker/nixpkg-gemini) | Packaging and wrapper repo for Gemini CLI |
| [nixpkg-jcodemunch](https://github.com/RogerNavelsaker/nixpkg-jcodemunch) | Packaging wrapper for the `jcodemunch-mcp` server |
| [nixpkg-jdocmunch](https://github.com/RogerNavelsaker/nixpkg-jdocmunch) | Packaging wrapper for the `jdocmunch-mcp` server |
| [nixpkg-lean-ctx](https://github.com/RogerNavelsaker/nixpkg-lean-ctx) | Packaging repo for `lean-ctx` |
| [nixpkg-linehash-edit](https://github.com/RogerNavelsaker/nixpkg-linehash-edit) | Packaging repo for `linehash-edit`, exposing `linehash-edit` and `le` |
| [nixpkg-mcp-agent-mail-rust](https://github.com/RogerNavelsaker/nixpkg-mcp-agent-mail-rust) | Packaging repo for `mcp_agent_mail_rust` |
| [nixpkg-mcp-communicator-telegram](https://github.com/RogerNavelsaker/nixpkg-mcp-communicator-telegram) | Packaging repo for `mcp-communicator-telegram` |
| [nixpkg-meta-skill](https://github.com/RogerNavelsaker/nixpkg-meta-skill) | Packaging repo for `meta_skill` |
| [nixpkg-mulch](https://github.com/RogerNavelsaker/nixpkg-mulch) | Packaging repo for `@os-eco/mulch-cli` |
| [nixpkg-mcp-nixos-cli](https://github.com/RogerNavelsaker/nixpkg-mcp-nixos-cli) | Packaging repo for `nixos-cli` |
| [nixpkg-named-tmux-manager](https://github.com/RogerNavelsaker/nixpkg-named-tmux-manager) | Packaging repo for `ntm` |
| [nixpkg-seeds](https://github.com/RogerNavelsaker/nixpkg-seeds) | Packaging repo for `@os-eco/seeds-cli` |
| [nixpkg-toon-rust](https://github.com/RogerNavelsaker/nixpkg-toon-rust) | Packaging repo for `toon_rust` |
| [nixpkg-overstory](https://github.com/RogerNavelsaker/nixpkg-overstory) | Packaging repo for `@os-eco/overstory-cli` |
| [nixpkg-pi-coding-agent-rust](https://github.com/RogerNavelsaker/nixpkg-pi-coding-agent-rust) | Packaging repo for `pi_agent_rust` |
| [nixpkg-pi-coding-agent](https://github.com/RogerNavelsaker/nixpkg-pi-coding-agent) | Generic Pi packaging repo |
| [nixpkg-process-triage](https://github.com/RogerNavelsaker/nixpkg-process-triage) | Packaging repo for `process_triage` |
| [nixpkg-repo-updater](https://github.com/RogerNavelsaker/nixpkg-repo-updater) | Packaging repo for `repo_updater` |
| [nixpkg-repo-map](https://github.com/RogerNavelsaker/nixpkg-repo-map) | Packaging repo for repository mapping tooling |
| [nixpkg-simultaneous-launch-button](https://github.com/RogerNavelsaker/nixpkg-simultaneous-launch-button) | Packaging repo for `simultaneous_launch_button` |
| [nixpkg-toolflow-mcp](https://github.com/RogerNavelsaker/nixpkg-toolflow-mcp) | Packaging repo for `toolflow-mcp` and the `toolflow` binary |
| [nixpkg-trellis](https://github.com/RogerNavelsaker/nixpkg-trellis) | Packaging repo for `@os-eco/trellis-cli` |
| [nixpkg-ultimate-bug-scanner](https://github.com/RogerNavelsaker/nixpkg-ultimate-bug-scanner) | Packaging repo for `ultimate_bug_scanner` |

## Scope

- Keep packaging concerns separate from upstream source forks and runtime/source repos
- Track wrapper-specific Nix expressions, manifests, and generated dependency locks
- Make it easier to see the full packaging surface in one place

## Source Lane Convention

- Prefer a stable `sync:source` script in packaging repos.
- Point `sync:source` at the currently active upstream lane such as `sync:npm-source` or `sync:github-source`.
- Keep inactive upstream lanes present but disabled in workflows so source-of-truth changes are a small swap instead of a redesign.
- Document the active lane in repo-local README files when a future source swap is likely.

## Shared Workspace

- Preferred layout: clone this repo as `~/Repositories/@nixpkgs` and keep the underlying repos as ignored child directories inside `@nixpkgs/`
- Shell: Flox + `direnv` via [manifest.toml](/home/rona/Repositories/@nixpkgs/.flox/env/manifest.toml) and [.envrc](/home/rona/Repositories/@nixpkgs/.envrc)
- Workspace file: [nixpkgs.code-workspace](/home/rona/Repositories/@nixpkgs/nixpkgs.code-workspace)
- Sample repo-local Flox manifest for the flywheel stack: [samples/agentic-flywheel-stack.manifest.toml](/home/rona/Repositories/@nixpkgs/samples/agentic-flywheel-stack.manifest.toml)
- Bootstrap missing sibling repos with `./scripts/bootstrap`
- Inspect workspace state with `./scripts/status`
- Submodules are intentionally not used

## Related Meta Projects

- [nix-repos](https://github.com/RogerNavelsaker/nix-repos) for Nix workspace tooling, shared config, and repository orchestration
- [runtime-intel](https://github.com/RogerNavelsaker/runtime-intel) for the binary/source side of runtime integration tooling
