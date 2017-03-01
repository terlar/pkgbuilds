.DEFAULT_GOAL := help

REPO ?= custom

comma:= ,
empty:=
space:= $(empty) $(empty)

ifdef PKGS
PKGFILTER := $(addsuffix /%,$(subst $(comma),$(space),$(PKGS)))
PKGBUILDS := $(sort $(filter $(PKGFILTER),$(wildcard */PKGBUILD)))
else
PKGBUILDS := $(sort $(wildcard */PKGBUILD))
endif
QUEUE     := tmp/queue
BUILDDIR  := tmp/build
TARGETS   := $(addprefix $(BUILDDIR)/,$(PKGBUILDS))

$(BUILDDIR)/%/PKGBUILD: %/PKGBUILD
	@mkdir -p $(BUILDDIR)
	cp -R $(+D) $(BUILDDIR)

$(QUEUE): $(TARGETS)
	@mkdir -p $(@D)
	printf '%s\n' $(+D) > $@

.PHONY: build
build: ## Build PKGBUILDS and add to REPO
build: $(QUEUE)
	aurbuild -c -d $(REPO) -a $(QUEUE)

.PHONY: clean
clean: ## Remove build artifacts
ifneq ("$(wildcard $(QUEUE))","")
	rm $(QUEUE)
endif
ifneq ("$(wildcard $(BUILDDIR))","")
	rm -rf $(BUILDDIR)
endif

.PHONY: help
help: ## Describe tasks
	$(info Tasks:)
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)
