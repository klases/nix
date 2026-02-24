# Oh My Zsh setup
export ZSH="$HOME/.oh-my-zsh"

# Env vars for fzf plugin
export FZF_BASE=$(which fzf)
export FZF_DEFAULT_OPTS="--height=50% --reverse --border --prompt='> '"

# Plugins for general shell usage
plugins=(git docker 1password git-commit aws kubectl fzf)
source $ZSH/oh-my-zsh.sh

# Load fzf keybindings and completions (Nix-installed)
source $(fzf-share)/key-bindings.zsh
source $(fzf-share)/completion.zsh

# fsf functions
[[ -f "$HOME/.config/nix/nix-darwin-config/fzf-funcs.zsh" ]] && source "$HOME/.config/nix/nix-darwin-config/fzf-funcs.zsh"


# Aliases
alias nix-darwin-rebuild="sudo darwin-rebuild switch --flake ~/.config/nix/nix-darwin-config"

# Remove any existing alias for `dev`
unalias dev 2>/dev/null

export EDITOR="zed --wait"

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

# Tab completion for `dev` function
_dev_complete() {
  reply=("base" "webapp" "golang" "frontend" "github-workflows" "keycloak" "fullstack")
}

compctl -K _dev_complete dev


cleanup_nix_env() {
  # If inside a normal shell and `NIX_DEV_ENV` is set, clean it silently
  if [[ -z "$IN_NIX_SHELL" && -n "$NIX_DEV_ENV" ]]; then
    echo "Exiting Nix DevShell: Cleaning NIX_DEV_ENV..."
    unset NIX_DEV_ENV
  fi
}

runIdeaWebapp() {
    if [[ "$NIX_DEV_ENV" != "webapp" ]]; then
      echo "Not running WebApp: Not in webapp environment"
      return 1
    fi
    cd "$HOME/matchi/repos/webapp" && ./run.sh "/Applications/IntelliJ IDEA.app/Contents/MacOS/idea" > /dev/null 2>&1 &
}


# Run cleanup when a shell exits
autoload -Uz add-zsh-hook
add-zsh-hook precmd cleanup_nix_env

# Git identity selector
_git_identity_session() {
  case "$1" in
    klases)
      export GIT_SSH_COMMAND="ssh -i ~/.ssh/id_rsa -o IdentitiesOnly=yes"
      echo "🔑 Using personal GitHub key (id_rsa)"
      ;;
    matchi)
      export GIT_SSH_COMMAND="ssh -i ~/.ssh/id_matchi -o IdentitiesOnly=yes"
      echo "🏢 Using Matchi GitHub key (id_matchi)"
      ;;
    *)
      command git "$@"
      return
      ;;
  esac
}

# Override `git` command
git() {
  if [[ "$1" == "klases" || "$1" == "matchi" ]]; then
    _git_identity_session "$1"
  else
    command git "$@"
  fi
}


#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="/Users/claeseklund/.sdkman"
[[ -s "/Users/claeseklund/.sdkman/bin/sdkman-init.sh" ]] && source "/Users/claeseklund/.sdkman/bin/sdkman-init.sh"


# test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

eval "$(starship init zsh)"


export PATH="$PATH:$HOME/.dotnet/tools"
export PATH=$PATH:$HOME/.maestro/bin
export PATH="$HOME/.local/bin:$PATH"
