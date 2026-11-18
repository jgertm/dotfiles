{
  description = "Portable user environment with Home Manager";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-darwin.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";
    nixpkgs-newer.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    herdr-thumbs = {
      url = "github:sd2k/herdr-thumbs";
      flake = false;
    };
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
    t3code-aarch64-darwin = {
      url = "file+https://github.com/pingdotgg/t3code/releases/download/v0.1.10/t3-0.1.10-darwin-arm64.tar.gz";
      flake = false;
    };
    t3code-aarch64-linux = {
      url = "file+https://github.com/pingdotgg/t3code/releases/download/v0.1.10/t3-0.1.10-linux-arm64.tar.gz";
      flake = false;
    };
    t3code-x86_64-linux = {
      url = "file+https://github.com/pingdotgg/t3code/releases/download/v0.1.10/t3-0.1.10-linux-x64.tar.gz";
      flake = false;
    };
    t3code-desktop-aarch64-darwin = {
      url = "file+https://github.com/pingdotgg/t3code/releases/download/v0.1.10/T3-Code-0.1.10-arm64.zip";
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
      keydKeyboard = {
        ids = [ "*" ];
        settings.main.capslock = "esc";
      };
      keydSetup = pkgs: pkgs.linkFarm "dotfiles-keyd" {
        "bin/keyd" = lib.getExe pkgs.keyd;
        "default.conf" = pkgs.writeText "keyd-default.conf" ''
          [ids]
          ${lib.concatStringsSep "\n" keydKeyboard.ids}

          ${lib.generators.toINI { } keydKeyboard.settings}
        '';
        "uinput.conf" = pkgs.writeText "keyd-uinput.conf" "uinput\n";
        "keyd.service" = pkgs.writeText "keyd.service" ''
          [Unit]
          Description=keyd keyboard remapping daemon
          After=systemd-modules-load.service

          [Service]
          Type=exec
          ExecStart=/nix/var/nix/gcroots/dotfiles-keyd/bin/keyd
          Restart=on-failure

          [Install]
          WantedBy=multi-user.target
        '';
      };
      mkHome =
        system: username: homeDirectory: profile: extraModules: agentPaths:
        let pkgs = pkgsFor system;
        in
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs = {
            inherit agentPaths doom-emacs nixpkgs-newer;
            codexArchive = inputs."codex-${system}".outPath;
            herdr = pkgs.callPackage ./packages/herdr.nix {
              herdrBinary = inputs."herdr-${system}".outPath;
            };
            t3code = pkgs.callPackage ./packages/t3code.nix ({
              t3Archive = inputs."t3code-${system}".outPath;
            } // lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
              t3DesktopArchive = inputs."t3code-desktop-${system}".outPath;
            });
            inherit (inputs) herdr-thumbs tridactyl ublock-origin;
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
          agentPaths = {
            checkout = builtins.getEnv "DOTFILES_REPO";
            claude = builtins.getEnv "CLAUDE_CONFIG_DIR";
            codex = builtins.getEnv "CODEX_HOME";
          };
        in
        if username == "" || homeDirectory == "" then
          throw "Use ./bootstrap so Home Manager knows which user and home directory to configure."
        else if !(lib.elem system systems) then
          throw "Unsupported platform: ${system}"
        else
          mkHome system username homeDirectory profile extraModules agentPaths;
    in
    {
      homeConfigurations = lib.mapAttrs (_: localHome) profiles // { default = localHome profiles.home; };

      packages = lib.genAttrs systems (system:
        let pkgs = pkgsFor system;
        in {
          home-manager = home-manager.packages.${system}.home-manager;
        } // lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
          keyd-setup = keydSetup pkgs;
        }
      );

      nixosModules.keyd = {
        services.keyd = {
          enable = true;
          keyboards.default = keydKeyboard;
        };
      };

      checks = lib.genAttrs systems (system:
        lib.mapAttrs (_: profile:
          (mkHome system "dotfiles-test" (
            if lib.hasSuffix "-darwin" system then "/Users/dotfiles-test" else "/home/dotfiles-test"
          ) profile [ ] { checkout = "/example/dotfiles"; }).activationPackage
        ) profiles
      );
    };
}
