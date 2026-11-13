{ config, nixpkgs-newer, pkgs, ... }:

let
  newer = nixpkgs-newer.legacyPackages.${pkgs.stdenv.hostPlatform.system};
  jdk = newer.temurin-bin-27;
in
{
  nixpkgs.config.allowUnfreePackages = [ "1password-cli" ];

  programs.java = {
    enable = true;
    package = jdk;
  };
  programs.k9s.enable = true;

  home.file =
    let
      k9sConfig =
        if pkgs.stdenv.hostPlatform.isDarwin && !config.xdg.enable then
          "Library/Application Support/k9s"
        else
          "${config.xdg.configHome}/k9s";
    in
    {
      "${k9sConfig}/views.yaml".source = ../config/k9s/views.yaml;
    };

  home.packages = with pkgs; [
    _1password-cli
    awscli2
    babashka
    bat
    (clojure.override { inherit jdk; })
    dust
    eza
    fd
    fzf
    gh
    glances
    go-containerregistry # crane
    htop
    jq
    kubectl
    (leiningen.override { inherit jdk; })
    ncdu
    nodejs_24
    ripgrep
    rsync
    sd
    tree
    uv
  ];
}
