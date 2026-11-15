{
  config,
  doom-emacs,
  lib,
  nixpkgs-newer,
  pkgs,
  ...
}:

let
  terminalEditor = pkgs.writeShellScript "emacs-terminal" ''
    exec ${config.programs.doom-emacs.finalEmacsPackage}/bin/emacsclient --tty "$@"
  '';
in
{
  imports = [ doom-emacs.homeModule ];

  programs.doom-emacs = {
    enable = true;
    emacs = nixpkgs-newer.legacyPackages.${pkgs.stdenv.hostPlatform.system}.emacs31;
    doomDir = ../config/doom;
    doomLocalDir = "${config.xdg.dataHome}/dotfiles/doom";
    experimentalFetchTree = true;
  };

  services.emacs.enable = true;

  launchd.agents.emacs.config = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
    EnvironmentVariables.PATH = "${config.home.profileDirectory}/bin:/usr/bin:/bin:/usr/sbin:/sbin";
    # launchd does not inherit Ghostty's environment; Emacs needs this when
    # initializing terminal clients to preserve the theme's RGB colors.
    EnvironmentVariables.COLORTERM = "truecolor";
    StandardOutPath = "${config.home.homeDirectory}/Library/Logs/emacs.log";
    StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/emacs.log";
  };

  programs.zsh.shellAliases = {
    emt = "${terminalEditor}";
    rpn = "${terminalEditor} --eval '(full-calc)'";
    # Use the client's cwd, not the daemon's current buffer directory.
    magit = "${terminalEditor} --eval '(magit-status (process-get (frame-parameter nil (quote client)) (quote server-client-directory)))'";
  };
  home.sessionVariables = {
    EDITOR = "${terminalEditor}";
    VISUAL = "${terminalEditor}";
  };
}
