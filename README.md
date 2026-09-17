# workflow-config-action

A composite GitHub Action that exposes reusable workflow configuration
(Python versions, OS matrices, etc.) as job outputs, so multiple workflows
and repos can share a single source of truth instead of duplicating
hardcoded lists.

## Config

By default the action uses the config bundled in this repo,
[`configs/versions.json`](configs/versions.json):

```json
{
  "python_versions": ["3.14", "3.14t", "3.13", "3.13t", "3.12", "3.11", "3.10"],
  "os_ubuntu": ["ubuntu-latest", "..."],
  "os_macos": ["macos-latest", "..."]
}
```

Add new keys there as needed, and expose them in [`action.yml`](action.yml)
outputs the same way `python_versions` and `os_ubuntu` are.

`os_unix` is not stored in the config file — it's derived in `action.yml`
by concatenating `os_ubuntu` and `os_macos`, so the two lists never drift
out of sync with their union.

The official list of GitHub-hosted runners (used for the `os_*` keys) is
available at
[docs.github.com/en/actions/reference/runners/github-hosted-runners](https://docs.github.com/en/actions/reference/runners/github-hosted-runners).

### Overriding the config in a consumer repo

Any repo using this action can override the defaults by checking out its own
config file and passing its path via the `config` input:

```yaml
steps:
  - uses: actions/checkout@v4
  - id: cfg
    uses: your-org/workflow-config-action@v1
    with:
      config: .github/workflow-config.json
```

The path is resolved relative to the calling repo's workspace, so the file
must exist in the consumer's own checkout (it does not need to check out
this action's repo). Leave `config` empty (the default) to use this action's
built-in `configs/versions.json`.

## Inputs

| Name     | Description                                                                  | Default                          |
|----------|-------------------------------------------------------------------------------|------------------------------------|
| `config` | Path to a JSON config file to override the defaults, relative to the calling repo's workspace | *(empty — uses built-in config)* |
| `key`    | Optional key to extract as the generic `value` output                        | *(none)*                          |

## Outputs

Every array output is sorted alphabetically by the action, regardless of the
order the items are listed in the config file — so output order stays
consistent even if the config is overridden or edited out of order.

| Name              | Description                                  |
|-------------------|-----------------------------------------------|
| `config`          | Full config file content as compact JSON (not sorted) |
| `python_versions` | JSON array of Python versions, sorted        |
| `os_unix`         | JSON array of all Unix-based OS runner labels, sorted (derived: `os_ubuntu` + `os_macos`) |
| `os_ubuntu`       | JSON array of Ubuntu OS runner labels, sorted |
| `os_macos`        | JSON array of macOS runner labels, sorted    |
| `value`           | Value of the `key` input, as compact JSON (sorted if it's an array) |

## Usage

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
        uses: your-org/workflow-config-action@v1

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
