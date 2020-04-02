#!/usr/bin/env bash


#####################################
# Setup
#####################################

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

#####################################
# Alias
#####################################
if [ -f ~/.bash_alias ]; then
    source ~/.bash_alias
fi

# Docker Functions
if [ -f ~/.dockerfunc ]; then
    source ~/.dockerfunc
fi

#####################################
# Variables
#####################################

# Mobile Home
# I sometimes keep some files in a mobile home directory mobile so that I can easily switch between different computers. This helps script to that.
export MOBILE_HOME=/media/veracrypt11/


# Org Files
export ORG_TIMEW_FILE="${HOME}/.org/projects.org"

# Editor : set default editor to emacs
export EDITOR=emacs


#####################################
#        HISTORY CONTROLS
#####################################

# Huge history. Doesn't appear to slow things down, so why not?
# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)

HISTSIZE=500000
HISTFILESIZE=100000

# Don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options

HISTCONTROL=ignoreboth

# Append to the history file, don't overwrite it

shopt -s histappend

# ALSO See: PROMPT_COMMAND below

# Don't record some commands

export HISTIGNORE="&:[ ]*:exit:ls:bg:fg:history:clear:pwd"

# remove duplicates while preserving input order

function dedup {
   awk '! x[$0]++' "$@"
}

# removes $HISTIGNORE commands from input

function remove_histignore {
   if [ -n "$HISTIGNORE" ]; then
      # replace : with |, then * with .*
      local IGNORE_PAT=`echo "$HISTIGNORE" | sed s/\:/\|/g | sed s/\*/\.\*/g`
      # negated grep removes matches
      grep -vx "$IGNORE_PAT" "$@"
   else
      cat "$@"
   fi
}

# clean up the history file by remove duplicates and commands matching $HISTIGNORE entries

function history_cleanup {
   local HISTFILE_SRC=~/.bash_history
   local HISTFILE_DST=/tmp/.$USER.bash_history.clean
   if [ -f $HISTFILE_SRC ]; then
      \cp $HISTFILE_SRC $HISTFILE_SRC.backup
      dedup $HISTFILE_SRC | remove_histignore >| $HISTFILE_DST
      \mv $HISTFILE_DST $HISTFILE_SRC
      chmod go-r $HISTFILE_SRC
      history -c
      history -r
   fi
}

# #run histroy cleanup on bash startup

history_cleanup

# Colors

export TERM=xterm-color
export CLICOLOR=1

# Colorize basic commands

alias ls="ls --color=auto"
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# Prompt

PS1="\[\e[32m\]\$(parse_git_branch)\[\e[34m\]\h:\W \$ \[\e[m\]"

# ..fix tangle errors..

PROMPT_COMMAND=prompt_commands

# Add additional prompt commands to the function below
#   - update histfile after every command

prompt_commands() {
        history -a
}

# Display

# Check the window size after each command and, if necessary, update the values of LINES and COLUMNS.

shopt -s checkwinsize

# Completion

# If set, the pattern "**" used in a pathname expansion context will match all files and zero or more directories and subdirectories.

shopt -s globstar

# Enable programmable completion features (you don't need to enable this, if it's already enabled in /etc/bash.bashrc and /etc/profile sources /etc/bash.bashrc).

if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

# Perform file completion in a case insensitive fashion

bind "set completion-ignore-case on"

# Treat hyphens and underscores as equivalent

bind "set completion-map-case on"

# Display matches for ambiguous patterns at first tab press

bind "set show-all-if-ambiguous on"

# PATH
# Add CASK to the path for emacs if using cask
# export PATH="$PATH:$HOME/.cask/bin"

# SSH Agent & GPG
# Set SSH_AUTH_SOCK
unset SSH_AGENT_PID
if [ "${gnupg_SSH_AUTH_SOCK_by:-0}" -ne $$ ]; then
  export SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)"
fi

# Configure pinentry to use the correct TTY
# Also set the GPG_TTY and refresh the TTY in case user has switched into an X session as stated in gpg-agent(1). For example:

export GPG_TTY=$(tty)
gpg-connect-agent updatestartuptty /bye >/dev/null



# Add go to path
export PATH=$PATH:/usr/local/go/bin
# Install Ruby Gems to ~/gems
export GEM_HOME="$HOME/gems"
export PATH="$HOME/gems/bin:$PATH"
