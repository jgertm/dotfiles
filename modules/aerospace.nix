{ lib, pkgs, ... }:

lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
  programs.aerospace = {
    enable = true;
    launchd.enable = true;

    settings = {
      config-version = 2;
      persistent-workspaces = [ "1" "2" "3" "4" "5" ];
      accordion-padding = 30;
      automatically-unhide-macos-hidden-apps = false;
      default-root-container-layout = "tiles";
      default-root-container-orientation = "auto";
      enable-normalization-flatten-containers = true;
      enable-normalization-opposite-orientation-for-nested-containers = true;
      key-mapping.preset = "qwerty";

      gaps = {
        inner = { horizontal = 10; vertical = 10; };
        outer = { bottom = 0; left = 0; right = 0; top = 0; };
      };

      mode.main.binding = {
        alt-h = "focus left";
        alt-j = "focus down";
        alt-k = "focus up";
        alt-l = "focus right";
        alt-shift-h = "move left";
        alt-shift-j = "move down";
        alt-shift-k = "move up";
        alt-shift-l = "move right";

        alt-1 = "workspace 1";
        alt-2 = "workspace 2";
        alt-3 = "workspace 3";
        alt-4 = "workspace 4";
        alt-5 = "workspace 5";
        alt-shift-1 = "move-node-to-workspace 1";
        alt-shift-2 = "move-node-to-workspace 2";
        alt-shift-3 = "move-node-to-workspace 3";
        alt-shift-4 = "move-node-to-workspace 4";
        alt-shift-5 = "move-node-to-workspace 5";

        alt-q = "focus-monitor 1";
        alt-w = "focus-monitor 2";
        alt-e = "focus-monitor 3";
        alt-shift-q = [ "move-node-to-monitor 1" "focus-monitor 1" ];
        alt-shift-w = [ "move-node-to-monitor 2" "focus-monitor 2" ];
        alt-shift-e = [ "move-node-to-monitor 3" "focus-monitor 3" ];

        alt-d = "layout floating tiling";
        alt-f = "fullscreen";
        alt-r = "layout tiles horizontal vertical";
        alt-semicolon = "mode service";
      };

      mode.service.binding = {
        backspace = [ "close-all-windows-but-current" "mode main" ];
        esc = [ "reload-config" "mode main" ];
        f = [ "layout floating tiling" "mode main" ];
        r = [ "flatten-workspace-tree" "mode main" ];
      };
    };
  };
}
