.DEFAULT_GOAL := build

BASEDIR := $(dir $(abspath $(CURDIR)))
MACHINE := $(shell uname -m)
CHROOT  := /var/cache/pkgs/chroot-$(MACHINE)
BUILDQUEUE := $(BASEDIR)buildqueue

DESTDIR ?= $(BASEDIR)pkgs

REPO := $(notdir $(CURDIR))

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

BUILDDIR     := .build
SOURCESDIR   := $(BUILDDIR)/sources
LOGSDIR      := $(BUILDDIR)/logs
PKGBUILDSDIR := $(BUILDDIR)/PKGBUILDs
TARGETS      := $(addprefix $(PKGBUILDSDIR)/,$(PKGBUILDS))
GIT_TARGETS  := $(filter %-git/PKGBUILD,$(TARGETS))

$(PKGBUILDSDIR)/%/PKGBUILD: %/PKGBUILD
	@mkdir -p $(PKGBUILDSDIR)
	cp -R $(+D) $(PKGBUILDSDIR)

	@mkdir -p $(DESTDIR)/$(REPO)/os/$(MACHINE)
	@mkdir -p $(SOURCESDIR) $(LOGSDIR)

ifdef INIT
	guzuta build $(@D) \
	  --repo-name $(REPO) \
	  --arch $(MACHINE) \
	  --chroot-dir $(CHROOT) \
	  --repo-dir $(DESTDIR)/$(REPO)/os/$(MACHINE) \
	  --srcdest $(SOURCESDIR) --logdest $(LOGSDIR)

	aws s3 sync $(DESTDIR)/$(REPO) s3://yak-packages/$(REPO)
else
	cp .guzuta.yml $(BUILDDIR)
	cd $(BUILDDIR) && \
	  guzuta omakase build $(notdir $(@D))
endif

.PHONY: build
build: clean-git $(TARGETS)

.PHONY: update-pkg
update-pkg:
ifndef PKG
	$(error PKG required)
endif
	cower -df $(PKG)

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

.PHONY: clean-git
clean-git: ## Clean git based packages
ifneq ("$(GIT_TARGETS)","")
	@-rm $(GIT_TARGETS) ||:
endif

.PHONY: clean
clean: ## Remove build artifacts
ifneq ("$(wildcard $(BUILDDIR))","")
	rm -rf $(BUILDDIR)
endif
