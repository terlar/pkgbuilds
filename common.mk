.DEFAULT_GOAL := build

REPO    := $(notdir $(CURDIR))
BASEDIR := $(dir $(abspath $(CURDIR)))
TMPDIR  := $(BASEDIR)tmp
MACHINE := $(shell uname -m)

BUILDQUEUE := $(BASEDIR)buildqueue

DESTDIR ?=
REPODIR ?= $(BASEDIR)pkgs

MAKEPKG_CONF := /usr/share/devtools/makepkg-$(MACHINE).conf
PACCONF      := $(TMPDIR)/pacman.conf
REPO_PACCONF := $(TMPDIR)/$(REPO).conf

comma := ,
empty :=
space := $(empty) $(empty)

ALL_PKGS  := $(subst /PKGBUILD,,$(wildcard */PKGBUILD))
SKIP_PKGS := $(subst $(comma),$(space),$(SKIP))

ifdef PKGS
PKGBUILDS := $(addsuffix /PKGBUILD,$(shell $(BUILDQUEUE) $(subst $(comma),$(space),$(PKGS))))
else
PKGBUILDS := $(addsuffix /PKGBUILD,$(shell $(BUILDQUEUE) $(filter-out $(SKIP_PKGS),$(ALL_PKGS))))
endif

CHROOT   := $(TMPDIR)/chroot
BUILDDIR := $(TMPDIR)/build/$(REPO)
TARGETS  := $(addprefix $(BUILDDIR)/,$(PKGBUILDS))

$(PACCONF):
	@mkdir -p $(@D)
	pacconf --raw > $@

$(REPO_PACCONF):
	echo "[options]" > $@
	pacconf --options --raw >> $@
	echo "[$(REPO)]" >> $@
	pacconf --repo=$(REPO) --raw >> $@

$(CHROOT): $(PACCONF)
	mkdir -p $@
	sudo mkarchroot \
	  -C $(PACCONF) -M $(MAKEPKG_CONF) \
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
          -C $(PACCONF) -M $(MAKEPKG_CONF) \
          $(CHROOT)/root pacman -Syyu --noconfirm
	mkdir -p $(DESTDIR)$(REPODIR)/$(REPO)

.PHONY:	refresh
refresh: $(REPO_PACCONF)
	sudo pacman -Fy --config=$(REPO_PACCONF)
	sudo pacman -Sy --config=$(REPO_PACCONF)

.PHONY: build
build: repo $(TARGETS) refresh

.PHONY: new-pkg
new-pkg:
ifndef PKG
	$(error PKG required)
endif
ifneq ("$(LOCAL)","1")
	cower -d $(PKG)
else
	mkdir $(PKG)
	touch $(PKG)/PKGBUILD
endif

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
ifneq ("$(wildcard $(TMPDIR)/pacman.conf)","")
	rm -rf $(TMPDIR)/pacman.conf
endif
