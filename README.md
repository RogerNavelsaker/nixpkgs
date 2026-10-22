# nixpkgs

Meta-flake for the independent Nix packaging repositories under `RogerNavelsaker/*`.

Each package remains an independent Git repository with its own release cycle, packaging logic, and upstream tracking. This repository declares package flakes as inputs and aggregates selected outputs. It owns the shared, locked Nixpkgs input; package inputs use `follows = "nixpkgs"` so aggregate evaluation shares that exact node.

## Current aggregate

The meta-flake migration is in progress. Current image inputs are `nixpkg-valkey`, `nixpkg-vaultwarden`, `nixpkg-postgresql`, and `nixpkg-searxng`, exported as `packages.x86_64-linux.{valkey,vaultwarden,postgresql,searxng}-image`. Add the remaining package repositories after their flakes and public remotes exist; do not recreate the old local symlink layout.

```sh
nix flake show
nix build .#valkey-image
nix flake check
```

`flake.lock` pins the shared Nixpkgs revision and each package input revision. A package repository can still build standalone with its own lockfile; when consumed here, its Nixpkgs input follows the meta-flake's pin.

## Repository conventions

- Package repositories remain separate Git repositories with `main` as their packaging branch.
- Keep package flakes reproducible and independent; use the aggregate flake for shared-input composition and selected combined outputs.
- Checkout repositories as siblings under `RogerNavelsaker/`; do not symlink them into this meta-repo.
- Keep packaging concerns separate from upstream source forks and runtime/source repos.
- Prefer stable `sync:source` workflows in individual package repos.

## Related Meta Projects

- [nix-repos](https://github.com/RogerNavelsaker/nix-repos) for Nix workspace tooling, shared config, and repository orchestration
- [runtime-intel](https://github.com/RogerNavelsaker/runtime-intel) for the binary/source side of runtime integration tooling
