# Enable Powerlevel10k instant prompt (keep at the top)
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Oh My Zsh setup
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=powerlevel10k/powerlevel10k

# Plugins for general shell usage
plugins=(git docker 1password git-commit)
source $ZSH/oh-my-zsh.sh

# Load Powerlevel10k prompt configuration
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Keep Homebrew paths
export PATH="/opt/homebrew/bin:$PATH"

# Aliases
alias nix-darwin-rebuild="darwin-rebuild switch --flake ~/.config/nix/nix-darwin-config"

# Remove any existing alias for `dev`
unalias dev 2>/dev/null

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
  reply=("base" "webapp" "personal" "golang" "frontend" "github-workflows" "gcp")
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


#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="/Users/claeseklund/.sdkman"
[[ -s "/Users/claeseklund/.sdkman/bin/sdkman-init.sh" ]] && source "/Users/claeseklund/.sdkman/bin/sdkman-init.sh"

