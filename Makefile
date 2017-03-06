.DEFAULT_GOAL := help

REPOS := $(notdir $(subst /Makefile,,$(wildcard */Makefile)))

test:
	echo $(REPOS)

.PHONY: build
build: ## Build repo PKGBUILDS

.PHONY: clean
clean: ## Remove build artifacts

build clean:
	@for i in $(REPOS); do \
		echo "--- Invoking source/$$i/Makefile ..."; \
		$(MAKE) --no-print-directory -C "$$i" $@; \
	done


.PHONY: update
update: ## Pull latest git commit
	git pull

.PHONY: help
help: ## Describe tasks
	$(info Tasks:)
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)
