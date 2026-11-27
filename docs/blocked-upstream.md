# Blocked upstream repos

Parked repos stay in the meta-flake and Cachix. Retired repos are listed in the section below. Callers exclude them from version-sync until the blocker clears.

No repos are currently blocked.

## Resolved

- `nixpkg-aweb`: tracks git-head; nixpkgs lock gives Go 1.27.3. PR nixpkg-aweb#2.
- `nixpkg-bifrost`: upstream 2.7.0, patches dropped, Go 1.27.4 overlay. PR nixpkg-bifrost#2.
- `nixpkg-litellm`: 1.111.0, `litellm_cli` installed via `cli_package.py` preInstall. PR nixpkg-litellm#2.
- `nixpkg-beeper-desktop-cli`: packages prebuilt `beeper/cli` linux-x64 release binary, x86_64-linux only. PR nixpkg-beeper-desktop-cli#17.

## Excluded from the meta-flake

See `scripts/meta-flake-exclude.txt` for per-repo reasons (for example `nixpkg-infisical`: archived upstream, licence).

## Retired

Reason (user decision, 2026-11-27): "archived: upkeep burden and no downstream usage". These Dicklesworthstone-based repos left the meta-flake, are listed in `scripts/meta-flake-exclude.txt`, and are archived on GitHub.

- `nixpkg-automated-plan-reviser-pro`
- `nixpkg-beads-rust`
- `nixpkg-beads-viewer`
- `nixpkg-cass-memory-system`
- `nixpkg-coding-agent-account-manager`
- `nixpkg-coding-agent-session-search`
- `nixpkg-cross-agent-session-resumer`
- `nixpkg-destructive-command-guard`
- `nixpkg-mcp-agent-mail-rust`
- `nixpkg-meta-skill`
- `nixpkg-named-tmux-manager`
- `nixpkg-pi-coding-agent-rust`
- `nixpkg-process-triage`
- `nixpkg-repo-updater`
- `nixpkg-simultaneous-launch-button`
- `nixpkg-toon-rust`
- `nixpkg-ultimate-bug-scanner`

Formerly parked (blockers no longer apply):

| Repo | Last blocker |
|---|---|
| `nixpkg-coding-agent-session-search` | `cargoHash` `sha256-ylqq6dZeexeaZi2/Pn2WUjVzobsLF6Twl4lKau4hV3E=` is fine, but the `franken_agent_detection` sibling is at rev `a0dd013` while the pin is `35049431`. |
| `nixpkg-beads-rust` | Needs rustc 1.100; nixpkgs unstable ships 1.99.1. The `sourceRoot` name also has a bug. |
| `nixpkg-pi-coding-agent-rust` | Upstream E0631 at `src/tools/structured_json.rs:676`. Packaging edits are uncommitted in its `fix/ci-green` worktree. |
| `nixpkg-process-triage` | Pinned `crates/pt-core` references `crate::config::validation`, which `config/mod.rs` lacks. |
| `nixpkg-mcp-agent-mail-rust` | Git dep `frankensearch@616c9a7` fails `cargo vendor` on workspace inheritance. |
| `nixpkg-destructive-command-guard` | PR #18 is open; CI fails with E0716 at upstream `src/packs/core/filesystem.rs:6112` under the current rustc. |
