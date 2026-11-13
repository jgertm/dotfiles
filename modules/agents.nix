{ codexArchive, config, lib, nixpkgs-newer, pkgs, ... }:

let
  newer = import nixpkgs-newer {
    inherit (pkgs.stdenv.hostPlatform) system;
    config.allowUnfreePackages = [ "claude-code" ];
  };

  codex = pkgs.runCommand "codex-upstream" { } ''
    mkdir -p "$out"
    tar -xzf ${codexArchive} -C "$out"
    test -x "$out/bin/codex"
  '';

  playwright = newer.playwright-mcp.override {
    playwright-driver = newer.playwright-driver // {
      browsers = newer.playwright-driver.selectBrowsers { withWebkit = false; };
    };
  };

  browserNames = {
    chrome = "chromium";
    firefox = "firefox";
  };
  playwrightPath = "${config.xdg.configHome}/dotfiles/mcp";
in
{
  home.file.".claude/settings.json".text = builtins.toJSON {
    editorMode = "vim";
    tui = "fullscreen";
    verbose = true;
    voiceEnabled = true;
    agentPushNotifEnabled = true;
    skipWorkflowUsageWarning = true;
    skipAutoPermissionPrompt = true;
    skipDangerousModePermissionPrompt = true;
    env = {
      CLAUDE_CODE_ENABLE_AUTO_MODE = "1";
      CLAUDE_CODE_SCROLL_SPEED = "3";
      DISABLE_AUTOUPDATER = "1";
    };
  };

  home.packages = [
    (pkgs.writeShellScriptBin "claude" ''
      exec ${newer.claude-code}/bin/claude --allow-dangerously-skip-permissions "$@"
    '')
    (pkgs.writeShellScriptBin "codex" ''
      exec ${codex}/bin/codex -c check_for_update_on_startup=false -c tui.vim_mode_default=true "$@"
    '')
  ];

  xdg.configFile = lib.mapAttrs' (name: browser:
    lib.nameValuePair "dotfiles/mcp/playwright-${name}" {
      executable = true;
      text = ''
        #!${pkgs.runtimeShell}
        exec ${lib.getExe playwright} --browser ${browser} --headless --isolated "$@"
      '';
    }
  ) browserNames;

  home.activation.registerPlaywright = lib.hm.dag.entryAfter [ "linkGeneration" ] (
    ''
      claudeConfig="''${CLAUDE_CONFIG_DIR:-$HOME}/.claude.json"
    ''
    + lib.concatMapStringsSep "\n" (name: ''
      run ${codex}/bin/codex mcp add playwright-${name} -- ${lib.escapeShellArg "${playwrightPath}/playwright-${name}"}
      if [[ ! -f "$claudeConfig" ]] ||
         ! ${lib.getExe pkgs.jq} -e '.mcpServers | has("playwright-${name}")' "$claudeConfig" >/dev/null 2>&1; then
        run ${newer.claude-code}/bin/claude mcp add --scope user --transport stdio playwright-${name} \
          -- ${lib.escapeShellArg "${playwrightPath}/playwright-${name}"}
      fi
    '') (lib.attrNames browserNames)
  );
}
