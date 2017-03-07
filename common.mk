.DEFAULT_GOAL := build

REPO    := $(notdir $(CURDIR))
BASEDIR := $(dir $(abspath $(CURDIR)))
TMPDIR  := $(BASEDIR)tmp
MACHINE := $(shell uname -m)

BUILDQUEUE := $(BASEDIR)buildqueue

DESTDIR ?=
REPODIR ?= $(BASEDIR)pkgs

MAKEPKG_CONF := /usr/share/devtools/makepkg-$(MACHINE).conf
PACMAN_CONF  := $(TMPDIR)/pacman.conf

comma := ,
empty :=
space := $(empty) $(empty)

ifdef PKGS
PKGBUILDS := $(addsuffix /PKGBUILD,$(shell $(BUILDQUEUE) $(subst $(comma),$(space),$(PKGS))))
else
PKGBUILDS := $(addsuffix /PKGBUILD,$(shell $(BUILDQUEUE)))
endif

CHROOT   := $(TMPDIR)/chroot
BUILDDIR := $(TMPDIR)/build/$(REPO)
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

	cd $(@D) && \
	  sudo PKGDEST=$(DESTDIR)$(REPODIR)/$(REPO) makechrootpkg \
	    -d $(DESTDIR)$(REPODIR)/$(REPO) -r $(CHROOT) -cnu

	LANG=C repose -r $(DESTDIR)$(REPODIR)/$(REPO) -zfv $(REPO)

.PHONY: repo
repo: $(CHROOT)
	sudo arch-nspawn \
          -C $(PACMAN_CONF) -M $(MAKEPKG_CONF) \
          $(CHROOT)/root pacman -Syyu --noconfirm
	mkdir -p $(DESTDIR)$(REPODIR)/$(REPO)

.PHONY:	refresh
refresh:
	sudo pacman -Sy
	sudo pacman -Fy

.PHONY: build
build: repo $(TARGETS) refresh

.PHONY: clean
clean: ## Remove build artifacts
ifneq ("$(wildcard $(QUEUE))","")
	rm $(QUEUE)
endif
ifneq ("$(wildcard $(BUILDDIR))","")
	rm -rf $(BUILDDIR)
endif
ifneq ("$(wildcard $(BASEDIR)/pkgs/$(REPO))","")
	rm -rf pkgs/$(REPO)
endif
