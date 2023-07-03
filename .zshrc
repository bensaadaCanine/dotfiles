export ZSH="/Users/bsaada/.oh-my-zsh"

ZSH_THEME="robbyrussell"

COMPLETION_WAITING_DOTS="false"
DISABLE_UNTRACKED_FILES_DIRTY="true"

# Set Locale
export LANG=en_US
export LC_CTYPE=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# History settings
HISTSIZE=5000
SAVEHIST=5000
setopt BANG_HIST              # Treat the '!' character specially during expansion.
setopt EXTENDED_HISTORY       # Write the history file in the ":start:elapsed;command" format.
setopt INC_APPEND_HISTORY     # Write to the history file immediately, not when the shell exits.
setopt SHARE_HISTORY          # Share history between all sessions.
setopt HIST_EXPIRE_DUPS_FIRST # Expire duplicate entries first when trimming history.
setopt HIST_IGNORE_DUPS       # Don't record an entry that was just recorded again.
setopt HIST_IGNORE_ALL_DUPS   # Delete old recorded entry if new entry is a duplicate.
setopt HIST_FIND_NO_DUPS      # Do not display a line previously found.
setopt HIST_IGNORE_SPACE      # Don't record an entry starting with a space.
setopt HIST_SAVE_NO_DUPS      # Don't write duplicate entries in the history file.
setopt HIST_REDUCE_BLANKS     # Remove superfluous blanks before recording entry.
setopt HIST_VERIFY            # Don't execute immediately upon history expansion.
setopt HIST_BEEP              # Beep when accessing nonexistent history.

plugins=(
  autoupdate
  aws
  colored-man-pages
  common-aliases
  git
  helm
  kubectl
  zsh-autosuggestions
  zsh-syntax-highlighting
)
fpath+=${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions/src
source $ZSH/oh-my-zsh.sh

# =================== #
# Completions and PS1 #
# =================== #

alias brave='open -a "Brave Browser"'
alias spotify='open -a "Spotify"'
alias outlook='open -a "Microsoft Outlook"'
alias slack='open -a "Slack"'
alias sublime='open -a "Sublime Text"'
alias zoom='open -a "zoom.us"'
alias tg=terragrunt

[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
alias ssv="/usr/local/bin/ssv.sh awsjump"
alias ssvd="/usr/local/bin/ssv.sh devjump"
alias tgrmtrace="rm -f aws-provider.tf backend.tf terragrunt_variables.tf versions.tf"

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"
alias repos="cd ~/github"
alias watch='watch '

source ~/aliases.sh
export EDITOR=nvim
export AWS_PROFILE=dev
source "/usr/local/opt/kube-ps1/share/kube-ps1.sh"
RPS1="[%B%F{green}AWS%f:%F{red}\${AWS_PROFILE}%b%f] [%B%F{blue}Azure%f:%F{red}\$(az account show | jq '.name' -r | awk '{print \$2}')%b%f] \$(kube_ps1)"
