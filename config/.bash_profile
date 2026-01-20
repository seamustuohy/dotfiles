TZ='America/New_York'; export TZ
ORG_TIMEW_FILE="${HOME}/.org/taskw.org"; export ORG_TIMEW_FILE
XDG_CONFIG_HOME="${HOME}/.config"; export XDG_CONFIG_HOME
XDG_CACHE_HOME="${HOME}/.cache"; export XDG_CACHE_HOME
XDG_DATA_HOME="${HOME}/.local/share"; export XDG_DATA_HOME

# if running bash
if [ -n "$BASH_VERSION" ]; then
    # include .bashrc if it exists
    if [ -f "$HOME/.bashrc" ]; then
        . "$HOME/.bashrc"
    fi
fi
