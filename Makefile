.DEFAULT_GOAL := help

REPO    ?= custom
DESTDIR ?=
REPODIR ?= $(CURDIR)/pkgs/$(REPO)
MACHINE := $(shell uname -m)

MAKEPKG_CONF := /usr/share/devtools/makepkg-$(MACHINE).conf
PACMAN_CONF  := tmp/pacman.conf

comma := ,
empty :=
space := $(empty) $(empty)

ifdef PKGS
PKGFILTER := $(addsuffix /%,$(subst $(comma),$(space),$(PKGS)))
PKGBUILDS := $(filter $(PKGFILTER),$(wildcard */PKGBUILD))
else
PKGBUILDS := $(sort $(wildcard */PKGBUILD))
endif

CHROOT   := tmp/chroot
QUEUE    := tmp/queue
BUILDDIR := tmp/build
TARGETS  := $(addprefix $(BUILDDIR)/,$(PKGBUILDS))

$(PACMAN_CONF):
	pacconf --raw > $@

$(CHROOT): $(PACMAN_CONF)
	mkdir -p $@
	sudo mkarchroot \
	  -C $(PACMAN_CONF) -M $(MAKEPKG_CONF) \
	  $(CHROOT)/root base-devel

$(BUILDDIR)/%/PKGBUILD: %/PKGBUILD
	@mkdir -p $(BUILDDIR)
	cp -R $(+D) $(BUILDDIR)

$(QUEUE): $(TARGETS)
	@mkdir -p $(@D)
	printf '%s\n' $(+D) > $@

.PHONY: build
build: ## Build PKGBUILDS
build: $(QUEUE) $(CHROOT)
	sudo arch-nspawn \
          -C $(PACMAN_CONF) -M $(MAKEPKG_CONF) \
          $(CHROOT)/root pacman -Syyu --noconfirm

	mkdir -p $(DESTDIR)$(REPODIR)
	for pkg	in $$(cat $(QUEUE)); do \
	  cd $(CURDIR)/$$pkg; \
	  sudo PKGDEST=$(DESTDIR)$(REPODIR) makechrootpkg \
	    -d $(DESTDIR)$(REPODIR) -r $(CURDIR)/$(CHROOT) -cnu; \
	  LANG=C repose -r $(DESTDIR)$(REPODIR) -fv $(REPO) \
	done

.PHONY: update
update: ## Pull latest git commit
	git pull

.PHONY: clean
clean: ## Remove build artifacts
ifneq ("$(wildcard $(QUEUE))","")
	rm $(QUEUE)
endif
ifneq ("$(wildcard $(BUILDDIR))","")
	rm -rf $(BUILDDIR)
endif
ifneq ("$(wildcard $(CURDIR)/pkgs/$(REPO))","")
	rm -rf pkgs/$(REPO)
endif

.PHONY: help
help: ## Describe tasks
	$(info Tasks:)
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)
