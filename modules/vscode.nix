{ pkgs, ... }:

{
  nixpkgs.config.allowUnfreePackages = [ "vscode" ];

  programs.vscode = {
    enable = true;
    mutableExtensionsDir = false;

    profiles.default = {
      extensions = [ pkgs.vscode-extensions.vscodevim.vim ];
      enableUpdateCheck = false;
      enableExtensionUpdateCheck = false;

      userSettings = {
        "editor.fontFamily" = "Iosevka, monospace";
        "terminal.integrated.fontFamily" = "Iosevka, monospace";
      };
    };
  };
}
