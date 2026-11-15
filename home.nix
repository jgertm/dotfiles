{ agentPaths, config, lib, pkgs, ... }:

{
  imports = [
    ./modules/aerospace.nix
    ./modules/agents.nix
    ./modules/devtools.nix
    ./modules/emacs.nix
    ./modules/firefox.nix
    ./modules/git.nix
    ./modules/macos.nix
    ./modules/shell.nix
    ./modules/terminal.nix
    ./modules/vscode.nix
  ];

  # Keep this at the version used for the first activation of this configuration.
  home.stateVersion = "26.05";

  programs.home-manager.enable = true;

  # The upstream CLI assumes a conventional home.nix. Supply this checkout's
  # flake context without requiring shell aliases or a particular working dir.
  home.packages = lib.optional (agentPaths.checkout != "") (lib.hiPrio (
    pkgs.writeShellScriptBin "home-manager" ''
      set -eu
      for arg in "$@"; do
        case "$arg" in
          --flake|--flake=*|-f|--file|--file=*)
            exec ${config.programs.home-manager.package}/bin/home-manager "$@"
            ;;
        esac
      done
      export DOTFILES_USER=${lib.escapeShellArg config.home.username}
      export DOTFILES_HOME=${lib.escapeShellArg config.home.homeDirectory}
      export DOTFILES_REPO=${lib.escapeShellArg agentPaths.checkout}
      export DOTFILES_LOCAL_CONFIG="''${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles/local.nix"
      profile_file="''${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles/profile"
      profile=home
      if [ -f "$profile_file" ]; then profile=$(cat "$profile_file"); fi
      case "$profile" in
        home|work) ;;
        *) printf 'Unknown dotfiles profile: %s\n' "$profile" >&2; exit 2 ;;
      esac
      exec ${config.programs.home-manager.package}/bin/home-manager \
        --impure --flake "$DOTFILES_REPO#$profile" "$@"
    ''
  ));

  programs.vim.enable = true;
}
