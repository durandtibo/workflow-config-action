#!/usr/bin/env bash
# Check that the inputs and outputs of the README match action.yaml: every name of action.yaml
# has a row in the README table of the same section, and every row of the README exists in
# action.yaml. The default of each input is compared too. Run it with `make check-readme`.
set -euo pipefail

cd "$(dirname "$0")/.."

# Names of the keys under the top-level block `$1` of action.yaml (inputs or outputs)
action_names() {
	awk -v block="$1:" '
		/^[a-z]/ { in_block = ($0 == block); next }
		in_block && /^  [a-z_-]+:/ { sub(/^  /, ""); sub(/:.*/, ""); print }
	' action.yaml | LC_ALL=C sort
}

# Names in the first column of the README table under the heading that contains `$1`
readme_names() {
	awk -v heading="$1" '
		/^## / { in_section = (index($0, heading) > 0); next }
		in_section && /^\| `/ { sub(/^\| `/, ""); sub(/`.*/, ""); print }
	' README.md | LC_ALL=C sort
}

status=0
for block in inputs outputs; do
	heading="$(printf '%s' "$block" | awk '{ print toupper(substr($0, 1, 1)) substr($0, 2) }')"
	expected="$(action_names "$block")"
	actual="$(readme_names "$heading")"
	if [ -z "$expected" ] || [ "$expected" != "$actual" ]; then
		echo "::error::The $block of README.md differ from action.yaml (see dev/check_readme.sh)"
		diff <(printf '%s\n' "$expected") <(printf '%s\n' "$actual") || true
		status=1
	fi
done

# An input without a default is documented as _(none)_, an empty default as _(empty...)_
for name in $(action_names inputs); do
	default="$(awk -v name="  $name:" '
		/^[a-z]/ { in_inputs = ($0 == "inputs:"); in_input = 0; next }
		in_inputs && $0 ~ /^  [a-z_-]+:/ { in_input = ($0 == name); next }
		in_input && /^    default:/ { sub(/^    default: */, ""); print; exit }
	' action.yaml)"
	row="$(grep -E '^\| `'"$name"'` +\|' README.md | head -n 1 || true)"
	if [ "$default" = '""' ] && ! grep -q -E '_\((empty|none)' <<<"$row"; then
		echo "::error::The README row of the input $name must document its empty default"
		status=1
	fi
done

[ "$status" -eq 0 ] || exit 1
echo "✅ The README inputs and outputs match action.yaml"
