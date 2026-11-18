# Dotfiles

Nix and Home Manager configuration for Apple Silicon macOS and 64-bit ARM and x86 Linux.

## Install

For a quick install, run this as your regular user with Bash, `curl`, and `tar`
available. It downloads the current `main` branch to `~/Dropbox/dotfiles` and
refuses to overwrite an existing destination.

```sh
curl -fsSL https://raw.githubusercontent.com/jgertm/dotfiles/main/bootstrap |
  bash -s -- --profile home
```

Append `--dir "$HOME/src/dotfiles"` to choose another destination. `--dir` is
only for piped installs; `--check` requires an existing checkout. Once Home
Manager installs Git, bootstrap turns the downloaded snapshot into a Git
repository with `main` tracking `origin/main` over HTTPS. Existing files are
preserved; any differences from the fetched commit appear as local changes.
Existing Git checkouts keep their branches and remotes unchanged.

If you cloned the repository or already extracted an archive, run bootstrap from that directory.

```sh
./bootstrap --profile home
```

Use `--profile work` on a work machine. Bootstrap installs Nix if needed, enables flakes system-wide, and activates Home Manager. The Nix setup may ask for administrator access. Open a new terminal after activation.

Bootstrap remembers the selected profile on each machine. `./bootstrap` reuses it and defaults to `home` on a fresh system. `./bootstrap --check --profile work` evaluates the work profile without activating or saving it.

In Codex, use `/hooks` to review and trust the Herdr session hook.

### Playwright MCP browsers

Home Manager registers four isolated browser servers in Codex and Claude:

- `playwright-chrome` and `playwright-firefox` launch headless for background automation.
- `playwright-chrome-headed` and `playwright-firefox-headed` open visible browser windows.

Choose the corresponding MCP server for the browser and launch mode you need.
The Chrome servers use Playwright's Chromium. Headed launches require a graphical
session; on Linux, the MCP client must inherit the appropriate display environment.
Run `./bootstrap` to register the servers, then restart your agent session to load them.

### Caps Lock → Escape

- **macOS** · Open **System Settings → Keyboard → Keyboard Shortcuts → Modifier Keys**. Choose a keyboard, set **Caps Lock Key** to **Escape**, and repeat for each keyboard you use.
- **Linux** · Bootstrap installs and enables keyd with sudo on systemd-based distributions. On NixOS, add this flake’s `nixosModules.keyd` to your system configuration’s `modules` list and rebuild. On other init systems, install keyd, set `capslock = esc` under `[main]` for all keyboards in `/etc/keyd/default.conf`, and enable the service.

## Maintain

- Edit `home.nix` and `modules/` for shared settings. Edit `profiles/home.nix` or `profiles/work.nix` for public settings specific to that context.
- For one machine, add an optional Home Manager module at `${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles/local.nix`. Keep credentials outside Nix and outside the checkout.
- After pulling or editing, run `./bootstrap --check` and then `./bootstrap`. In a Git checkout, stage new files before evaluating so the flake can see them.
- To update a branch input, run `nix flake update <input>`. For a versioned release asset, update its URL in `flake.nix` and run `nix flake lock`. Review `flake.lock` before applying.
- Git defaults to Tim Jäger's GitHub noreply identity. Override it in `~/.gitconfig.local` or in each repository when needed.

## T3 Code

Home Manager installs official T3 Code release archives pinned in `flake.lock`.
macOS uses the signed desktop bundle; Linux installs the headless CLI.
On macOS it merges Iosevka preferences into writable T3 settings and
publishes the Tokyo Night theme from `config/t3code/`. The desktop updater is
disabled. To upgrade, update the four T3 input URLs in `flake.nix` and the
package version in `packages/t3code.nix`, run `nix flake lock`, then run `./bootstrap`.

Configure remote environments and route preferences in T3 itself. Pairing
credentials and the encrypted route catalog belong to T3's private writable
state, not Git or the Nix store. Provider logins likewise stay on the machine
running agents. Service and network configuration are outside this repository.
