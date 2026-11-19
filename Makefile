SHELL = /bin/bash

include .make/all.mk

.PHONY: check-export
check-export: ## Check that the exported files are the files the action needs
	./dev/check_export.sh

.PHONY: check-cases
check-cases: ## Check that every case of tests/cases.json is well formed
	./dev/check_cases.sh

.PHONY: check-readme
check-readme: ## Check that the README inputs and outputs match action.yaml
	./dev/check_readme.sh

.PHONY: all
all: format lint check-export check-cases check-readme ## Format, lint and run the local checks

.PHONY: test
test: check-export check-cases check-readme ## Run the local checks (the action itself is tested by ci-action.yaml in CI)

.PHONY: clean
clean: ## Nothing to clean: the repository has no build artifacts
	@echo "Nothing to clean."
