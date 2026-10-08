#!/usr/bin/env zsh
### Helper functions ###
function _alias_parser() {
  local parsed_alias
  parsed_alias=$(alias -- "$1")
  if [[ $? == 0 ]]; then
    echo $parsed_alias | awk -F\' '{print $2}'
  fi
}
function _alias_finder() {
  local final_result s alias_val
  final_result=()
  for s in $(echo $1); do
    alias_val=$(_alias_parser "$s")
    if [[ -n $alias_val ]]; then
      # Handle nested aliases with the same name
      if [[ $alias_val == *"$s"* ]]; then
        final_result+=($alias_val)
      else
        final_result+=($(_alias_finder "$alias_val"))
      fi
    else
      final_result+=($s)
    fi
  done
  echo "${final_result[@]}"
}
### Random functions ###
function mwatch() {
  local final_alias
  final_alias=$(_alias_finder "$*")
  echo $final_alias
  watch --color "$final_alias"
}
function docke() {
  docker "$@"
}

function ssh2() {
  in_url=$(sed -e 's/ip-//' -e 's/-/./g' <<<"$1")
  echo $in_url && ssh $in_url
}
function jsonlint() {
  pbcopy && open https://jsonlint.com/
}
function grl() {
  grep -rl $* .
}
### Git functions ###
# Open the github page of the repo you're in, in the browser
function opengit() {
  git remote -v | awk 'NR==1{print $2}' | sed -e "s?:?/?g" -e 's?\.git$??' -e "s?git@?https://?" -e "s?https///?https://?g" | xargs open
}
# Create pull request = cpr (same logic as <leader>PR / :Cpr in nvim)
function cpr() {
  local remote_url host project_repo project repo git_name web_host pr_link branch_name
  remote_url=$(git remote get-url origin 2>/dev/null)
  if [[ -z $remote_url ]]; then
    print -u2 "cpr: could not find remote 'origin'"
    return 1
  fi
  if [[ $remote_url == git@* ]]; then
    # git@host:project/repo.git
    host=${remote_url#git@}
    host=${host%%:*}
    project_repo=${remote_url#*:}
  elif [[ $remote_url == https://* ]]; then
    # https://host/project/repo.git
    host=${remote_url#https://}
    host=${host%%/*}
    project_repo=${remote_url#https://*/}
  else
    print -u2 "cpr: could not parse git remote URL: $remote_url"
    return 1
  fi
  project_repo=${project_repo%.git}
  project=${project_repo%/*}
  repo=${project_repo##*/}
  if [[ -z $host || -z $project || -z $repo || $project == "$project_repo" ]]; then
    print -u2 "cpr: could not parse git remote URL: $remote_url"
    return 1
  fi
  # ssh-config host aliases (github.com-emu, github-personal, ...) map back to the real web host
  web_host=$host
  if [[ $remote_url == git@* ]]; then
    web_host=$(ssh -G "$host" 2>/dev/null | awk '/^hostname /{print $2; exit}')
    [[ -n $web_host ]] || web_host=$host
  fi
  if [[ $web_host == "github.com-emu" ]]; then
    web_host="github.com"
  fi
  # git provider from host, e.g. 'github' from 'github.com' or 'gitlab' from 'gitlab.com'
  git_name=${web_host%%[^[:alnum:]]*}
  case $git_name in
  gitlab) pr_link="-/merge_requests/new?merge_request[source_branch]=" ;;
  bitbucket) pr_link="pull-requests/new?source=" ;;
  *) pr_link="pull/new/" ;;
  esac
  branch_name=$(git branch --show-current)
  if [[ -z $branch_name ]]; then
    print -u2 "cpr: could not get current branch"
    return 1
  fi
  open "https://${web_host}/${project}/${repo}/${pr_link}${branch_name}"
}

function bitbucket_ro() {
  local tok
  tok=$(bw get password 'bitbucket-ro-api-token') || {
    print -u2 "bitbucket_ro: bw failed -- vault locked? run 'bw unlock'"
    return 1
  }
  [[ -n $tok ]] || { print -u2 "bitbucket_ro: got an empty token"; return 1; }
  # Names the @aashari/mcp-server-atlassian-bitbucket MCP server actually reads.
  export ATLASSIAN_USER_EMAIL="ben.saada@aquasec.com"
  export ATLASSIAN_API_TOKEN="$tok"
  export BITBUCKET_DEFAULT_WORKSPACE="scalock"
  # Legacy names, kept for anything else that still expects them.
  export BITBUCKET_USERNAME="$ATLASSIAN_USER_EMAIL"
  export BITBUCKET_TOKEN="$tok"
}

### AWS functions ###
function gparamsp() {
  local parameter
  parameter=$(aws ssm describe-parameters --parameter-filters Key=Name,Values="$1",Option=Contains | jq ".[][0].Name" -r)
  aws ssm get-parameter --name $parameter --profile $AWS_PROFILE --with-decryption | jq ".[]|[.Name,.Value]"
}

function dparamsp() {
  local aws_param_temp
  aws_param_temp=$(aws ssm describe-parameters --parameter-filters Key=Name,Values="$1",Option=Contains | jq '.Parameters[].Name' -r | fzf)
  if [ $aws_param_temp ]; then
    aws ssm get-parameter --name $aws_param_temp --profile $AWS_PROFILE --with-decryption | jq ".[]|[.Name,.Value]"
  fi
}

function gsecretsp() {
  local secret
  secret=$(aws secretsmanager list-secrets --filters Key=name,Values="$1" --profile $AWS_PROFILE | jq ".[][0].Name" -r)
  aws secretsmanager get-secret-value --secret-id $secret --profile $AWS_PROFILE | jq "[.Name,.SecretString]"
}

function dsecretsp() {
  local aws_secret_temp
  aws_secret_temp=$(aws secretsmanager list-secrets --profile $AWS_PROFILE | jq -r '.SecretList[].Name' | grep -E "$1" | fzf)
  if [ $aws_secret_temp ]; then
    aws secretsmanager get-secret-value --secret-id $aws_secret_temp --profile $AWS_PROFILE | jq "[.Name,.SecretString]"
  fi
}

# --- aws profile switcher --------------------------------------------------
aws_p() {
  local profiles profile

  # subcommands that don't need the profile list
  case $1 in
  -h | --help)
    cat <<'EOF'
usage:
  aws_p                pick a profile with fzf
  aws_p NAME           set NAME directly, or filter the picker if partial
  aws_p off            unset AWS_PROFILE / AWS_REGION
  aws_p -c, --current  show the active profile
  aws_p -l, --list     print profile names, one per line
EOF
    return 0
    ;;
  off)
    unset AWS_PROFILE AWS_REGION
    echo "AWS_PROFILE unset"
    return 0
    ;;
  -c | --current)
    echo "${AWS_PROFILE:-<none>}"
    return 0
    ;;
  esac

  profiles=$(sed -nE 's/^\[profile[[:space:]]+([^]]+)\][[:space:]]*$/\1/p;
                      s/^\[default\][[:space:]]*$/default/p' ~/.aws/config 2>/dev/null)

  if [[ -z $profiles ]]; then
    echo "aws_p: no profiles found in ~/.aws/config" >&2
    return 1
  fi

  case $1 in
  -l | --list)
    printf '%s\n' "$profiles"
    return 0
    ;;
  esac

  if [[ -n $1 ]]; then
    if grep -qxF -- "$1" <<<"$profiles"; then
      profile=$1 # exact match, skip fzf entirely
    else
      profile=$(fzf --height 40% --reverse --prompt='aws profile> ' \
        --query="$1" --select-1 --exit-0 <<<"$profiles")
      if [[ -z $profile ]]; then
        echo "aws_p: no profile matching '$1'" >&2
        return 1
      fi
    fi
  else
    profile=$(fzf --height 40% --reverse --prompt='aws profile> ' <<<"$profiles") || return
    [[ -z $profile ]] && return
  fi

  export AWS_PROFILE="$profile"
  echo "AWS_PROFILE=$profile"
}

