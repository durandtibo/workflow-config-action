# CLAUDE.md

Guidance for coding agents working in this repository.

## Repository purpose

A GitHub composite action (`action.yml`) that exposes shared workflow configuration (Python
versions, OS runner labels) as job outputs. The default config lives in `configs/versions.json`;
consumers can override it with the `config` input. The logic is inline in the `load` step of
`action.yml` (bash and `jq`). There is no separate script. The action is tested by workflows in
CI (`ci-action.yaml`, `nightly-test-released.yaml`) using the fixtures in `tests/fixtures/`.

## Environment

- Use the `Makefile`; run `make help` to list targets.
- Do not edit `.make/`: it is a shared directory synced by `bot-sync-shared-makefile.yaml`.
- Run `make format` and `make lint` before committing. Fix what they report instead of disabling
  rules.
- The action cannot be run end to end locally. Check `jq` filters by hand against the files in
  `configs/` and `tests/fixtures/`, and say in the PR which workflows could not be run locally
  instead of claiming they pass.

## Git workflow

- One branch and one PR per logical change, branched from an up-to-date `main`. Never commit or
  push to `main`.
- Name branches `<type>/<short-description>` in kebab-case, with type one of: `feat`, `bugfix`,
  `hotfix`, `docs`, `refactor`, `perf`, `test`, `chore`, `ci`.
- PR descriptions cover what changed, what was deliberately left alone, and any behaviour change.
- On conflicts with `main`, merge `origin/main` into the branch; do not rebase and force-push.
- Update `README.md` when inputs, outputs, config keys, behaviour, or workflows change.

## Action rules (`action.yml`)

- Keep input and output names, defaults, and descriptions consistent with `README.md`. Renaming
  or removing an input or output is a breaking change and must be flagged.
- Adding a config key means updating `configs/versions.json`, the `outputs:` block, the
  `emit_sorted` calls in the `load` step, `README.md`, and the tests.
- Derived outputs (`python_versions`, `os_unix`, `os_all`) are computed in `action.yml`, never
  stored in the config file.
- List outputs are sorted and default to an empty array when the key is absent.
- Pass inputs to the script through `env:`, never by interpolating `${{ inputs.* }}` in `run:`.
- Every `run:` step sets `shell: bash`.
- Fail early with a clear `::error::` message (missing config file, unknown key).
- Pin third-party actions in workflows to commit SHAs with a `# ratchet:<owner>/<repo>@<tag>`
  comment, never to tags or branches.
- Workflows use least-privilege `permissions` and set `timeout-minutes` on jobs.

## Workflow structure (`.github/workflows/`)

Files are prefixed by role:

- `ci.yaml`: entry point for pull requests, pushes to `main`, a nightly schedule and manual runs.
  It holds no steps, only jobs that call the reusable `ci-*.yaml` workflows below.
  - `lib-get-test-matrix.yaml`: loads the OS and Python lists from the latest released action
    once, and passes them to the jobs that need them.
  - `ci-format.yaml`: runs the `make lint-*` targets.
  - `ci-action.yaml`: runs the action from this checkout (`uses: ./`), i.e. the version not
    released yet, against the default config, overrides, the `key` input, and error paths.
- `nightly.yaml`: nightly entry point. It calls `nightly-test-released.yaml`, which runs the
  latest released action with the same tests as `ci-action.yaml`.
- `ci-verify-workflows.yaml`: lints the workflow files themselves. It has its own triggers and is
  not called from `ci.yaml`, so it can be a required check.
- `example.yml`: example usage of the action for consumers.
- `bot-*.yaml`: scheduled automation that opens PRs or acts on runs (format files, pin actions,
  sync `.make/`, cancel stale runs).
- `security-*.yaml`: dependency review and OSSF Scorecard.

Conventions:

- Set `permissions` on every job (including jobs that call a reusable workflow). Every workflow
  has `permissions: {}` at the workflow level (it grants nothing), never a grant.
- Each `ci-*` check is a `workflow_call` workflow. When it needs no input it also has
  `workflow_dispatch`, so it can be run alone. The test workflows take the `test-matrix` input
  from `lib-get-test-matrix.yaml`, so they only run through their caller. Add a new check as a
  new `ci-<name>.yaml` plus a job in `ci.yaml`.
- Put `make` targets in the steps rather than duplicating commands, so local runs and CI match.
- Start each file with a comment saying what it does, and update it when the behaviour changes.

## Tests

- Test cases are jobs in `ci-action.yaml`, mirrored in `nightly-test-released.yaml`, with inputs
  in `tests/fixtures/`.
- One behaviour per step; assert on the exact output value.
- Cover success, failure, and edge cases (missing keys, partial configs, unsorted lists, unknown
  key, missing file).
- Every bug fix needs a regression test that fails without the fix.
- If a check fails for a real reason, report it rather than weakening the test.

## Reporting

- State which checks ran (`make lint`, `make format`) and which did not.
- Note that CI was not awaited.
- Report failures that already exist on `main` rather than hiding them.
