TZ='America/New_York'; export TZ
ORG_TIMEW_FILE="${HOME}/.org/taskw.org"; export ORG_TIMEW_FILE
XDG_CONFIG_HOME="${HOME}/.config"; export XDG_CONFIG_HOME
XDG_CACHE_HOME="${HOME}/.cache"; export XDG_CACHE_HOME
XDG_DATA_HOME="${HOME}/.local/share"; export XDG_DATA_HOME



# Set pass information
PASSWORD_STORE_DIR="${HOME}/dotfiles/private/pass"; export PASSWORD_STORE_DIR
PASSWORD_STORE_KEY="36AC272EB7CFEDD5F907E488B6193EC73CF07AA7"; export PASSWORD_STORE_KEY
# Don't have a consistent random length to better thwart targeted cracking attempts
PASSWORD_STORE_GENERATED_LENGTH=$(shuf -i30-50 -n1); export PASSWORD_STORE_GENERATED_LENGTH
# Remove the letters and special chars that always ruin things for me.
PASSWORD_STORE_CHARACTER_SET='[:digit:][a-hkmp-tw-zA-HKMP-TW-Z][!@%^&*():;{}\[\]\\/?<>,.]'; export PASSWORD_STORE_CHARACTER_SET
PASSWORD_STORE_SIGNING_KEY="36AC272EB7CFEDD5F907E488B6193EC73CF07AA7"; export PASSWORD_STORE_CHARACTER_SET
# if running bash
if [ -n "$BASH_VERSION" ]; then
    # include .bashrc if it exists
    if [ -f "$HOME/.bashrc" ]; then
        . "$HOME/.bashrc"
    fi
fi

# # set PATH so it includes user's private bin if it exists
# if [ -d "$HOME/bin" ] ; then
#     PATH="$HOME/bin:$PATH"
# fi
