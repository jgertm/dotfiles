{ config, pkgs, ... }:

{
  home.sessionPath = [
    "${config.home.profileDirectory}/bin"
    "$HOME/.local/bin"
  ];
  home.packages = [ pkgs.bazelisk ];

  programs = {
    zsh = {
      enable = true;
      defaultKeymap = "viins";
      autosuggestion.enable = true;
      shellAliases = import ./aliases.nix;

      # Audit completion paths at most once a day. The fast path only reads
      # a dump created by this user; the slow path ignores insecure fpaths.
      completionInit = ''
        () {
          autoload -Uz compinit
          zmodload zsh/stat || { compinit -i -D; return; }
          local dump="''${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump-$ZSH_VERSION"
          local cache_dir="''${dump:h}" scratch
          local -A cache_info dump_info
          local -a fresh=("$dump"(.Nmh-24))

          if [[ ! -d $cache_dir ]]; then
            (umask 077; mkdir -p -- "$cache_dir") || { compinit -i -D; return; }
          fi
          if [[ ! -O $cache_dir || -L $cache_dir ]] || ! zstat -H cache_info -- "$cache_dir" || (( cache_info[mode] & 8#022 )); then
            compinit -i -D
          elif (( ''${#fresh} )) && [[ -O $dump && ! -L $dump && ! -e $dump.zwc ]] &&
               zstat -H dump_info -- "$dump" && (( !(dump_info[mode] & 8#022) )); then
            compinit -C -d "$dump"
          elif scratch=$(mktemp -d "$cache_dir/build.XXXXXXXX"); then
            compinit -i -d "$scratch/dump"
            if [[ -f $scratch/dump && ! -d $dump ]]; then
              mv -f -- "$scratch/dump" "$dump"
            fi
            rm -f -- "$scratch/dump"
            rmdir -- "$scratch"
          else
            compinit -i -D
          fi
        }
      '';
    };

    direnv = {
      enable = true;
      enableZshIntegration = true;
      nix-direnv.enable = true;
    };

    starship = {
      enable = true;
      enableZshIntegration = true;
      settings = {
        add_newline = true;
        format = ''
          $fill $git_branch$directory$username@$hostname$time
          $status$character
        '';
        fill = {
          style = "grey";
          symbol = "·";
        };
        status = {
          disabled = false;
          format = "([$status ]($style))";
        };
        hostname = {
          format = "[$hostname]($style)";
          ssh_only = false;
          style = "bold underline white";
          trim_at = "";
        };
        username = {
          format = "[$user]($style)";
          show_always = true;
          style_root = "bold red";
          style_user = "bold white";
        };
        directory.format = "[$path]($style) ";
        git_branch.format = " [$symbol$branch]($style):";
        character = {
          success_symbol = "[>](bold green)";
          error_symbol = "[<](bold red)";
          vimcmd_symbol = "[_](bold dimmed white)";
        };
        time = {
          disabled = false;
          format = "[\\[$time\\]]($style)";
        };
      };
    };

    atuin = {
      enable = true;
      enableZshIntegration = true;
      settings = {
        filter_mode = "global";
        auto_sync = false;
        keymap_mode = "vim-insert";
      };
    };
  };
}
