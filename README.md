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

Dotfiles are stored in `nix-darwin-config/` and symlinked to `$HOME`:

```
~/.zshrc      -> ~/.config/nix/nix-darwin-config/.zshrc
~/.gitconfig  -> ~/.config/nix/nix-darwin-config/.gitconfig
```

Create them with:

```sh
ln -sf ~/.config/nix/nix-darwin-config/.zshrc ~/.zshrc
ln -sf ~/.config/nix/nix-darwin-config/.gitconfig ~/.gitconfig
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

## Prerequisites

1. [Nix](https://nixos.org/download.html) with flakes enabled (`experimental-features = nix-command flakes` in `~/.config/nix/nix.conf`)
2. [nix-darwin](https://github.com/LnL7/nix-darwin)
3. [Homebrew](https://brew.sh) (managed via [nix-homebrew](https://github.com/zhaofengli/nix-homebrew))
