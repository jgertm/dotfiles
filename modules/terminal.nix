{ config, herdrBinary, lib, pkgs, ... }:

let
  herdr = pkgs.callPackage ../packages/herdr.nix { inherit herdrBinary; };
  ghostty = if pkgs.stdenv.hostPlatform.isDarwin then pkgs.ghostty-bin else pkgs.ghostty;
  startHerdr = pkgs.writeShellScript "ghostty-herdr" ''
    # Finder and other desktop launchers may start with only the system PATH.
    export PATH=${lib.escapeShellArg "${config.home.profileDirectory}/bin"}:"$HOME/.local/bin:$PATH"
    export SHELL=${lib.getExe config.programs.zsh.package}
    exec ${lib.getExe herdr}
  '';
in
{
  home.packages = [
    herdr
    pkgs.iosevka-bin
  ];

  fonts.fontconfig.enable = pkgs.stdenv.hostPlatform.isLinux;

  programs.ghostty = {
    enable = true;
    package = ghostty;
    settings = {
      command = "direct:${startHerdr}";
      font-family = "Iosevka";
    };
    # Herdr owns the terminal surface. Its child shells use their own integration.
    enableZshIntegration = false;
  };
}