# `complete` is a bash-only builtin; without this guard, sourcing this file
# in zsh before oh-my-zsh's `aws` plugin has run `bashcompinit` (e.g. via
# .zshenv, or any non-interactive zsh invocation) fails with
# "command not found: complete".
if [[ -n $ZSH_VERSION ]]; then
  autoload -Uz bashcompinit && bashcompinit
fi
complete -W '$(aws_p --list)' aws_p 2>/dev/null

function aws_ecr_login() {
  aws ecr get-login-password --region $(aws configure get region --output text) | docker login --username AWS --password-stdin $(aws sts get-caller-identity | jq '.Account' -r).dkr.ecr.$(aws configure get region --output text).amazonaws.com
}

### Azure functions ###

### Kubernetes functions ###
function kdpw() {
  watch "kubectl describe po $* | tail -20"
}
function kgres() {
  kubectl get pod $* \
    -ojsonpath='{range .items[*]}{.spec.containers[*].name}{" memory: "}{.spec.containers..resources.requests.memory}{"/"}{.spec.containers..resources.limits.memory}{" | cpu: "}{.spec.containers..resources.requests.cpu}{"/"}{.spec.containers..resources.limits.cpu}{"\n"}{end}' | sort \
    -u \
    -k1,1 | column -t
}

function kgpimg() {
  kgp $* -ojson | jq '.spec.containers[].image'
}
function kubedebug() {
  # image=gcr.io/kubernetes-e2e-test-images/dnsutils:1.3
  local image=nicolaka/net-debug:latest
  local docker_exe=bash
  local pod_name=network-debug
  local kubectl_args=()
  local processing_k_args=false
  while test $# -gt 0; do
    if $processing_k_args; then
      kubectl_args=($kubectl_args $1)
      shift
      continue
    fi
    case $1 in
    # exe provided
    -e)
      shift
      docker_exe=$1
      ;;
    -p)
      shift
      pod_name=$1
      ;;
    -i)
      shift
      image=$1
      ;;
    *)
      if [[ "$1" == "--" ]]; then
        processing_k_args=true
      fi
      ;;
    esac
    shift
  done
  kubectl run \
    -i \
    --rm \
    --tty \
    --image=$image \
    --restart=Never \
    ${kubectl_args[*]} \
    $pod_name \
    -- \
    $docker_exe
}
function get_pods_of_svc() {
  local svc_name label_selectors
  svc_name=$1
  shift
  label_selectors=$(kubectl get svc $svc_name $* -ojsonpath="{.spec.selector}" | jq -r "to_entries|map(\"\(.key)=\(.value|tostring)\")|.[]" | paste -s -d "," -)
  kubectl get pod $* -l $label_selectors
}

