{ agentPaths, codexArchive, config, herdr, lib, nixpkgs-newer, pkgs, ... }:

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

  claudeHome = if (agentPaths.claude or "") == "" then ".claude" else agentPaths.claude;
  codexHome = if (agentPaths.codex or "") == "" then ".codex" else agentPaths.codex;

  # Run the pinned installer in a clean build directory to get the upstream scripts.
  herdrHooks = pkgs.runCommand "herdr-agent-hooks" { } ''
    export HOME="$TMPDIR/home"
    export CLAUDE_CONFIG_DIR="$HOME/.claude"
    export CODEX_HOME="$HOME/.codex"
    mkdir -p "$CLAUDE_CONFIG_DIR" "$CODEX_HOME" "$out"
    ${lib.getExe herdr} integration install claude
    ${lib.getExe herdr} integration install codex
    install -m755 "$CLAUDE_CONFIG_DIR/hooks/herdr-agent-state.sh" "$out/claude.sh"
    install -m755 "$CODEX_HOME/herdr-agent-state.sh" "$out/codex.sh"
  '';
  herdrSessionHook = agent: {
    hooks = [
      {
        type = "command";
        command = "PATH=${lib.makeBinPath [ pkgs.python3 ]}:$PATH ${pkgs.runtimeShell} ${herdrHooks}/${agent}.sh session";
        timeout = 10;
      }
    ];
  };

  memoryPath = "dotfiles/agent-memory";
  memoryIndex = "${config.xdg.configHome}/${memoryPath}/MEMORY.md";
  memoryFiles = lib.filter
    (name: name != "MEMORY.md" && lib.hasSuffix ".md" name)
    (builtins.attrNames (builtins.readDir ../config/agent-memory));
  agentInstructions = pkgs.writeText "dotfiles-agent-instructions.md" (
    lib.optionalString (agentPaths.checkout != "") ''
      My Nix and Home Manager dotfiles checkout is at `${agentPaths.checkout}`. Edit that checkout when I ask to change my dotfiles.

    ''
    + ''
      Shared agent memories are included below. Treat them as already loaded for
      this session and apply the relevant entries. Do not reread their source
      files on every turn or task. Read a source again only when it has changed,
      the user asks you to refresh it, or its contents are missing from context
      after compaction. Preserve relevant memories in compaction summaries.

      The editable source files are indexed at `${memoryIndex}`. In the dotfiles
      checkout, edit `config/agent-memory/` and run bootstrap to regenerate these
      instructions; do not edit the generated instruction files directly.

    ''
    + lib.concatMapStringsSep "\n" (name: builtins.readFile (../config/agent-memory + "/${name}")) memoryFiles
  );
in
{
  home.file."${claudeHome}/CLAUDE.md".source = agentInstructions;
  home.file."${codexHome}/AGENTS.md".source = agentInstructions;

  home.file."${claudeHome}/settings.json".text = builtins.toJSON {
    editorMode = "vim";
    tui = "fullscreen";
    verbose = true;
    voiceEnabled = true;
    agentPushNotifEnabled = true;
    skipWorkflowUsageWarning = true;
    skipAutoPermissionPrompt = true;
    skipDangerousModePermissionPrompt = true;
    hooks.SessionStart = [
      ((herdrSessionHook "claude") // { matcher = "^(startup|resume|clear|compact|fork)$"; })
    ];
    env = {
      CLAUDE_CODE_ENABLE_AUTO_MODE = "1";
      CLAUDE_CODE_SCROLL_SPEED = "3";
      DISABLE_AUTOUPDATER = "1";
    };
  };

  home.file."${codexHome}/hooks.json".text = builtins.toJSON {
    hooks.SessionStart = [ (herdrSessionHook "codex") ];
  };

  home.packages = [
    (pkgs.writeShellScriptBin "claude" ''
      exec ${newer.claude-code}/bin/claude --allow-dangerously-skip-permissions "$@"
    '')
    (pkgs.writeShellScriptBin "codex" ''
      # Codex 0.169 treats TERM_PROGRAM=herdr as an unknown terminal before
      # checking GHOSTTY_RESOURCES_DIR, disabling inline image previews.
      # Let its Ghostty fallback run in this known Kitty-capable combination.
      if [ "''${TERM_PROGRAM:-}" = herdr ] && [ -n "''${GHOSTTY_RESOURCES_DIR:-}" ]; then
        unset TERM_PROGRAM TERM_PROGRAM_VERSION
      fi
      exec ${codex}/bin/codex "$@"
    '')
  ];

  # Codex writes its own settings here. Merge our preferences into the writable
  # file instead of symlinking it or using -c (which forces embedded-server mode).
  home.activation.configureCodex = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run ${pkgs.python3.withPackages (ps: [ ps.tomlkit ])}/bin/python3 - ${lib.escapeShellArg "${config.home.homeDirectory}/${codexHome}/config.toml"} <<'PY'
    import os
    from pathlib import Path
    import sys
    import tempfile
    import tomlkit

    path = Path(sys.argv[1])
    original = path.read_text() if path.exists() else ""
    settings = tomlkit.parse(original)
    settings["check_for_update_on_startup"] = False
    # Exact persistent equivalent of --approve-for-me, whose CLI expansion
    # also injects overrides and therefore forces embedded-server mode.
    settings["approvals_reviewer"] = "auto_review"
    settings["approval_policy"] = "on-request"
    settings["sandbox_mode"] = "workspace-write"
    if "tui" not in settings:
        settings["tui"] = tomlkit.table()
    settings["tui"].update({
        "vim_mode_default": True,
        "mouse_scroll_speed": 3.0,
        "status_line": ["model-with-reasoning", "context-used", "five-hour-limit", "weekly-limit", "current-dir", "thread-name"],
    })
    updated = tomlkit.dumps(settings)
    if updated != original:
        path.parent.mkdir(parents=True, exist_ok=True)
        with tempfile.NamedTemporaryFile(mode="w", dir=path.parent, delete=False) as output:
            output.write(updated)
            temporary = output.name
        os.replace(temporary, path)
    PY
  '';

  xdg.configFile = lib.mapAttrs' (name: browser:
    lib.nameValuePair "dotfiles/mcp/playwright-${name}" {
      executable = true;
      text = ''
        #!${pkgs.runtimeShell}
        exec ${lib.getExe playwright} --browser ${browser} --headless --isolated "$@"
      '';
    }
  ) browserNames // {
    "${memoryPath}".source = ../config/agent-memory;
  };

  home.activation.registerPlaywright = lib.hm.dag.entryAfter [ "linkGeneration" "configureCodex" ] (
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
