# TODO

## bun2nix Removal

Remove the `github:nix-community/bun2nix` flake input from all repos that still use it.
Completed repos use either `fetchurl` (native binaries) or a `deps` map in the manifest (compiled from source).

### Done

- [x] `nixpkg-claude-code`: fetchurl per-platform tarballs, no bun2nix
- [x] `nixpkg-codex`: fetchurl per-platform tarballs, no bun2nix
- [x] `nixpkg-codex-acp`: fetchurl per-platform tarballs, no bun2nix
- [x] `nixpkg-canopy`: manifest deps map + bun compile, no bun2nix
- [x] `nixpkg-mulch`: manifest deps map + bun compile, no bun2nix
- [x] `nixpkg-seeds`: manifest deps map + bun compile, no bun2nix
- [x] `nixpkg-trellis`: manifest deps map + bun compile, no bun2nix
- [x] `nixpkg-claude-agent-acp`: manifest deps map + bun compile, no bun2nix
- [x] `nixpkg-mcp-communicator-telegram`: manifest deps map + bun compile, no bun2nix

### Pending — GitHub-source, runtime bun apps

- [ ] `nixpkg-cass-memory-system`: runs bun at runtime, needs different approach
- [ ] `nixpkg-context-mode-cli`: runs bun at runtime, needs different approach
- [ ] `nixpkg-context-mode-mcp`: runs bun at runtime, needs different approach
- [ ] `nixpkg-mcp-nixos-cli`: runs bun at runtime, needs different approach
- [ ] `nixpkg-toolflow-mcp`: runs bun at runtime, needs different approach
- [ ] `nixpkg-overstory`: GitHub-source bun compile
- [ ] `nixpkg-pi-coding-agent`: GitHub-source bun compile

### Low priority

- [ ] `nixpkg-gemini`: already uses `buildNpmPackage`, bun2nix only in devShell

## Aligned Reference Patterns

- [x] `nixpkg-lean-ctx`: two-stage Rust packaging
- [x] `nixpkg-gemini`: two-stage npm/bun packaging via buildNpmPackage
- [x] `nixpkg-claude-code`: upstream native binary via fetchurl
- [x] `nixpkg-codex`: upstream native binary via fetchurl
- [x] `nixpkg-canopy`: npm tarball + manifest deps + bun compile
- [x] `nixpkg-mulch`: npm tarball + manifest deps + bun compile
- [x] `nixpkg-seeds`: GitHub source + manifest deps + bun compile
- [x] `nixpkg-trellis`: GitHub source + manifest deps + bun compile