function rmpods() {
  for i in $(kgp G "$1" | awk '{print $1}'); do kdelp "$i"; done
}

argocd_web() {
  local argocd_ingress ingress_host creds CMDPID
  argocd_ingress=$(kubectl get ingress -n argocd --no-headers -o custom-columns=":metadata.name" | grep argocd-server)
  ingress_host=https://$(kubectl get ingress -n argocd "${argocd_ingress}" -ojson | jq -r '.spec.rules[].host')
  creds=$(kubectl get secret -n argocd argocd-initial-admin-secret -ojson | jq '.data | with_entries(.value |= @base64d)')
  if [[ -n $1 ]] && [[ $1 == "-f" ]]; then
    kubectl port-forward -n argocd svc/argocd-server 8080:443 &
    CMDPID=$!
    ingress_host="http://localhost:8080"
    echo "waiting for port-forward to start"
    while ! lsof -nP -iTCP:8080 | grep --color LISTEN; do
      echo "port 8080 is still not open"
      sleep 1
    done
    echo "Port forward for svc/argocd-server started on port 8080"
    echo "To kill, run 'kill $CMDPID' or exit the shell"
  fi
  # Don't echo the decoded admin password to stdout/history; just copy it.
  jq -r '.password' <<<"${creds}" | pbcopy
  echo "Admin password copied to clipboard"
  unset creds
  open "${ingress_host}"
}

