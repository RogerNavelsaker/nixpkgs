{
  description = "Meta-flake for RogerNavelsaker Nix packaging repositories";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    valkey.url = "github:RogerNavelsaker/nixpkg-valkey";
    valkey.inputs.nixpkgs.follows = "nixpkgs";

    vaultwarden.url = "github:RogerNavelsaker/nixpkg-vaultwarden";
    vaultwarden.inputs.nixpkgs.follows = "nixpkgs";

    postgresql.url = "github:RogerNavelsaker/nixpkg-postgresql";
    postgresql.inputs.nixpkgs.follows = "nixpkgs";

    searxng.url = "github:RogerNavelsaker/nixpkg-searxng";
    searxng.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { valkey, vaultwarden, postgresql, searxng, ... }:
    let
      system = "x86_64-linux";
    in {
      packages.${system} = {
        valkey-image = valkey.packages.${system}.image;
        vaultwarden-image = vaultwarden.packages.${system}.image;
        postgresql-image = postgresql.packages.${system}.image;
        searxng-image = searxng.packages.${system}.image;
      };
      checks.${system} = {
        valkey-image = valkey.checks.${system}.image;
        vaultwarden-image = vaultwarden.checks.${system}.image;
        postgresql-image = postgresql.checks.${system}.image;
        searxng-image = searxng.checks.${system}.image;
      };
    };
}
