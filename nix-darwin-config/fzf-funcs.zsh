# fif - search for text in files and preview the match
fif() {
  if [ ! "$#" -gt 0 ]; then
    echo "Need a string to search for!"
    return 1
  fi

  rg --files-with-matches --no-messages "$1" | \
  fzf --preview "highlight -O ansi -l {} 2> /dev/null | rg --colors 'match:bg:yellow' --ignore-case --pretty --context 10 '$1' || rg --ignore-case --pretty --context 10 '$1' {}"
}

# fbr - fuzzy checkout git branch
fbr() {
  local branches branch
  branches=$(git for-each-ref --count=30 --sort=-committerdate refs/heads/ --format="%(refname:short)") &&
  branch=$(echo "$branches" | fzf-tmux -d $(( 2 + $(wc -l <<< "$branches") )) +m) &&
  git checkout $(echo "$branch" | sed "s/.* //" | sed "s#remotes/[^/]*/##")
}

# fshow - git commit browser with preview and color
fshow() {
  git log -n 100 --graph --color=always \
    --format="%C(auto)%h%d %s %C(black)%C(bold)%cr" "$@" | \
  fzf --ansi --no-sort --reverse --tiebreak=index \
      --preview "echo {} | grep -o '[a-f0-9]\\{7,\\}' | head -1 | xargs -I % git show --color=always --stat %" \
      --bind "ctrl-m:execute:
        echo {} | grep -o '[a-f0-9]\\{7,\\}' | head -1 |
        xargs -I % sh -c 'git show --color=always % | less -R'"
}


# vf - fuzzy find files using locate and open with Neovim
vf() {
  if [[ -z "$@" ]]; then
    echo "Usage: vf <search terms...>"
    return 1
  fi

  local files
  files=(${(f)"$(locate -Ai -0 "$@" | grep -z -vE '~$' | fzf --read0 -0 -1 -m)"})

  if [[ -n $files ]]; then
    nvim -- $files
    print -l "$files[1]"
  fi
}

FZF_PROJECT_ROOTS=(~/matchi ~/projects ~/lab ~/work)

vscd() {
  local dir
  dir=$( (find "${FZF_PROJECT_ROOTS[@]}" -type d -not -path '*/\.*' 2>/dev/null;
          find . -type d -not -path '*/\.*' 2>/dev/null) | \
    awk '!seen[$0]++' | \
    fzf --height=40% --reverse \
        --preview 'ls -la {}' \
        --prompt="Open folder > ")

  [[ -n "$dir" ]] && code "$dir" && cd "$dir"
}

fzf-help() {
  cat <<'EOF'

🔥 FZF Command Palette
────────────────────────────────────────────
fif   <pattern>     Fuzzy search inside files and preview matching lines
                    Example: fif config

fbr                 Fuzzy switch to a recent Git branch
                    Example: fbr

fshow              Fuzzy browse recent Git commits with preview
                    Example: fshow

vf    <keyword>     Fuzzy locate files using `locate` and open in Neovim
                    Example: vf docker-compose

vscd                Fuzzy search folders from key locations and open in VS Code
                    Example: vscd

ghwf                Fuzzy browse recent GitHub Actions workflow runs
                    Requires: \$GH_WORKFLOW_REPOS set to repos (e.g. "org/repo1 org/repo2")
                    Preview: Shows each run’s jobs with status and conclusion
                    Example:
                      export GH_WORKFLOW_REPOS="matchiapp/matchi-backend matchiapp/keycloak"
                      ghwf

Tips:
• All fzf windows support typing, arrow keys, and ENTER to select
• `ctrl-s` in fshow toggles sorting
• `vscd` searches in: ${FZF_PROJECT_ROOTS[*]}

EOF
}

ghwf() {
  while true; do
    clear
    ghwf_exec
    sleep 300
  done
}


ghwf_exec() {
  local repos=(${(s: :)GH_WORKFLOW_REPOS})

  if [[ ${#repos[@]} -eq 0 ]]; then
    echo "❌ Set GH_WORKFLOW_REPOS to space-separated list like 'matchiapp/matchi-backend matchiapp/keycloak'"
    echo "Will use default repos matchiapp/matchi-backend"
    repos=(matchiapp/matchi-backend)
  fi

  local runs
  runs=$(
  {
    for repo in $repos; do
      printf "URL\tStatus\tResult\tRepo\tTitle\tBranch\n"
      gh run list --repo "$repo" --limit 50 \
        --json url,headBranch,status,conclusion,displayTitle \
        --template '{{range .}}{{.url}}\t{{.status}}\t{{.conclusion}}\t'"$repo"'\t{{.displayTitle}}\t{{.headBranch}}{{"\n"}}{{end}}'
    done
  } | ghwf_symbols | column -t -s $'\t'
  )

  echo "$runs"| \
  fzf --ansi \
      --with-nth=2.. \
      --preview '
  url=$(echo {} | awk "{print \$1}")
  id=$(basename "$url")
  repo=$(echo {} | awk "{print \$4}")
  gh run view "$id" --repo "$repo" --json jobs --template "
{{- printf \"Job\tStatus\tConclusion\\n\" -}}
{{- range .jobs }}
{{- printf \"%s\t%s\t%s\\n\" .name .status .conclusion -}}
{{- end }}
" | sed -e 's/in_progress/🔄/g' \
        -e 's/queued/⏳/g' \
        -e 's/completed/🏁/g' \
        -e 's/success/✅/g' \
        -e 's/failure/❌/g' \
        -e 's/cancelled/🚫/g' \
        -e 's/skipped/⏭/g' \
        -e 's/neutral/⚪️/g' \
        -e 's/timed_out/⌛/g'
      '\
      --preview-window=right,25% \
      --bind "enter:execute(
        url=\$(echo {} | awk '{print \$1}')
        id=\$(basename \"\$url\")
        repo=\$(echo {} | awk '{print \$4}')
        gh run view \$id --repo \$repo --web
      )"
}

ghwf_symbols() {
  sed -e 's/in_progress/🔄/g' \
      -e 's/queued/⏳/g' \
      -e 's/completed/🏁/g' \
      -e 's/success/✅/g' \
      -e 's/failure/❌/g' \
      -e 's/cancelled/🚫/g' \
      -e 's/skipped/⏭/g' \
      -e 's/neutral/⚪️/g' \
      -e 's/timed_out/⌛/g'
}

