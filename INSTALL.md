

## INSTALLATION INSTRUCTIONS

```
sudo apt-get install build-essential git
git clone https://github.com/seamustuohy/dotfiles.git
cd dotfiles
make all # This will give .gpg.conf errors, don't worry you just don't have your keys in the repo
sudo install.sh first_boot
install.sh emacs
# Anything else you want
```