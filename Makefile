.PHONY: bin dotfiles src etc

all: bin dotfiles src etc

bin:
	# Move Binary Files to /usr/local/bin
	for file in $(shell find $(CURDIR)/bin); do \
		f=$$(basename $$file); \
		sudo ln -sf $$file /usr/local/bin/$$f; \
	done

src:
	# Move src Files to /usr/local/src
	for file in $(shell find $(CURDIR)/src); do \
		f=$$(basename $$file); \
		sudo ln -sf $$file /usr/local/src/$$f; \
	done

dotfiles:
	# add aliases for dotfiles
	for file in $(shell find $(CURDIR) -name ".*" -not -name ".gitignore" -not -name ".git" -not -name ".gnupg"); do \
		f=$$(basename $$file); \
		ln -sfn $$file $(HOME)/$$f; \
	done; \
	ln -sfn $(CURDIR)/.gnupg/gpg.conf $(HOME)/.gnupg/gpg.conf;
	ln -sfn $(CURDIR)/.gnupg/gpg-agent.conf $(HOME)/.gnupg/gpg-agent.conf;
	#ln -fn $(CURDIR)/gitignore $(HOME)/.gitignore;
	#ln -fn $(CURDIR)/gitignore /usr/local/src/.gitignore;

etc:
	sudo mkdir -p /etc/docker/seccomp
	sudo chmod 755 /etc/docker
	for file in $(shell find $(CURDIR)/etc -type f -not -name ".*.swp"); do \
		f=$$(echo $$file | sed -e 's|$(CURDIR)||'); \
		d=$$(dirname $$f); \
		sudo mkdir -p $$d; \
		sudo ln -f $$file $$f; \
	done
	systemctl --user daemon-reload || true
	sudo systemctl daemon-reload
