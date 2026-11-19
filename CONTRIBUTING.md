# Contributing to workflow-config-action

Thank you for your interest in contributing to this project! We welcome contributions from the
community.

## How to Contribute

### Reporting Issues

If you encounter a bug or have a feature request:

1. Check the [existing issues](https://github.com/durandtibo/workflow-config-action/issues)
   to see if it has already been reported
2. If not, create a new issue using the bug report or feature request template
3. Include any relevant information:
   - Steps to reproduce (for bugs), with your workflow and config file
   - Expected behavior
   - Actual behavior
   - The action version and the runner OS

To report a security vulnerability, follow [SECURITY.md](SECURITY.md) instead of opening an issue.

### Submitting Changes

1. **Fork the repository** and create a branch from an up-to-date `main`. Name it
   `<type>/<short-description>` in kebab-case, where type is one of `feat`, `bugfix`, `hotfix`,
   `docs`, `refactor`, `perf`, `test`, `chore`, `ci`
2. **Make your changes**:
   - Follow the existing code style
   - Add or update tests (see [Tests](#tests))
   - Update documentation as needed
3. **Check your changes**:
   - Run `make format` and `make lint`, and fix what they report instead of disabling rules
   - The action cannot be run end to end locally, so check the `jq` filters by hand against the
     files in `configs/` and `tests/fixtures/`
4. **Commit your changes**:
   - Use clear and descriptive commit messages
   - Reference any related issues
5. **Submit a pull request**:
   - Describe what changed, what was deliberately left alone, and any behavior change
   - Say which workflows could not be run locally
   - Link to any related issues
   - Ensure CI checks pass

One branch and one pull request per logical change. If your branch conflicts with `main`, merge
`origin/main` into it instead of rebasing and force-pushing.

## Development Setup

### Prerequisites

- `make`
- `jq` and `bash`
- The linters and formatters used by the `Makefile`. Run `make check-tools` to see which are
  missing and `make install-tools` to install them

Run `make help` to list all the targets.

The `.make/` directory is synced from a shared repository by `bot-sync-shared-makefile.yaml`, so
do not edit it.

### Repository Layout

- `action.yaml`: the composite action. The logic is inline in the `load` step (bash and `jq`)
- `configs/versions.json`: the default configuration
- `tests/cases.json` and `tests/fixtures/`: the test cases and their inputs
- `dev/`: maintainer helpers used by the tests and the CI (not shipped)
- `.github/workflows/`: the CI, nightly, bot and security workflows

### Tests

The action is tested by GitHub workflows, not by local tests:

- Test cases are the rows of `tests/cases.json` (inputs in `tests/fixtures/`), run by
  `.github/workflows/ci-action.yaml` on the checkout and, with `use-released: true`, on the latest
  release by `nightly.yaml`. A new case is a new row, not a new job
- `dev/check_action_case.sh` asserts one case, so the local and the released runs check the same
  thing. Assert on the exact output value
- Cover success, failure, and edge cases (missing keys, partial configs, unsorted lists, unknown
  key, missing file)
- Every bug fix needs a regression test that fails without the fix
- Run `make test` for the checks that run locally (`make check-export` and `make check-cases`)

## Code Style

- Pass inputs to the script through `env:`, never by interpolating `${{ inputs.* }}` in `run:`
- Every `run:` step sets `shell: bash`
- Fail early with a clear `::error::` message
- Pin third-party actions in workflows to commit SHAs with a `# ratchet:<owner>/<repo>@<tag>`
  comment
- Use least-privilege `permissions` and set `timeout-minutes` on jobs
- Start each workflow file with a comment saying what it does

## Documentation

When making changes, please update [README.md](README.md) if inputs, outputs, config keys,
behavior, or workflows change. Renaming or removing an input or output is a breaking change and
must be flagged in the pull request.

## Code of Conduct

This project follows the [Contributor Covenant Code of Conduct](CODE_OF_CONDUCT.md). By
participating, you are expected to uphold this code.

## Questions?

If you have questions, feel free to open an issue for discussion.

Thank you for contributing! 🎉
