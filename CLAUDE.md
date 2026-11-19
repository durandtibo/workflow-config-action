# CLAUDE.md

Guidance for coding agents working in this repository.

## Repository purpose

A GitHub composite action (`action.yaml`) that exposes shared workflow configuration (Python
versions, OS runner labels) as job outputs. The default config lives in `configs/versions.json`;
consumers can override it with the `config` input. The logic is inline in the `load` step of
`action.yaml` (bash and `jq`). There is no separate script, so there is no code level test: the
action is tested by the reusable `ci-action.yaml` workflow, with the cases of `tests/cases.json`
and the fixtures in `tests/fixtures/`. The action runs on Linux and macOS runners; Windows is not
supported and not tested.

This repository is also the source of the OS and Python lists that the other action repositories
of `durandtibo` use in their tests, through `lib-get-test-matrix.yaml`. Keep the keys of that
matrix stable (see "Testing strategy").

`dev/` holds maintainer helpers (`check_action_case.sh`, `check_cases.sh`, `check_export.sh`,
`check_readme.sh`), not part of the action.

## Environment

- Use the `Makefile`; run `make help` to list targets.
- Do not edit `.make/`: it is a shared directory synced by `bot-sync-shared-makefile.yaml`.
- Run `make format` and `make lint` before committing. Fix what they report instead of disabling
  rules.
- Run `make test` (`make check-export`, `make check-cases` and `make check-readme`) for the checks
  that run on a laptop.
- The action cannot be run end to end locally. Check `jq` filters by hand against the files in
  `configs/` and `tests/fixtures/`, and say in the PR which workflows could not be run locally
  instead of claiming they pass.

## Git workflow

- One branch and one PR per logical change, branched from an up-to-date `main`. Never commit or
  push to `main`.
- Name branches `<type>/<short-description>` in kebab-case, with type one of: `feat`, `bugfix`,
  `hotfix`, `docs`, `refactor`, `perf`, `test`, `chore`, `ci`.
- Write commit messages and PR titles as a short imperative sentence starting with a verb such as
  `Add`, `Fix`, `Update`, `Remove` or `Improve`. Do not use conventional-commit prefixes like
  `docs:` or `feat:` (the type prefix is only for branch names). The squash-merge appends the PR
  number, so do not add one.
- PR descriptions cover what changed, what was deliberately left alone, and any behaviour change.
- Do not escape special characters such as the backtick (`` ` ``) in PR titles and descriptions
  (no `\``): the escape characters are not rendered well. Write them as plain Markdown.
- On conflicts with `main`, merge `origin/main` into the branch; do not rebase and force-push.
- Update `README.md` when inputs, outputs, config keys, behaviour, or workflows change.
- Releases are immutable exact version tags (`v0.3.0`, ...). Do not create or move floating tags
  (`v0`, `latest`) and do not document them as an option. After a release, update the pinned
  version in `ci-action.yaml`, `lib-get-test-matrix.yaml` and the `README.md` examples, and set
  `"released": true` on the rows of `tests/cases.json` that the release supports.

## Action rules (`action.yaml`)

- Keep input and output names, defaults, and descriptions consistent with `README.md`. Renaming
  or removing an input or output is a breaking change and must be flagged.
- Adding a config key means updating `configs/versions.json`, the `outputs:` block, the
  `emit_sorted` calls in the `load` step, `README.md`, `dev/check_action_case.sh` and the cases of
  `tests/cases.json`.
- Derived outputs (`python_versions`, `os_unix`, `os_all`) are computed in `action.yaml`, never
  stored in the config file.
- List outputs are sorted and default to an empty array when the key is absent.
- Pass inputs to the script through `env:`, never by interpolating `${{ inputs.* }}` in `run:`.
- Every `run:` step sets `shell: bash`.
- Fail early with a clear `::error::` message (missing config file, unknown key).
- Pin third-party actions in workflows to commit SHAs with a `# ratchet:<owner>/<repo>@<tag>`
  comment, never to tags or branches.
- Workflows use least-privilege `permissions` and set `timeout-minutes` on jobs.
- Only ship what the action needs at runtime: files the action itself uses (`action.yaml`,
  `LICENSE`, `configs/versions.json`) are exported, and `.gitattributes` marks everything else
  `export-ignore`. When the action starts using a new file, un-ignore it there and add it to
  `EXPECTED` in `dev/check_export.sh`. Never make the action read tests, fixtures or other repo
  files that are not exported. Test inputs belong in `tests/fixtures/` and are passed through the
  `config` input from the consumer workspace. Check the exported set with `make check-export`
  (`git archive --worktree-attributes HEAD | tar t`).

## Shell rules (`load` step and `dev/`)

- Quote all variables; validate inputs early with clear `::error::` messages.
- The `dev/` scripts pass `shellcheck` and `shfmt` via `make lint` / `make format`.
- The `load` step must keep working with the bash and `jq` of the Linux and macOS runners (no GNU
  only option).
- Check a `jq` filter on the files of `configs/` and `tests/fixtures/` before changing it.

## Workflow structure (`.github/workflows/`)

Files are prefixed by role:

- `ci.yaml`: entry point for pull requests, pushes to `main`, a nightly schedule and manual runs.
  It holds no steps, only jobs that call the reusable `ci-*.yaml` workflows below.
  - `lib-get-test-matrix.yaml`: loads the OS and Python lists from the latest released action
    once, and passes them to the jobs that need them.
  - `ci-format.yaml`: runs `make format` and fails on a diff, then `make lint` (Markdown, shell,
    YAML, Makefile and workflow files).
  - `ci-export.yaml`: checks the exported set (`make check-export`, `dev/check_export.sh`), the
    shape of the cases (`make check-cases`, `dev/check_cases.sh`) and the README inputs and
    outputs against `action.yaml` (`make check-readme`, `dev/check_readme.sh`).
  - `ci-action.yaml`: runs the action from this checkout (`uses: ./`), i.e. the version not
    released yet, against the default config, overrides, the `key` input, and error paths. With
    the input `use-released: true` it runs the latest released action instead.
