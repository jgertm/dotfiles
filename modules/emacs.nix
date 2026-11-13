{
  config,
  doom-emacs,
  nixpkgs-newer,
  pkgs,
  ...
}:

{
  imports = [ doom-emacs.homeModule ];

  programs.doom-emacs = {
    enable = true;
    emacs = nixpkgs-newer.legacyPackages.${pkgs.stdenv.hostPlatform.system}.emacs31;
    doomDir = ../config/doom;
    doomLocalDir = "${config.xdg.dataHome}/dotfiles/doom";
    experimentalFetchTree = true;
  };
}
