{ lib, pkgs, tridactyl, ublock-origin, ... }:

{
  programs.firefox = {
    enable = true;
    nativeMessagingHosts = [ pkgs.tridactyl-native ];

    policies.ExtensionSettings = lib.mapAttrs (_id: xpi: {
      installation_mode = "normal_installed";
      install_url = "file://${xpi}";
      private_browsing = true;
      updates_disabled = true;
    }) {
      "tridactyl.vim@cmcaine.co.uk" = pkgs.runCommand "tridactyl.xpi" { } "cp ${tridactyl} $out";
      "uBlock0@raymondhill.net" = pkgs.runCommand "ublock-origin.xpi" { } "cp ${ublock-origin} $out";
    };
  };

  xdg.configFile."tridactyl/tridactylrc".source = ../config/tridactylrc;
}
