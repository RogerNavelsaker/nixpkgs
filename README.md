# nixpkgs

Meta-flake for independent Nix package and repack repositories under `RogerNavelsaker/nixpkg-*`.

Each package remains an independent Git repository. This flake composes 77 package output sets under one input and shares a locked Nixpkgs revision wherever a package flake declares a Nixpkgs input. Repositories excluded from distribution or scheduled for retirement are omitted.

## Package outputs

Package outputs stay grouped by repository under the custom packageSets output, preserving each repository's native package names:

    nix build .#packageSets.x86_64-linux.nixpkg-caveman.default
    nix build .#packageSets.x86_64-linux.nixpkg-crawl4ai.default

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
