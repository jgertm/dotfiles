{ config, herdr, herdr-thumbs, lib, pkgs, ... }:

let
  ghostty = if pkgs.stdenv.hostPlatform.isDarwin then pkgs.ghostty-bin else pkgs.ghostty;
  thumbsPlugin = pkgs.callPackage ../packages/herdr-thumbs.nix { src = herdr-thumbs; };
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

  home.activation.linkHerdrThumbs = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    run ${lib.getExe herdr} plugin link ${thumbsPlugin}
  '';

  xdg.configFile."herdr/config.toml".source = (pkgs.formats.toml { }).generate "herdr-config.toml" {
    terminal.new_cwd = "follow";
    ui.copy_on_select = true;
    session.resume_agents_on_restore = true;
    experimental.pane_history = true;

    keys = {
      prefix = "ctrl+a";
      help = [ "prefix+?" "f1" ];
      focus_pane_left = [ "prefix+h" "prefix+ctrl+h" ];
      focus_pane_down = [ "prefix+j" "prefix+ctrl+j" ];
      focus_pane_up = [ "prefix+k" "prefix+ctrl+k" ];
      focus_pane_right = [ "prefix+l" "prefix+ctrl+l" ];
      split_vertical = [ "prefix+v" "prefix+|" "prefix+percent" ];
      split_horizontal = [ "prefix+minus" "prefix+double_quote" ];
      last_pane = "prefix+semicolon";

      next_tab = [ "prefix+n" "prefix+ctrl+n" ];
      previous_tab = [ "prefix+p" "prefix+ctrl+p" ];
      rename_tab = [ "prefix+shift+t" "prefix+comma" ];
      close_tab = [ "prefix+shift+x" "prefix+ampersand" ];
      detach = [ "prefix+q" "prefix+d" ];
      copy_mode = [ "prefix+[" "prefix+esc" ];

      navigate_workspace_up = [ "up" "ctrl+k" ];
      navigate_workspace_down = [ "down" "ctrl+j" ];
      switch_workspace = "prefix+shift+1..9";
      next_agent = "prefix+a";
      previous_agent = "prefix+shift+a";

      command = [
        {
          key = "prefix+shift+f";
          type = "plugin_action";
          command = "sd2k.thumbs.pick";
          description = "Copy a visible URL, path, or hash";
        }
        {
          key = "prefix+!";
          type = "shell";
          command = ''"$HERDR_BIN_PATH" pane move "$HERDR_ACTIVE_PANE_ID" --new-tab --focus'';
          description = "Move pane to a new tab";
        }
      ];
    };
  };

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
