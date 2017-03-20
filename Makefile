.DEFAULT_GOAL := help

REPOS := $(notdir $(subst /Makefile,,$(wildcard */Makefile)))

GPG_KEYS := \
A703C1328EABC7B201753BA3919464515CCF8BB3 \
487EACC08557AD082088DABA1EB2638FF56C0C53

comma := ,
empty :=
space := $(empty) $(empty)

.PHONY: build
build: ## Build repo PKGBUILDS

.PHONY: clean
clean: ## Remove build artifacts

build clean:
	@for i in $(subst $(comma),$(space),$(REPOS)); do \
		echo "--- Invoking source/$$i/Makefile ..."; \
		$(MAKE) --no-print-directory -C "$$i" $@; \
	done

.PHONY: add-gpg-keys
add-gpg-keys:
	gpg --recv-key $(GPG_KEYS)

.PHONY: update
update: ## Pull latest git commit
	git pull

.PHONY: help
help: ## Describe tasks
	$(info Tasks:)
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)
