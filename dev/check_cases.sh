#!/usr/bin/env bash
# Check that tests/cases.json is well formed, so that a typo in a row fails here, on a laptop,
# instead of passing silently in ci-action.yaml: unique ids, a known outcome, a boolean
# `released` flag, and fixtures that exist. Run it with `make check-cases`.
set -euo pipefail

cd "$(dirname "$0")/.."
cases=tests/cases.json

jq -e '
  type == "array" and length > 0
  and (map(.id) | length == (unique | length))
  and all(.[];
    (.id | type == "string" and test("^[a-z0-9-]+$"))
    and (.expect == "success" or .expect == "failure")
    and (.released | type == "boolean")
    and (.inputs | type == "object")
    and ((.inputs | keys) - ["config", "key"] == [])
    and (if .expect == "failure" then has("unset") and (has("expected") | not) else (has("unset") | not) end))
' "$cases" >/dev/null || {
	echo "::error::$cases is not well formed (see dev/check_cases.sh)"
	exit 1
}

status=0
while IFS= read -r path; do
	# A failure row may point at a file that is missing on purpose
	if [ ! -f "$path" ] && ! jq -e --arg p "$path" 'any(.[]; (.inputs.config == $p and (.id | startswith("missing-"))))' "$cases" >/dev/null; then
		echo "::error::The fixture $path of $cases does not exist"
		status=1
	fi
done < <(jq -r '.[].inputs.config // empty' "$cases")
[ "$status" -eq 0 ] || exit 1
echo "✅ $(jq 'length' "$cases") cases are well formed"
