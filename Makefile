SHELL = /bin/bash

include .make/all.mk

.PHONY: all
all: format lint ## Format and lint everything

.PHONY: test
test: ## No local tests: the action is tested by the CI workflows
	@echo "The action cannot be run locally. Tests run in CI (ci-action.yaml)."

.PHONY: clean
clean: ## Nothing to clean: the repository has no build artifacts
	@echo "Nothing to clean."
