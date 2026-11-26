# nixpkgs

Meta-flake for independent Nix package and repack repositories under `RogerNavelsaker/nixpkg-*`.

Each package remains an independent Git repository. This flake composes one input per public `nixpkg-*` repository (78 at last sync) output sets under one input and shares a locked Nixpkgs revision wherever a package flake declares a Nixpkgs input. Repositories excluded from distribution or scheduled for retirement are omitted.

## Package outputs
The public output is a flat set of first-party packages, named after their package repositories:

```sh
nix build .#nixpkgs.x86_64-linux.browser-cli
nix build .#nixpkgs.x86_64-linux.mulch
nix build .#nixpkgs.x86_64-linux.seeds
nix build .#nixpkgs.x86_64-linux.terrarium
```

Consumers can select individual packages with `inputs.roger-navelsaker.nixpkgs.${system}.browser-cli`. Each package output is selected lazily; evaluating one attribute does not traverse other package outputs. There is no legacy `packageSets` compatibility alias.


This flake aggregates Nix packages only. OCI images are published separately to GHCR and are not exposed or built here.

Inspect the aggregate with:

```sh
nix flake show
nix flake check
```

`flake.lock` pins the shared Nixpkgs revision and each package input revision. Individual repositories remain independently buildable with their own lockfiles.

## Repository conventions

- Package repositories remain independent Git repositories with `main` as their packaging branch.
- Keep package flakes reproducible; use this aggregate for shared-input composition and namespaced package outputs.
- Checkout repositories as siblings under `RogerNavelsaker/`; do not symlink them into this meta-repo.
- Keep packaging concerns separate from upstream source forks and runtime/source repos.
- Prefer stable `sync:source` workflows in individual package repos.

## Related Meta Projects

- [nix-repos](https://github.com/RogerNavelsaker/nix-repos) for Nix workspace tooling, shared config, and repository orchestration
- [runtime-intel](https://github.com/RogerNavelsaker/runtime-intel) for the binary/source side of runtime integration tooling

## Remote-only sync

Inputs are `github:RogerNavelsaker/nixpkg-*` only: no `path:` inputs and no tracked symlinks to local folders. `scripts/meta-flake-exclude.txt` lists repos skipped on purpose (private or broken); private repos are excluded by default because Nix cannot fetch them without a token.

- `scripts/sync-meta-flake.sh` lists public, non-archived remote `nixpkg-*` repos (`gh repo list`), adds missing inputs, drops stale ones, and runs `nix flake update` for those inputs only. The root `nixpkgs` pin stays untouched.
- `scripts/check-meta-flake.sh` fails on missing/stale inputs, `path:` inputs, tracked symlinks, or lock revs older than the remote HEAD by more than `CHECK_WINDOW_HOURS` (default 24). `CHECK_OFFLINE=1` skips the remote checks.
- `.github/workflows/sync-meta-flake.yml` runs hourly (`17 * * * *`), on `workflow_dispatch`, and on `repository_dispatch` type `nixpkg-updated`; it commits `flake.nix`/`flake.lock` to the default branch. Secret needed: `CACHIX_AUTH_TOKEN`.
- `.github/workflows/ci.yml` runs the check script and `nix flake check` on push and PR.

### Notifying this repo from a nixpkg-* repo (follow-up rollout)

Add as the last step of each package repo's sync workflow. Needs secret `META_FLAKE_DISPATCH_TOKEN` (PAT with `contents: write` on `RogerNavelsaker/nixpkgs`) in that repo:

```yaml
      - uses: peter-evans/repository-dispatch@v3
        with:
          token: ${{ secrets.META_FLAKE_DISPATCH_TOKEN }}
          repository: RogerNavelsaker/nixpkgs
          event-type: nixpkg-updated
          client-payload: '{"repo": "${{ github.event.repository.name }}"}'
```

Until a repo adopts this, the hourly schedule picks up its updates.
