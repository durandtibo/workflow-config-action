# 🛠️ workflow-config-action

<p align="center">
    <a href="https://github.com/durandtibo/workflow-config-action/actions/workflows/ci.yaml">
        <img alt="CI" src="https://github.com/durandtibo/workflow-config-action/actions/workflows/ci.yaml/badge.svg">
    </a>
    <a href="https://github.com/durandtibo/workflow-config-action/actions/workflows/nightly.yaml">
        <img alt="Nightly Tests" src="https://github.com/durandtibo/workflow-config-action/actions/workflows/nightly.yaml/badge.svg">
    </a>
    <a href="https://github.com/durandtibo/workflow-config-action/actions/workflows/security-scorecard.yaml">
        <img alt="Scorecard" src="https://github.com/durandtibo/workflow-config-action/actions/workflows/security-scorecard.yaml/badge.svg">
    </a>
    <a href="https://github.com/durandtibo/workflow-config-action/blob/main/LICENSE">
        <img alt="License" src="https://img.shields.io/github/license/durandtibo/workflow-config-action">
    </a>
    <a href="https://github.com/durandtibo/workflow-config-action/releases">
        <img alt="Release" src="https://img.shields.io/github/v/release/durandtibo/workflow-config-action">
    </a>
</p>

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

The derived outputs are not stored in the config file. They are computed in `action.yml`, so the
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
2. Add an entry to the `outputs:` block of [`action.yml`](action.yml).
3. Add an `emit_sorted` call in the `load` step of `action.yml`.
4. Document it in the tables of this README.
5. Add or update the tests in `ci-action.yaml` and `nightly-test-released.yaml`.

### 🔀 Overriding the config in a consumer repo

Any repo using this action can override the defaults by checking out its own
config file and passing its path via the `config` input:

```yaml
steps:
  - uses: actions/checkout@v7
  - id: cfg
    uses: durandtibo/workflow-config-action@v0.3.0
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
        uses: durandtibo/workflow-config-action@v0.3.0

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
    uses: durandtibo/workflow-config-action@v0.3.0
    with:
      key: os_windows
  - run: echo '${{ steps.cfg.outputs.value }}'
```

See [`.github/workflows/example.yml`](.github/workflows/example.yml) for a
full working example.

## ✅ Testing

The action cannot be run end to end locally, so it is tested by workflows in CI. The test inputs
are in [`tests/fixtures`](tests/fixtures).

[`ci.yaml`](.github/workflows/ci.yaml) runs on every pull request, push to `main`, nightly
(09:10 UTC) and on manual dispatch. It holds no steps, only jobs that call reusable workflows:

- [`lib-get-test-matrix.yaml`](.github/workflows/lib-get-test-matrix.yaml): loads the Python
  versions and the OS list once from the latest released action, and passes them to the test
  jobs. It uses the released action so a broken change cannot take the test matrix down.
- [`ci-format.yaml`](.github/workflows/ci-format.yaml): lints the Markdown and YAML files with
  the `make lint-*` targets.
- [`ci-action.yaml`](.github/workflows/ci-action.yaml): exercises the action from the **current
  repository code** (`uses: ./`), so changes are validated before they are released.

[`nightly.yaml`](.github/workflows/nightly.yaml) runs every night (10:30 UTC) and on manual
dispatch. It calls
[`nightly-test-released.yaml`](.github/workflows/nightly-test-released.yaml), which runs the
**released** action (pinned to a release) with the same tests, to catch regressions in what
consumers actually pick up. Update the pinned release there when a new version is released.

[`ci-verify-workflows.yaml`](.github/workflows/ci-verify-workflows.yaml) lints the workflow
files themselves. It has its own triggers and is not called from `ci.yaml`, so it can be a
required check.

Both test workflows run the same suite, each case being a separate job asserting on the exact
output values:

| Job                     | What it checks                                                       |
| ----------------------- | -------------------------------------------------------------------- |
| `default-config`        | Outputs match the default config, and the derived unions are correct |
| `config-override`       | The `config` input replaces the defaults, and lists are sorted       |
| `key-scalar`            | The `key` input returns a scalar value as is                         |
| `key-array`             | The `key` input returns an array value sorted                        |
| `partial-keys`          | Derived outputs equal the present side when the other side is absent |
| `missing-keys-fallback` | Absent keys default to empty arrays                                  |
| `missing-config-file`   | A missing config file fails the step                                 |
| `unknown-key`           | An unknown `key` fails the step                                      |

`default-config` runs on every OS of the default config (`os_all`, with `fail-fast: false`) to
confirm the bash and `jq` logic behaves the same across runners. The other jobs run on the
`*-latest` runners only.

`ci-action.yaml` and `nightly-test-released.yaml` receive the test matrix as input, so they only
run through `ci.yaml` and `nightly.yaml`. The other workflows can also be triggered manually
(`workflow_dispatch`).

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