- `nightly.yaml`: nightly entry point. It calls `ci-action.yaml` with `use-released: true`, which
  tests the latest released action with the same cases. It is not part of `ci.yaml`.
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
  `workflow_dispatch`, so it can be run alone. `ci-action.yaml` takes the `test-matrix` input
  from `lib-get-test-matrix.yaml` (and has its own `get-matrix` job on `workflow_dispatch`).
  Add a new check as a new `ci-<name>.yaml` plus a job in `ci.yaml`.
- Put `make` targets in the steps rather than duplicating commands, so local runs and CI match.
- Start each file with a comment saying what it does, and update it when the behaviour changes.

## Tests

- Test cases are the rows of `tests/cases.json`, with inputs in `tests/fixtures/`. A new case is
  a new row, not a new job. `dev/check_action_case.sh` asserts one case and is shared by the local
  and the released runs.
- One behaviour per row; assert on the exact output value, or on its format and invariants.
- Cover success, failure, and edge cases (missing keys, partial configs, unsorted lists, unknown
  key, missing file).
- Every bug fix needs a regression test that fails without the fix.
- If a check fails for a real reason, report it rather than weakening the test.

## Testing strategy

The strategy is the same for all the action repositories of `durandtibo`; the reference is
`review/testing.md` of `durandtibo/cancel-queued-runs-action` (properties T1 to T16). This
repository follows it.

Three levels:

1. **Code**: each script or function, tested alone with mocks. This action has no code outside
   `action.yaml`, so this level is empty. The `make` checks of `dev/` (`check-export`,
   `check-cases`, `check-readme`) are the only checks that run without GitHub.
2. **Local action**: the action from this checkout (`uses: ./`) in a real workflow.
3. **Released action**: the latest stable release (`uses: durandtibo/workflow-config-action@<sha>`),
   run nightly with the same cases as level 2. Never run it on pull requests.

Rules:

- The action tests (levels 2 and 3) are the only tests of the logic, because the logic is inline.
  Test each behaviour once, on the cheapest runner set that can show it.
- Split the action tests in two. **General behaviour** (`test`: the default config) runs on the
  full matrix: `os_matrix` (the Linux and macOS runners of the default config). This action does
  not depend on Python, so there is no Python dimension. **Edge cases** (`test-cases`: one
  override, one `key`, one invalid value, one unusual file) run on `os_latest` (`ubuntu-latest`
  and `macos-latest`), because `jq`, `sort` and bash differ between Linux and macOS. There is no
  reduced matrix on pull requests: the same matrix runs on pull requests, pushes and the schedule.
- Never write an OS or a Python version in a workflow: read the lists from
  `durandtibo/workflow-config-action` through `lib-get-test-matrix.yaml`. The file exposes the
  same keys as in the other repositories: `os_matrix` (Linux and macOS), `os_macos`, `os_latest`,
  `python_versions`, `python_versions_standard`. Do not rename or remove a key: the other
  repositories copy the file. Windows is added only if the README starts to claim it.
- Layout: one reusable `ci-action.yaml` with a boolean input `use-released`. `ci.yaml` calls it
  with `false`, `nightly.yaml` with `true`. Each job has two action steps, `uses: ./` with
  `if: ${{ !inputs.use-released }}` and the pinned release with `if: ${{ inputs.use-released }}`,
  and one verify step reading `steps.local.outputs.x || steps.released.outputs.x`. There is no
  `nightly-test-released.yaml`.
- Count the jobs per run and keep the count in the `README.md` "Testing" section (currently 31 for
  `ci.yaml` and 33 for `nightly.yaml`). Update it when a case, a job or the matrix lists change.
- Put the cases in `tests/cases.json`. A row has `"released": false` until the last release has the
  feature; the released run skips those rows.
- The default config of the released action can differ from the working tree. Check its outputs
  against the `config` output of the action itself; compare with `configs/versions.json` only for
  the local action (`BUNDLED_CONFIG`).
- Every input has a case that sets it and asserts its effect: `config` (override, partial, missing
  keys) and `key` (scalar, array, unknown). A case with an invalid value (missing file, unknown
  key) asserts that the action failed. Assert the value or the format of outputs, never just
  print them.
- Failure paths use `continue-on-error: true`, an `id`, and a verify step that asserts the
  `outcome`. Assert the outcome and which outputs are unset, not a message. A negative test needs
  a positive run on the same runner before it, so it cannot pass for the wrong reason.
- Tests have no side effects outside the runner: the action only reads files. If something cannot
  be tested in CI, write down which check covers it.
- Check what is shipped: the exported set (`make check-export`) must contain every file the
  action needs, because `uses: ./` runs the whole checkout and hides a missing file. The released
  run has `test-downloaded-files`, which checks the files the runner downloaded.
- Set `timeout-minutes` and `fail-fast: false` on matrix jobs. Put assertions shared by the local
  and released runs in one script (`dev/check_action_case.sh`), not in two workflows.
- Keep the README inputs and outputs in step with `action.yaml`: `make check-readme`
  (`dev/check_readme.sh`) compares the names of the tables with the `inputs:` and `outputs:` blocks
  and the empty defaults, and runs in `ci-export.yaml`.

## Reporting

- State which checks ran (`make lint`, `make format`, `make test`) and which did not.
- Note that CI was not awaited.
- Report failures that already exist on `main` rather than hiding them.
