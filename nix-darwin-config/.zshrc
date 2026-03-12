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
    echo " base, webapp, golang, keycloak, frontend, fullstack"
    return 1
  fi
  export NIX_DEV_ENV="$1"
  nix develop ~/.config/nix/nix-dev-envs#"$1" -c zsh
  unset NIX_DEV_ENV
}

# Tab completion for `dev` function
_dev_complete() {
  reply=("base" "webapp" "golang" "keycloak" "frontend" "fullstack")
}

compctl -K _dev_complete dev

# Fix $SHELL inside nix develop (it overrides to nix bash)
if [[ -n "$NIX_DEV_ENV" ]]; then
  export SHELL=$(command -v zsh)
fi

# Source SDKMAN in zsh for dev shells that need it
if [[ "$NIX_DEV_ENV" == "webapp" || "$NIX_DEV_ENV" == "fullstack" ]]; then
  export SDKMAN_DIR="$HOME/.sdkman"
  [[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"
fi


runIdeaWebapp() {
    if [[ "$NIX_DEV_ENV" != "webapp" ]]; then
      echo "Not running WebApp: Not in webapp environment"
      return 1
    fi
    cd "$HOME/workspace/matchi/webapp" && ./run.sh "/Applications/IntelliJ IDEA.app/Contents/MacOS/idea" "$HOME/workspace/matchi/webapp" > /dev/null 2>&1 &
}

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


eval "$(starship init zsh)"

export PATH="$HOME/.local/bin:$PATH"
