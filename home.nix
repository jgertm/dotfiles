{ ... }:

{
  imports = [
    ./modules/agents.nix
    ./modules/devtools.nix
    ./modules/emacs.nix
    ./modules/firefox.nix
    ./modules/git.nix
    ./modules/macos.nix
    ./modules/shell.nix
    ./modules/terminal.nix
  ];

  # Keep this at the version used for the first activation of this configuration.
  home.stateVersion = "26.05";

  programs.home-manager.enable = true;

  programs.vim.enable = true;
}
