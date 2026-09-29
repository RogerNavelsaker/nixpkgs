{ inputs, pkgs, ... }:

let
  system = pkgs.stdenv.hostPlatform.system;
in
{
  packages = [
    inputs.automated-plan-reviser-pro.packages.${system}.default
    inputs.beads-rust.packages.${system}.default
    inputs.beads-viewer.packages.${system}.default
    inputs.cass-memory-system.packages.${system}.default
    inputs.coding-agent-session-search.packages.${system}.default
    inputs.coding-agent-account-manager.packages.${system}.default
    inputs.cross-agent-session-resumer.packages.${system}.default
    inputs.destructive-command-guard.packages.${system}.default
    inputs."mcp-agent-mail-rust".packages.${system}.default
    inputs."meta-skill".packages.${system}.default
    inputs."named-tmux-manager".packages.${system}.default
    inputs."pi-coding-agent-rust".packages.${system}.default
    inputs."process-triage".packages.${system}.default
    inputs."repo-updater".packages.${system}.default
    inputs."simultaneous-launch-button".packages.${system}.default
    inputs."toon-rust".packages.${system}.default
    inputs."ultimate-bug-scanner".packages.${system}.default
  ];

  env.TERM = "xterm-256color";
}