fdf() {
  local dir_clean all_files dir_to_enter
  # remove trailing / from $1
  dir_clean=${1%/}
  all_files=$(find $dir_clean/* -maxdepth 0 -type d -print 2>/dev/null)
  dir_to_enter=$(sed "s?$dir_clean/??g" <<<$all_files | fzf)
  cd "$dir_clean/$dir_to_enter" && nvim
}
alias pj='fdf ~/repos'
### General aliases ###
alias lla='ls -la'
alias cat='bat'
alias watch='watch --color '
alias vim="nvim"
alias v='nvim'
alias vi='nvim'
alias sed=gsed
alias grep=ggrep
alias sort=gsort
alias dc='cd '
# global aliases
alias -g Wt='while :;do '
alias -g Wr=' | while read -r line;do '
alias -g D=';done'
alias -g S='| sort'
alias -g SRT='+short | sort'
alias -g Sa='--sort-by=.metadata.creationTimestamp'
alias -g Srt='--sort-by=.metadata.creationTimestamp'
alias -g SECRET='-ojson | jq ".data | with_entries(.value |= @base64d)"'
alias -g YML='-oyaml | vim -c "setlocal buftype=nofile filetype=yaml | nnoremap <buffer> q :qall<cr>"'
alias -g NM=' --no-headers -o custom-columns=":metadata.name"'
alias -g RC='--sort-by=".status.containerStatuses[0].restartCount" -A | grep -v "\s0\s"'
### Git related ###
# see recently pushed branches
# alias gb="git for-each-ref --sort=-committerdate --format='%(refname:short)' refs/heads | fzf | xargs git checkout && git pull"
alias gb='git for-each-ref --sort=-committerdate --format="%(refname:short)" | grep -n . | sed "s?origin/??g" | sort -t: -k2 -u | sort -n | cut -d: -f2 | fzf | xargs git checkout'
alias gp="git push --set-upstream origin HEAD"
alias gml="git checkout \$(git symbolic-ref refs/remotes/origin/HEAD | tr \"/\" \" \" | awk '{print \$4}') && git pull"
alias groot="cd \$(git rev-parse --show-toplevel)"
alias repos="cd ~/repos"
# run `gml` (checkout default branch + pull) in every git repo under ~/repos
function gml_all() {
  local repos_dir="${1:-$HOME/repos}"
  local repo default_branch failed=()
  for repo in "$repos_dir"/*/; do
    repo="${repo%/}"
    [[ -d "$repo/.git" ]] || continue
    printf '\n\033[1;34m==> %s\033[0m\n' "${repo##*/}"
    (
      cd "$repo" || exit 1
      default_branch=$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed 's#^origin/##')
      if [[ -z "$default_branch" ]]; then
        default_branch=$(git remote show origin 2>/dev/null | awk '/HEAD branch/ {print $NF}')
      fi
      [[ -n "$default_branch" ]] || { echo "could not detect default branch"; exit 1; }
      git checkout "$default_branch" && git pull
    ) || failed+=("${repo##*/}")
  done
  if (( ${#failed[@]} )); then
    printf '\n\033[1;31mFailed:\033[0m %s\n' "${failed[*]}"
    return 1
  fi
  printf '\n\033[1;32mAll repos updated.\033[0m\n'
}
### Shortcuts to directories ###
alias difff='code --diff'
### Kubernetes Aliases ###
alias cinfo='kubectl cluster-info'
alias kafd='kubectl apply --validate=true --dry-run=true -f -'
alias kgdns="kubectl get services --all-namespaces -o jsonpath='{.items[*].metadata.annotations.external-dns\.alpha\.kubernetes\.io/hostname}' | tr ' ' '\n'"
alias kns='kubens'
alias ctx='kubectx'
alias kmem='kubectl top node | (gsed -u 1q;sort -r -hk5)'
alias kcpu='kubectl top node | (gsed -u 1q;sort -r -hk3)'
alias ktn='kubectl top node'
alias ktp='kubectl top pod'
alias krs='kubectl rollout restart'
alias kesec='kubectl edit secret'
alias kgnol='kgno -l'
alias kgpname='kubectl get pod --no-headers -o custom-columns=":metadata.name"'
alias kgdname='kubectl get deployment --no-headers -o custom-columns=":metadata.name"'
alias kg='kubectl get '
alias kd='kubectl describe '
alias ke='kubectl edit '
alias kdel='kubectl delete '
alias ktestpod='kubectl run netshoot --image=nicolaka/netshoot --rm -it -- /bin/bash'
# Kubectl Persistent Volume
alias kgpv='kubectl get persistentvolume'
alias kdpv='kubectl describe persistentvolume'
alias kepv='kubectl edit persistentvolume'
alias kdelpv='kubectl delete persistentvolume'
# Kubectl jobs
alias kgj='kubectl get job'
alias kdj='kubectl describe job'
alias kej='kubectl edit job'
alias kdelj='kubectl delete job'
# Kubectl Statefulsets
alias kgsts='kubectl get statefulsets'
alias kdsts='kubectl describe statefulsets'
alias kests='kubectl edit statefulsets'
alias kdelsts='kubectl delete statefulsets'
# Common Used tools:
alias brave='open -a "Brave Browser"'
alias spotify='open -a "Spotify"'
alias outlook='open -a "Microsoft Outlook"'
alias slack='open -a "Slack"'
alias sublime='open -a "Sublime Text"'
alias zoom='open -a "zoom.us"'
alias tgrmtrace="rm -rf aws-provider.tf backend.tf terragrunt_variables.tf versions.tf azure-provider.tf providers-tg-generated.tf .azure .terraform"
alias tf='terraform'
alias tg='terragrunt'
alias update-nvim-nightly='asdf uninstall neovim nightly && asdf install neovim nightly'
