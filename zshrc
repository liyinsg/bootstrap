HISTFILE=$HOME/.zsh_history
HISTSIZE=4096
SAVEHIST=4096
export CLICOLOR=1
export EDITOR=vim
setopt EXTENDEDGLOB
setopt APPEND_HISTORY
setopt EXTENDED_HISTORY
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_VERIFY
setopt SHARE_HISTORY
setopt INC_APPEND_HISTORY
unsetopt CHASE_DOTS
unsetopt CHASE_LINKS
unsetopt FLOW_CONTROL
bindkey -e
zstyle :compinstall filename '/home/ly/.zshrc'
autoload -Uz compinit
setopt COMPLETEALIASES
compinit
autoload edit-command-line
zle -N edit-command-line
bindkey '\C-x\C-e' edit-command-line

if [[ -n $SSH_CONNECTION ]]; then
	PROMPT="%(?..%{[38;5;001m%}%? )%{[38;5;011m%}%m:%{[38;5;010m%}%~%{[0m%} "
else
	PROMPT="%(?..%{[38;5;001m%}%? )%{[38;5;010m%}%~%{[0m%} "
fi
