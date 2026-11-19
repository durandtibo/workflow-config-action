# 🛠️ workflow-config-action

[![CI](https://github.com/durandtibo/workflow-config-action/actions/workflows/ci.yaml/badge.svg)](https://github.com/durandtibo/workflow-config-action/actions/workflows/ci.yaml)
[![Nightly](https://github.com/durandtibo/workflow-config-action/actions/workflows/nightly.yaml/badge.svg)](https://github.com/durandtibo/workflow-config-action/actions/workflows/nightly.yaml)
[![OpenSSF Scorecard](https://api.scorecard.dev/projects/github.com/durandtibo/workflow-config-action/badge)](https://scorecard.dev/viewer/?uri=github.com/durandtibo/workflow-config-action)
[![License](https://img.shields.io/badge/license-BSD--3--Clause-blue)](LICENSE)
[![Latest release](https://img.shields.io/github/v/tag/durandtibo/workflow-config-action?label=release)](https://github.com/durandtibo/workflow-config-action/tags)

A composite GitHub Action that exposes reusable workflow configuration
(Python versions, OS matrices, etc.) as job outputs, so multiple workflows
and repos can share a single source of truth instead of duplicating
hardcoded lists.

## ✨ Why

Keeping the same Python version list or OS matrix in sync across a dozen
workflow files (and repos) is tedious and error-prone. This action centralizes
that config in one JSON file and exposes it as ready-to-use, sorted JSON
arrays you can feed straight into a matrix strategy, with sane derived
unions like "all Python versions" or "all Unix OSes" computed for you.

## 📦 Config

By default the action uses the config bundled in this repo,
[`configs/versions.json`](configs/versions.json):

```json
{
  "python_versions_standard": ["3.11", "3.12", "3.13", "3.14", "3.15"],
  "python_versions_threaded": ["3.13t", "3.14t", "3.15t"],
  "os_ubuntu": [
    "ubuntu-latest",
    "ubuntu-slim",
    "ubuntu-22.04",
    "ubuntu-24.04",
    "..."
  ],
  "os_macos": ["macos-latest", "macos-15", "macos-26", "..."],
  "os_windows": ["windows-latest", "windows-2022", "windows-2025", "..."]
}
```

The `...` stands for more runner labels, see the file for the full lists.

The recognized keys are `python_versions_standard`, `python_versions_threaded`, `os_ubuntu`,
`os_macos` and `os_windows`. Each one is a JSON array and each one is optional. Any other key is
kept in the `config` output and can be read with the `key` input.

The derived outputs are not stored in the config file. They are computed in `action.yaml`, so the
lists never drift out of sync with their union:

| Derived output    | Computed as                                             |
| ----------------- | ------------------------------------------------------- |
| `python_versions` | `python_versions_standard` + `python_versions_threaded` |
| `os_unix`         | `os_ubuntu` + `os_macos`                                |
| `os_all`          | `os_ubuntu` + `os_macos` + `os_windows`                 |

`python_versions_standard` holds the regular CPython builds and `python_versions_threaded` holds
the free-threaded builds (`t` suffix).

The official list of GitHub-hosted runners (used for the `os_*` keys) is
available at
[docs.github.com/en/actions/reference/runners/github-hosted-runners](https://docs.github.com/en/actions/reference/runners/github-hosted-runners).

### ➕ Adding a config key

Adding a new key to the default config requires changes in several places:

1. Add the key to [`configs/versions.json`](configs/versions.json).
2. Add an entry to the `outputs:` block of [`action.yaml`](action.yaml).
3. Add an `emit_sorted` call in the `load` step of `action.yaml`.
4. Document it in the tables of this README.
5. Add or update the cases in `tests/cases.json` and the checks of `dev/check_action_case.sh`.

### 🔀 Overriding the config in a consumer repo

Any repo using this action can override the defaults by checking out its own
config file and passing its path via the `config` input:

```yaml
steps:
  - uses: actions/checkout@v7
  - id: cfg
    uses: durandtibo/workflow-config-action@v0.3.1
    with:
      config: .github/workflow-config.json
```

The path is resolved relative to the calling repo's workspace, so the file
must exist in the consumer's own checkout (it does not need to check out
this action's repo). Leave `config` empty (the default) to use this action's
built-in `configs/versions.json`. An override file replaces the defaults entirely (it is not
merged with them), so keys it omits default to empty arrays.

## ⚙️ Inputs

| Name     | Description                                                                                   | Default                         |
| -------- | --------------------------------------------------------------------------------------------- | ------------------------------- |
| `config` | Path to a JSON config file to override the defaults, relative to the calling repo's workspace | _(empty, uses built-in config)_ |
| `key`    | Optional key to extract as the generic `value` output                                         | _(none)_                        |

The step fails early with an `::error::` message when the file given by `config` does not exist,
or when the `key` is not present in the config file.

## 📤 Outputs

Every array output is sorted alphabetically by the action, regardless of the
order the items are listed in the config file, so output order stays
consistent even if the config is overridden or edited out of order. If
`python_versions_standard`, `python_versions_threaded`, `os_ubuntu`,
`os_macos`, or `os_windows` is absent from the config file, the
corresponding output (and `python_versions`/`os_unix`/`os_all`, if all of
their inputs are absent) defaults to an empty array (`[]`) rather than
erroring.

| Name                       | Description                                                                                                                           |
| -------------------------- | ------------------------------------------------------------------------------------------------------------------------------------- |
| `config`                   | Full config file content as compact JSON (not sorted)                                                                                 |
| `python_versions`          | JSON array of all Python versions, sorted (derived: `python_versions_standard` + `python_versions_threaded`; `[]` if both are absent) |
| `python_versions_standard` | JSON array of standard (non-threaded) Python versions, sorted (`[]` if absent from the config)                                        |
| `python_versions_threaded` | JSON array of free-threaded Python versions, sorted (`[]` if absent from the config)                                                  |
| `os_unix`                  | JSON array of all Unix-based OS runner labels, sorted (derived: `os_ubuntu` + `os_macos`; `[]` if both are absent)                    |
| `os_all`                   | JSON array of all OS runner labels, sorted (derived: `os_ubuntu` + `os_macos` + `os_windows`; `[]` if all are absent)                 |
| `os_ubuntu`                | JSON array of Ubuntu OS runner labels, sorted (`[]` if absent from the config)                                                        |
| `os_macos`                 | JSON array of macOS runner labels, sorted (`[]` if absent from the config)                                                            |
| `os_windows`               | JSON array of Windows runner labels, sorted (`[]` if absent from the config)                                                          |
| `value`                    | Value of the `key` input, as compact JSON (sorted if it's an array); the step fails if the key is missing                             |

## 🚀 Usage

The action does not need a checkout to use its built-in config. A checkout is only needed when
you pass your own file with `config`.

```yaml
jobs:
  config:
    runs-on: ubuntu-latest
    outputs:
      python_versions: ${{ steps.cfg.outputs.python_versions }}
      os_ubuntu: ${{ steps.cfg.outputs.os_ubuntu }}
    steps:
      - id: cfg
        uses: durandtibo/workflow-config-action@v0.3.1

  test:
    needs: config
    strategy:
      matrix:
        python-version: ${{ fromJSON(needs.config.outputs.python_versions) }}
        os: ${{ fromJSON(needs.config.outputs.os_ubuntu) }}
    runs-on: ${{ matrix.os }}
    steps:
      - uses: actions/setup-python@v7
        with:
          python-version: ${{ matrix.python-version }}
```

Reading a single key with the `key` input:

```yaml
steps:
  - id: cfg
    uses: durandtibo/workflow-config-action@v0.3.1
    with:
      key: os_windows
  - run: echo '${{ steps.cfg.outputs.value }}'
```

See [`.github/workflows/example.yml`](.github/workflows/example.yml) for a
full working example.

## ✅ Testing

The logic is inline in [`action.yaml`](action.yaml) (bash and `jq`), so there is no code level
test: the action is tested by workflows in CI. The test cases are the rows of
[`tests/cases.json`](tests/cases.json), with inputs in [`tests/fixtures`](tests/fixtures). The
action is tested on Linux and macOS runners. Windows runners are not tested and not supported.

[`ci.yaml`](.github/workflows/ci.yaml) runs on every pull request, push to `main`, nightly
(09:10 UTC) and on manual dispatch. It holds no steps, only jobs that call reusable workflows:

- [`lib-get-test-matrix.yaml`](.github/workflows/lib-get-test-matrix.yaml): loads the OS and Python
  lists once from the latest released action, and passes them to the test jobs. It uses the
  released action so a broken change cannot take the test matrix down. It exposes `os_matrix`
  (Linux and macOS), `os_macos`, `os_latest`, `python_versions` and `python_versions_standard`.
- [`ci-format.yaml`](.github/workflows/ci-format.yaml): lints the Markdown and YAML files with
  the `make lint-*` targets.
- [`ci-export.yaml`](.github/workflows/ci-export.yaml): checks that the files shipped in a release
  (`git archive`) are the files the action needs (`make check-export`), and that the cases are
  well formed (`make check-cases`).
- [`ci-action.yaml`](.github/workflows/ci-action.yaml): exercises the action from the **current
  repository code** (`uses: ./`), so changes are validated before they are released.

[`nightly.yaml`](.github/workflows/nightly.yaml) runs every night (10:30 UTC) and on manual
dispatch. It calls the same `ci-action.yaml` with `use-released: true`, which runs the
**released** action (pinned to a release) with the same cases, to catch regressions in what
consumers actually pick up. Update the pinned release in `ci-action.yaml` when a new version is
released.

[`ci-verify-workflows.yaml`](.github/workflows/ci-verify-workflows.yaml) lints the workflow
files themselves. It has its own triggers and is not called from `ci.yaml`, so it can be a
required check.

`ci-action.yaml` has two groups of tests. Every check asserts on the exact output values or on
their format.

| Job                     | Runs on                                    | What it checks                                                                                                    |
| ----------------------- | ------------------------------------------ | ----------------------------------------------------------------------------------------------------------------- |
| `test`                  | every Linux and macOS runner (`os_matrix`) | The default config: outputs are sorted JSON arrays, match the `config` output, and the derived unions are correct |
| `test-cases`            | `ubuntu-latest` and `macos-latest`         | One row of `tests/cases.json` per job (below)                                                                     |
| `test-downloaded-files` | `ubuntu-latest` and `macos-latest`         | Released action only: only the runtime files were downloaded                                                      |

For the local action, `test` also compares the `config` output with `configs/versions.json`. The
released action bundles its own config, which can differ from the working tree.

| Case                        | What it checks                                                       |
| --------------------------- | -------------------------------------------------------------------- |
| `config-override`           | The `config` input replaces the defaults, and lists are sorted       |
| `partial-keys`              | Derived outputs equal the present side when the other side is absent |
| `missing-keys-fallback`     | Absent keys default to empty arrays                                  |
| `key-scalar`                | The `key` input returns a scalar value as is                         |
| `key-array-sorted`          | The `key` input returns an array value sorted                        |
| `key-not-in-the-known-keys` | The `key` input reads a key that is not one of the known keys        |
| `key-default-config`        | The `key` input works with the default config                        |
| `missing-config-file`       | A missing config file fails the step and sets no output              |
| `unknown-key`               | An unknown `key` fails the step and sets no `value`                  |

A case that expects a failure runs after a successful run of the action on the same runner, so it
cannot fail for the wrong reason. A new case is a new row in `tests/cases.json` (with
`"released": false` until the last release supports it), not a new job.

`ci-action.yaml` receives the test matrix as input, so through `ci.yaml` and `nightly.yaml` it
runs with the matrix they load. It can also be run by hand (`workflow_dispatch`), with the input
`use-released` to choose the version. The checks that run without GitHub are `make check-export`
and `make check-cases` (`make test`).

## 🤖 Automation and security

| Workflow                                                                                   | Purpose                                                 |
| ------------------------------------------------------------------------------------------ | ------------------------------------------------------- |
| [`bot-format-files.yaml`](.github/workflows/bot-format-files.yaml)                         | Weekly PR formatting the repository files               |
| [`bot-pin-action.yaml`](.github/workflows/bot-pin-action.yaml)                             | Weekly PR pinning actions to commit SHAs with `ratchet` |
| [`bot-sync-shared-makefile.yaml`](.github/workflows/bot-sync-shared-makefile.yaml)         | Weekly PR syncing the shared `.make/` directory         |
| [`bot-cancel-stale-queued-runs.yaml`](.github/workflows/bot-cancel-stale-queued-runs.yaml) | Hourly cancellation of stale queued runs                |
| [`security-dependency-review.yaml`](.github/workflows/security-dependency-review.yaml)     | Dependency review on pull requests                      |
| [`security-scorecard.yaml`](.github/workflows/security-scorecard.yaml)                     | OSSF Scorecard analysis                                 |

Third-party actions are pinned to commit SHAs, and workflows use least-privilege `permissions`.

## 🧑‍💻 Development

Use the `Makefile` (run `make help` to list the targets). Run `make format` and `make lint`
before committing. The `.make/` directory is synced from a shared repository, do not edit it.

See [`CLAUDE.md`](CLAUDE.md) for the contribution guidelines (branching, pull requests, action
rules), and the [Code of Conduct](CODE_OF_CONDUCT.md).

## 📄 License

Released under the license in [LICENSE](LICENSE).
