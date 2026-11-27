# nixpkgs

Meta-flake for independent Nix package and repack repositories under `RogerNavelsaker/nixpkg-*`.

Each package remains an independent Git repository. This flake composes one input per public `nixpkg-*` repository (78 at last sync) under one flake and shares a locked Nixpkgs revision wherever a package flake declares a Nixpkgs input. Repositories excluded from distribution or scheduled for retirement are omitted.

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

## Central CI and sync framework

Every `nixpkg-*` repo calls reusable workflows from this repo instead of carrying its own copy.

- `.github/workflows/reusable-ci.yml`: checks out the caller (full history), installs Nix, sets up Cachix `rogernavelsaker`, runs `ci/check-sync.sh`, `nix flake check`, `nix build .#default`.
- `.github/workflows/reusable-sync-upstream.yml`: runs the caller's sync step (`ci/sync-update.sh`), builds `.#default` first, commits `chore: sync upstream <version>` to the default branch only when the build passes, runs `ci/check-sync.sh` (a stale version fails the run), then dispatches `nixpkg-updated` here when `META_FLAKE_DISPATCH_TOKEN` exists (otherwise skips).
- `ci/check-sync.sh` reads the caller's `.nixpkg-sync.json`: `kind` (`git-tag|github-release|npm|pypi|git-head|none`), `upstream` (git URL, `owner/repo`, npm or pypi name), `tag_regex`, `tag_prefix`, `version_file` with `version_jq` or `version_grep`, `pinned_paths[]`, optional `pinned_flake_regex`, `sync_script`, `cachix_name`, `sync_workflow`. Kind `none` keeps the structural checks and skips version checks. `CHECK_OFFLINE=1` skips network checks; `BASE_REF` enables bump-on-change.
- `ci/templates/` holds the thin callers; `ci/migrate-repo.sh <repo-path>` writes them plus a `.nixpkg-sync.json` skeleton (idempotent, no network). Callers must grant `permissions: contents: write` for sync and pass `secrets: inherit`.
- `ci/test-check-sync.sh` runs offline fixtures for each kind and one induced failure per structural check.
- `ci/sync-github-release.sh` syncs GitHub-release-tarball repos (the `*craft` family, upstream `storytold/<name>`). It resolves the latest release (`gh release view`, else `git ls-remote --tags`), skips when current or older, prefetches the asset with `nix store prefetch-file --json` (a missing asset exits non-zero), and rewrites `nix/package-manifest.json` with `jq` (`version`, `tag`, `archive`, `url`, `hash`, `package.version`). Both `.source.*` and `.upstream.*` schemas are autodetected; `MANIFEST` overrides the manifest path.
- `sync-update.sh` exports `NIXPKG_CI_DIR` (the staged `ci/` directory). Caller contract in `.nixpkg-sync.json`: `"kind": "github-release"` and `"sync_script": "bash \"$NIXPKG_CI_DIR/sync-github-release.sh\""`.
- `ci/test-sync-github-release.sh` runs offline tests (stub `gh`/`nix`/`git` on `PATH`) for both schemas, up-to-date, missing asset, and the git fallback.
- Parked repos, unblock conditions, and the Retired section (17 Dicklesworthstone-based repos, reason "archived: upkeep burden and no downstream usage"): `docs/blocked-upstream.md`. Retired repos are listed in `scripts/meta-flake-exclude.txt`.

Callers reference `@main`, so merging here changes every repo's CI. This repo is public, so public callers need no Actions-access setting; a private caller needs Settings → Actions → General → Access set to allow access from repositories in the owner account.
