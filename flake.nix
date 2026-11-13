{
  description = "Portable user environment with Home Manager";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-darwin.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";
    nixpkgs-newer.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    doom-emacs = {
      url = "github:marienz/nix-doom-emacs-unstraightened";
      inputs.nixpkgs.follows = "nixpkgs-newer";
      inputs.doomdir.follows = "";
    };
    tridactyl = {
      url = "file+https://addons.mozilla.org/firefox/downloads/file/5014416/tridactyl_vim-1.25.1.xpi";
      flake = false;
    };
    ublock-origin = {
      url = "file+https://addons.mozilla.org/firefox/downloads/file/5225273/ublock_origin-1.76.0.xpi";
      flake = false;
    };
    herdr-aarch64-darwin = {
      url = "file+https://github.com/herdrdev/herdr/releases/download/v0.9.5/herdr-macos-aarch64";
      flake = false;
    };
    herdr-aarch64-linux = {
      url = "file+https://github.com/herdrdev/herdr/releases/download/v0.9.5/herdr-linux-aarch64";
      flake = false;
    };
    herdr-x86_64-linux = {
      url = "file+https://github.com/herdrdev/herdr/releases/download/v0.9.5/herdr-linux-x86_64";
      flake = false;
    };
    codex-aarch64-darwin = {
      url = "file+https://github.com/openai/codex/releases/download/rust-v0.169.0/codex-package-aarch64-apple-darwin.tar.gz";
      flake = false;
    };
    codex-aarch64-linux = {
      url = "file+https://github.com/openai/codex/releases/download/rust-v0.169.0/codex-package-aarch64-unknown-linux-musl.tar.gz";
      flake = false;
    };
    codex-x86_64-linux = {
      url = "file+https://github.com/openai/codex/releases/download/rust-v0.169.0/codex-package-x86_64-unknown-linux-musl.tar.gz";
      flake = false;
    };
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      nixpkgs-darwin,
      nixpkgs-newer,
      doom-emacs,
      home-manager,
      ...
    }@inputs:
    let
      inherit (nixpkgs) lib;
      systems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];
      profiles = {
        home = ./profiles/home.nix;
        work = ./profiles/work.nix;
      };
      pkgsFor = system: (if lib.hasSuffix "-darwin" system then nixpkgs-darwin else nixpkgs).legacyPackages.${system};
      mkHome =
        system: username: homeDirectory: profile: extraModules:
        home-manager.lib.homeManagerConfiguration {
          pkgs = pkgsFor system;
          extraSpecialArgs = {
            inherit doom-emacs nixpkgs-newer;
            codexArchive = inputs."codex-${system}".outPath;
            herdrBinary = inputs."herdr-${system}".outPath;
            inherit (inputs) tridactyl ublock-origin;
          };
          modules = [
            ./home.nix
            profile
            { home = { inherit username homeDirectory; }; }
          ] ++ extraModules;
        };
      localHome = profile:
        let
          system = builtins.currentSystem;
          username = builtins.getEnv "DOTFILES_USER";
          homeDirectory = builtins.getEnv "DOTFILES_HOME";
          localConfig = builtins.getEnv "DOTFILES_LOCAL_CONFIG";
          extraModules = lib.optional (localConfig != "" && builtins.pathExists localConfig) (import localConfig);
        in
        if username == "" || homeDirectory == "" then
          throw "Use ./bootstrap so Home Manager knows which user and home directory to configure."
        else if !(lib.elem system systems) then
          throw "Unsupported platform: ${system}"
        else
          mkHome system username homeDirectory profile extraModules;
    in
    {
      homeConfigurations = lib.mapAttrs (_: localHome) profiles // { default = localHome profiles.home; };

      packages = lib.genAttrs systems (system: {
        home-manager = home-manager.packages.${system}.home-manager;
      });

      checks = lib.genAttrs systems (system:
        lib.mapAttrs (_: profile:
          (mkHome system "dotfiles-test" (
            if lib.hasSuffix "-darwin" system then "/Users/dotfiles-test" else "/home/dotfiles-test"
          ) profile [ ]).activationPackage
        ) profiles
      );
    };
}
