# Nix Configuration

Personal nix setup for macOS using nix-darwin, nix-homebrew, and flakes.

## Repository Structure

```
~/.config/nix/
├── nix-darwin-config/    # System-wide config (nix-darwin + homebrew casks)
│   ├── flake.nix         # Machine packages, homebrew casks, system settings
│   ├── .zshrc            # Shell config (symlinked to ~/.zshrc)
│   ├── .gitconfig        # Git config (symlinked to ~/.gitconfig)
│   └── fzf-funcs.zsh     # fzf helper functions
└── nix-dev-envs/         # Project dev environments
    └── flake.nix         # Dev shells: base, webapp, golang, keycloak, frontend, fullstack
```

## Symlinks

Dotfiles are stored in `nix-darwin-config/` and automatically symlinked to `$HOME` by the nix-darwin activation script on every rebuild:

```
~/.zshrc      -> ~/.config/nix/nix-darwin-config/.zshrc
~/.gitconfig  -> ~/.config/nix/nix-darwin-config/.gitconfig
```

## Dev Shells

Enter a dev environment:

```sh
dev <environment>
```

Available environments:

| Shell        | What it adds on top of base                              |
|--------------|----------------------------------------------------------|
| `base`       | CLI tools, AWS, Kubernetes, Terraform, Node.js           |
| `webapp`     | Java 8, Groovy 2.5, Grails 3.3 via SDKMAN               |
| `golang`     | Go, linters, Hugo, OpenAPI generator                     |
| `keycloak`   | Go + Java 21 + Gradle + Bun/Yarn                        |
| `frontend`   | Bun, Yarn, pnpm, Android SDK paths                      |
| `fullstack`  | Golang + Frontend + GCP + Java 21                        |

### How it works

1. `dev <env>` is a zsh function defined in `.zshrc`
2. It runs `nix develop ~/.config/nix/nix-dev-envs#<env> -c zsh`
3. Nix builds the shell (bash), runs `shellHook` to set up env vars and install tools
4. Then launches zsh as the interactive shell via `-c zsh`
5. `.zshrc` detects `NIX_DEV_ENV` and fixes `$SHELL` (nix overrides it to its bash)
6. For `webapp`/`fullstack`, `.zshrc` also sources SDKMAN so `sdk` commands work in zsh

### Rebuilding

```sh
# Rebuild nix-darwin system config
nix-darwin-rebuild

# Update dev environment flake inputs
cd ~/.config/nix/nix-dev-envs && nix flake update
```

## Fresh Machine Setup

### Automated (handled by nix-darwin rebuild)

- System CLI tools (ripgrep, fzf, bat, git, curl, etc.)
- GUI apps via nix: Spotify, Obsidian, IntelliJ IDEA, 1Password CLI, Bitwarden, Discord, Bruno, DBeaver, Ghostty, Zed
- GUI apps via brew casks: 1Password, Arc, Bartender, Chrome, DisplayLink, Karabiner-Elements, NordVPN, Notion, OrbStack, VLC, Zoom
- Mac App Store apps: BetterSnapTool, Be Focused, Disk Space Analyzer, GarageBand, iMovie, Keynote, Numbers, Pages, Slack, WireGuard
- Dotfile symlinks (.zshrc, .gitconfig)
- Shell configuration (zsh, Starship prompt, Oh My Zsh)
- Touch ID for sudo

### Manual steps

1. Install [Nix](https://nixos.org/download.html) with flakes enabled
2. Install [nix-darwin](https://github.com/LnL7/nix-darwin)
3. Clone this repo: `git clone <repo-url> ~/.config/nix`
4. Update the `hostname` variable in `nix-darwin-config/flake.nix` to match the new machine name
5. Run the initial rebuild:
   ```sh
   sudo darwin-rebuild switch --flake ~/.config/nix/nix-darwin-config
   ```
6. Update flake inputs:
   ```sh
   cd ~/.config/nix/nix-darwin-config && nix flake update
   cd ~/.config/nix/nix-dev-envs && nix flake update
   ```
7. Set up SSH keys via 1Password SSH agent (`id_rsa` for personal, `id_matchi` for work)
8. Install Xcode from the App Store (required for iOS/macOS development tools)
9. Install Adobe Creative Cloud and apps (manual download)
10. Sign in to Mac App Store (required for `masApps` to install)

### Not managed by nix

These require manual installation and are not portable:

- Xcode (App Store only, includes CLI tools)
- Adobe Creative Cloud + apps
- DisplayLink driver (brew cask installs it, but driver activation is manual)
- SSH keys (restore from 1Password or generate new ones)

## Prerequisites

1. [Nix](https://nixos.org/download.html) with flakes enabled (`experimental-features = nix-command flakes` in `~/.config/nix/nix.conf`)
2. [nix-darwin](https://github.com/LnL7/nix-darwin)
3. [Homebrew](https://brew.sh) (managed via [nix-homebrew](https://github.com/zhaofengli/nix-homebrew))
