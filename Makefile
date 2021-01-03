.PHONY: bin dotfiles src rss fonts

all: bin dotfiles src

bin:
	# Move Binary Files to /usr/local/bin
	for file in $(shell find $(CURDIR)/bin/ -type f); do \
		f=$$(basename $$file); \
		sudo ln -sf $$file /usr/local/bin/$$f; \
	done
	for file in $(shell find $(CURDIR)/private/bin/ -type f); do \
		f=$$(basename $$file); \
		sudo ln -sf $$file /usr/local/bin/$$f; \
	done
src:
	# Move src Files to /usr/local/src
	for file in $(shell find $(CURDIR)/src/ ! -path $(CURDIR)/src/ ); do \
		f=$$(basename $$file); \
		sudo ln -sf $$file /usr/local/src/$$f; \
	done

dotfiles: rss fonts
	# add aliases for dotfiles
	for file in $(shell find $(CURDIR)/config/  -maxdepth 1 \
						    -name ".*" \
						    -not -name ".gnupg" \
						    -not -name ".fonts" \
                                  ); do \
		f=$$(basename $$file); \
		ln -sfn $$file $(HOME)/$$f; \
	done; \
	# GPG
	ln -sfn $(CURDIR)/config/.gnupg/gpg.conf $(HOME)/.gnupg/gpg.conf;
	ln -sfn $(CURDIR)/config/.gnupg/gpg-agent.conf $(HOME)/.gnupg/gpg-agent.conf;
rss:
	# RSS
	mkdir -p $(HOME)/.newsboat
	ln -sfn $(CURDIR)/config/.newsboat.conf $(HOME)/.newsboat/config

fonts:
	# FONTS
	mkdir -p $(XDG_CONFIG_HOME)/fonts/truetype/
	mkdir -p $(HOME)/.local/share/fonts/truetype/
	mkdir -p $(XDG_CONFIG_HOME)/fontconfig
	for font in $(shell find $(CURDIR)/config/fonts/ -maxdepth 1 ! -path $(CURDIR)/config/fonts/ -type d -name "*" ); do \
		f=$$(basename $$font); \
		ln -sfn $$font $(XDG_CONFIG_HOME)/fonts/truetype/$$f; \
	ln -sfn $$font $(HOME)/.local/share/fonts/truetype/$$f; \
	done;
	ln -sfn $(CURDIR)/config/fonts/fonts.conf $(XDG_CONFIG_HOME)/fontconfig/fonts.conf
	fc-cache
