# Blocked upstream repos

Parked repos stay in the meta-flake and Cachix. Callers exclude them from version-sync until the blocker clears.

| Repo | Blocker | Unblock condition |
|---|---|---|
| `nixpkg-beeper-desktop-cli` | Upstream v0.6.4 is a TS/bun monorepo with no `go.mod`; the Go packaging no longer applies. | Repackage for the bun monorepo, or pin a pre-monorepo Go tag. |
| `nixpkg-coding-agent-session-search` | `cargoHash` `sha256-ylqq6dZeexeaZi2/Pn2WUjVzobsLF6Twl4lKau4hV3E=` is fine, but the `franken_agent_detection` sibling is at rev `a0dd013` while the pin is `35049431`. | Align the sibling pin with the rev upstream expects, then refresh `cargoHash`. |
| `nixpkg-beads-rust` | Needs rustc 1.100; nixpkgs unstable ships 1.99.1. The `sourceRoot` name also has a bug. | nixpkgs reaches rustc >= 1.100, and the `sourceRoot` name is fixed. |
| `nixpkg-pi-coding-agent-rust` | Upstream E0631 at `src/tools/structured_json.rs:676`. Packaging edits are uncommitted in its `fix/ci-green` worktree. | Upstream fixes E0631 (or a patch is carried), and the packaging edits are committed from `fix/ci-green`. |
| `nixpkg-process-triage` | Pinned `crates/pt-core` references `crate::config::validation`, which `config/mod.rs` lacks. | Pin an upstream rev where `config/mod.rs` declares `validation`. |
| `nixpkg-mcp-agent-mail-rust` | Git dep `frankensearch@616c9a7` fails `cargo vendor` on workspace inheritance. | Bump `frankensearch` to a rev that vendors cleanly, or stage it as a sibling per the Rust sibling-path pattern in `AGENTS.md`. |
| `nixpkg-destructive-command-guard` | PR #18 is open; CI fails with E0716 at upstream `src/packs/core/filesystem.rs:6112` under the current rustc. | Upstream fixes E0716 (or the build pins an older rustc), and PR #18 merges with green CI. |

## Excluded from the meta-flake

See `scripts/meta-flake-exclude.txt` for per-repo reasons (for example `nixpkg-infisical`: archived upstream, licence).
