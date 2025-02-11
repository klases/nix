# Nix Development Environment Setup

This repository houses a **Nix-based development environment** setup for macOS, using **nix-darwin**, **nix-homebrew**, and **flakes** to provide a reproducible and portable development experience.

---

## 🚀 Usage

This setup provides isolated, reproducible development environments using Nix Flakes and nix develop.

Enter development environment

```sh
dev <environment>
```

Example:

```sh
dev base     # General CLI tools, AWS CLI, Kubernetes, Terraform
dev golang   # Go development environment
dev webapp   # Java 8, Groovy, Grails (SDKMAN! based)
```

## 📂 Architecture

This setup follows a modular structure:

- nix-darwin (nix-darwin-config/)
  - Provides system-wide configurations.
  - Installs essential CLI tools available in all environments.
  - Manages Homebrew for GUI apps (casks).
  - Will later support Apple Store app installations.

- nix-dev-envs (nix-dev-envs/)
  - Provides a set of development environments (dev <env>)
  - Each environment is defined in a separate shell configuration, and inherits from the base shell.

This setup is structured around a two Nix Flakes, one for defining the machine configuration with `nix-darwin` and one for defining the development environment e.g. Golang, Java, etc.

`nix-darwin` are using `homebrew` (mostly for casks) and `apple-sdk` (mostly for `xcode-tools`, to be added later). This is a curated list of packages that I want to have available in my environment.

The `nix-dev-env` flake is used to define different development environments, e.g. Golang, Java, etc. Is it built with an `base` overlay, which is inherited by all other dev environments. Each dev environment defines its own packages and are isolated from each other.

## **🛠️ Setup & Prerequisites**

> Please note that this setup is still in development, and may not work as expected.

> This setup is to my personal taste, and may not be suitable for everyone. Please use at your own risk. and fork if you want to customize it. Be aware of this before setting this up on your machine. It could change your system in unexpected ways!

This guide assumes you have a working macOS system, and are using `~/.config/nix` as your configuration directory.

1. Install [nix](https://nixos.org/download.html)

1. Add the following to your `~/.config/nix/nix.conf` file:

   ```nix
   experimental-features = nix-command flakes
   ```

   This will enable flakes support in nix.

1. Follow the [nix-darwin installation guide](https://github.com/LnL7/nix-darwin#installation) to install `nix-darwin` and `homebrew`.

1. Clone this repository, and move into your preferred place to store the configurations. I use `~/.config/nix`.

1. After cloning ensure to run `nix flake update` to pull the latest flakes. And run `darwin-rebuild switch` to apply the configurations to your system.

    **This assumes that you allready have `homebrew` installed.** If you haven't installed `homebrew` yet, update the `nix-darwin-config/flake.nix` to follow this [guide](https://github.com/zhaofengli/nix-homebrew)
1. Test by switchin to the `base` environment, and run `nix develop` to enter the environment.

    ```sh
    nix develop ~/.config/nix/nix-dev-envs#"$1" -c base
    ```

## Setup for simplified dev environment switching

This makes use of a `dev` function that is defined in the `~/.zshrc` file.

Usage:

```sh
dev <environment>
```

The follow needs to ba added to your `~/.zshrc` file:

```shell
# Simplifying the rebuilding of the nix-darwin configuration
alias nix-darwin-rebuild="darwin-rebuild switch --flake ~/.config/nix/nix-darwin-config"

# Remove any existing alias for `dev`
unalias dev 2>/dev/null

# Add a new alias for `dev`
# Usage: dev <environment>
# NIX_DEV_ENV is set to the environment name and are used
# to prompt which dev environment to use in p10k.
dev() {
  if [[ -z "$1" ]]; then
    echo "Usage: dev <environment>"
    echo "Available dev environments:"
    echo " base, webapp, personal, golang, frontend, github-workflows, gcp"
    return 1
  fi
  export NIX_DEV_ENV="$1"
  nix develop ~/.config/nix/nix-dev-envs#"$1" -c $SHELL
}

# Run cleanup when a shell exits
cleanup_nix_env() {
  # If inside a normal shell and `NIX_DEV_ENV` is set, clean it silently
  if [[ -z "$IN_NIX_SHELL" && -n "$NIX_DEV_ENV" ]]; then
    echo "Exiting Nix DevShell: Cleaning NIX_DEV_ENV..."
    unset NIX_DEV_ENV
  fi
}

# Run cleanup when a shell exits, to ensure that the `NIX_DEV_ENV` is updated
autoload -Uz add-zsh-hook
add-zsh-hook precmd cleanup_nix_env
```

**Prompt for dev environment with `p10k`**

Update the `~/.p10k.zsh` so that it include the `NIX_DEV_ENV` variable.

1. Add `nixdevenv` to either the `POWERLEVEL9K_LEFT_PROMPT_ELEMENTS` or `POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS` array.

1. Add this functions to the `~/.p10k.zsh` file:
  ``` shell
  function prompt_nixdevenv() {
    local nix_dev_env
    nix_dev_env=$(echo $NIX_DEV_ENV)
    p10k segment -b 1 -f 0 -t "$nix_dev_env"
  }

  function instant_prompt_nixdevenv() {
    prompt_nixdevenv
  }

  typeset -g POWERLEVEL9K_NIXDEVENV_FOREGROUND=0
  typeset -g POWERLEVEL9K_NIXDEVENV_BACKGROUND=1
  ```