.DEFAULT_GOAL := help

MACHINE := $(shell uname -m)
CHROOT  := /var/cache/pkgs/chroot-$(MACHINE)

REPOS := $(notdir $(subst /Makefile,,$(wildcard */Makefile)))

GPG_KEYS := \
A703C1328EABC7B201753BA3919464515CCF8BB3 \
487EACC08557AD082088DABA1EB2638FF56C0C53 \
79BE3E4300411886 \
38DBBDC86092693

comma := ,
empty :=
space := $(empty) $(empty)

.PHONY: repo
repo:
	sudo arch-nspawn \
	  $(CHROOT)/root pacman -Syyu --noconfirm

.PHONY: add-gpg-keys
add-gpg-keys: ## Add required GPG keys
	gpg --recv-key $(GPG_KEYS)

.PHONY: update
update: ## Pull latest git commit
	git pull

.PHONY: build
build: ## Build repo PKGBUILDS
build: repo

.PHONY: clean
clean: ## Remove build artifacts

build clean:
	@for i in $(subst $(comma),$(space),$(REPOS)); do \
		echo "--- Invoking source/$$i/Makefile ..."; \
		$(MAKE) --no-print-directory -C "$$i" $@; \
	done

.PHONY: new-pkg
new-pkg: ## Initialize a new package

.PHONY: update-pkg
update-pkg: ## Update an existing package

new-pkg update-pkg:
ifndef REPO
	$(error REPO required)
endif
	$(info --- Invoking source/$(REPO)/Makefile ...)
	@$(MAKE) --no-print-directory -C $(REPO) $@

.PHONY: help
help: ## Describe tasks
	$(info Tasks:)
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)
