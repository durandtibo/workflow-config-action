# 🛠️ workflow-config-action

A composite GitHub Action that exposes reusable workflow configuration
(Python versions, OS matrices, etc.) as job outputs, so multiple workflows
and repos can share a single source of truth instead of duplicating
hardcoded lists.

## ✨ Why

Keeping the same Python version list or OS matrix in sync across a dozen
workflow files (and repos) is tedious and error-prone. This action centralizes
that config in one JSON file and exposes it as ready-to-use, sorted JSON
arrays you can feed straight into a matrix strategy — with sane derived
unions like "all Python versions" or "all Unix OSes" computed for you.

## 📦 Config

By default the action uses the config bundled in this repo,
[`configs/versions.json`](configs/versions.json):

```json
{
  "python_versions_standard": ["3.14", "3.13", "3.12", "3.11", "3.10"],
  "python_versions_threaded": ["3.14t", "3.13t"],
  "os_ubuntu": ["ubuntu-latest", "..."],
  "os_macos": ["macos-latest", "..."],
  "os_windows": ["windows-latest", "..."]
}
```

Add new keys there as needed, and expose them in [`action.yml`](action.yml)
outputs the same way `python_versions_standard` and `os_ubuntu` are.

`os_unix` is not stored in the config file — it's derived in `action.yml`
by concatenating `os_ubuntu` and `os_macos`, so the two lists never drift
out of sync with their union. `os_all` is derived the same way, adding
`os_windows` to the mix. `python_versions` is derived the same way too, by
concatenating `python_versions_standard` (regular CPython builds) and
`python_versions_threaded` (free-threaded, `t`-suffixed builds).

The official list of GitHub-hosted runners (used for the `os_*` keys) is
available at
[docs.github.com/en/actions/reference/runners/github-hosted-runners](https://docs.github.com/en/actions/reference/runners/github-hosted-runners).

### 🔀 Overriding the config in a consumer repo

Any repo using this action can override the defaults by checking out its own
config file and passing its path via the `config` input:

```yaml
steps:
  - uses: actions/checkout@v4
  - id: cfg
    uses: durandtibo/workflow-config-action@main
    with:
      config: .github/workflow-config.json
```

The path is resolved relative to the calling repo's workspace, so the file
must exist in the consumer's own checkout (it does not need to check out
this action's repo). Leave `config` empty (the default) to use this action's
built-in `configs/versions.json`.

## ⚙️ Inputs

| Name     | Description                                                                  | Default                          |
|----------|-------------------------------------------------------------------------------|------------------------------------|
| `config` | Path to a JSON config file to override the defaults, relative to the calling repo's workspace | *(empty — uses built-in config)* |
| `key`    | Optional key to extract as the generic `value` output                        | *(none)*                          |

## 📤 Outputs

Every array output is sorted alphabetically by the action, regardless of the
order the items are listed in the config file — so output order stays
consistent even if the config is overridden or edited out of order. If
`python_versions_standard`, `python_versions_threaded`, `os_ubuntu`,
`os_macos`, or `os_windows` is absent from the config file, the
corresponding output (and `python_versions`/`os_unix`/`os_all`, if all of
their inputs are absent) defaults to an empty array (`[]`) rather than
erroring.

| Name                        | Description                                  |
|-----------------------------|-----------------------------------------------|
| `config`                    | Full config file content as compact JSON (not sorted) |
| `python_versions`           | JSON array of all Python versions, sorted (derived: `python_versions_standard` + `python_versions_threaded`; `[]` if both are absent) |
| `python_versions_standard`  | JSON array of standard (non-threaded) Python versions, sorted (`[]` if absent from the config) |
| `python_versions_threaded`  | JSON array of free-threaded Python versions, sorted (`[]` if absent from the config) |
| `os_unix`                   | JSON array of all Unix-based OS runner labels, sorted (derived: `os_ubuntu` + `os_macos`; `[]` if both are absent) |
| `os_all`                    | JSON array of all OS runner labels, sorted (derived: `os_ubuntu` + `os_macos` + `os_windows`; `[]` if all are absent) |
| `os_ubuntu`                 | JSON array of Ubuntu OS runner labels, sorted (`[]` if absent from the config) |
| `os_macos`                  | JSON array of macOS runner labels, sorted (`[]` if absent from the config) |
| `os_windows`                | JSON array of Windows runner labels, sorted (`[]` if absent from the config) |
| `value`                     | Value of the `key` input, as compact JSON (sorted if it's an array); the step fails if the key is missing |

## 🚀 Usage

```yaml
jobs:
  config:
    runs-on: ubuntu-latest
    outputs:
      python_versions: ${{ steps.cfg.outputs.python_versions }}
      os_ubuntu: ${{ steps.cfg.outputs.os_ubuntu }}
    steps:
      - uses: actions/checkout@v4
      - id: cfg
        uses: durandtibo/workflow-config-action@main

  test:
    needs: config
    strategy:
      matrix:
        python-version: ${{ fromJSON(needs.config.outputs.python_versions) }}
        os: ${{ fromJSON(needs.config.outputs.os_ubuntu) }}
    runs-on: ${{ matrix.os }}
    steps:
      - uses: actions/setup-python@v5
        with:
          python-version: ${{ matrix.python-version }}
```

See [`.github/workflows/example.yml`](.github/workflows/example.yml) for a
full working example.

## ✅ Testing

[`.github/workflows/ci.yaml`](.github/workflows/ci.yaml) runs on every
push/PR and calls two reusable workflows:

- [`test-local.yaml`](.github/workflows/test-local.yaml) — exercises the
  action using the **current repository code** (`uses: ./`), so changes are
  validated before they're released.
- [`test-stable.yaml`](.github/workflows/test-stable.yaml) — exercises the
  **published** action (`uses: durandtibo/workflow-config-action@main`), to
  catch regressions in what consumers actually pick up.

Both workflows run the same suite: default config, the `config` override
input (using fixtures under [`tests/fixtures`](tests/fixtures)), the `key`
input for both scalar and array values, sorting, the
`python_versions`/`os_unix`/`os_all` union derivations (both when all their
inputs are present and when only some are, e.g. `python_versions_threaded`
or `os_windows` absent), missing/absent-key config files, and unknown
keys — each as a separate job asserting on the action's outputs with `jq`.
Every job runs on an `[ubuntu-latest, macos-latest, windows-latest]` matrix
(with `fail-fast: false`) to confirm the action's bash/`jq` logic behaves
identically across all three GitHub-hosted runner OSes.

Both workflows can also be triggered manually (`workflow_dispatch`).

## 📄 License

See [LICENSE](LICENSE).
