#!/usr/bin/env bash
#
# Check the result of one case of the action tests (used by ci-action.yaml, for the local
# action and for the released action, so that both runs assert the same thing).
#
# The cases are the rows of tests/cases.json (the default config has its own case in the
# `test` job of ci-action.yaml). This script checks one of them.
#
# Environment variables (passed through env:, never interpolated in a script):
#   CASE            The case, as a JSON object (see below)
#   OUTCOME         The outcome of the step that ran the action (success or failure)
#   CONFIG, PYTHON_VERSIONS_STANDARD, PYTHON_VERSIONS_THREADED, PYTHON_VERSIONS, OS_UBUNTU,
#   OS_MACOS, OS_WINDOWS, OS_UNIX, OS_ALL, VALUE
#                   The outputs of the action (empty when the step did not set them)
#   BUNDLED_CONFIG  Optional. Path of the config file the action must have bundled. Set it for
#                   the local action only: the released action bundles its own config.
#
# A case has "expect" (the outcome) and, optionally:
#   "expected":  an object output name -> exact value, compared as compact JSON
#   "non-empty": true, every list output must have at least one element
#   "unset":     "all" or a list of output names that must not be set (the action failed)
# On success the outputs are always checked against the CONFIG output, which is the config
# the action actually used (so it holds for the released action too): every list is a sorted
# JSON array of strings, the derived lists are the unions of their parts, and VALUE is the
# key of the `key` input (sorted when it is an array), or empty without a `key`.
#
# Exit codes:
#   0 - The case passed
#   1 - At least one problem (each one is reported as an ::error:: on stderr)

set -euo pipefail

errors=0
id=""
fail() {
	echo "::error::[$id] $*" >&2
	errors=1
}

LIST_OUTPUTS="PYTHON_VERSIONS_STANDARD PYTHON_VERSIONS_THREADED PYTHON_VERSIONS OS_UBUNTU OS_MACOS OS_WINDOWS OS_UNIX OS_ALL"

# is_sorted_array TEXT: TEXT is a JSON array of strings in sorted order
is_sorted_array() {
	jq -e 'type == "array" and all(.[]; type == "string") and . == sort' <<<"$1" >/dev/null 2>&1
}

# expect_equal NAME ACTUAL WANT: compare two JSON texts as compact JSON
expect_equal() {
	local want
	want=$(jq -c . <<<"$3")
	[ "$2" = "$want" ] || fail "The output $1 must be $want (got '$2')"
}

check_lists() {
	local name
	for name in $LIST_OUTPUTS; do
		is_sorted_array "${!name:-}" || fail "The output $name must be a sorted JSON array of strings (got '${!name:-}')"
	done
	[ "$errors" -eq 0 ] || return 0
	if [ "$(jq -r '.["non-empty"] // false' <<<"$CASE")" = "true" ]; then
		for name in $LIST_OUTPUTS; do
			[ "$(jq 'length' <<<"${!name}")" -gt 0 ] || fail "The output $name must not be empty"
		done
	fi
}

check_against_config() {
	local config="${CONFIG:-}" key
	if ! jq -e 'type == "object"' <<<"$config" >/dev/null 2>&1; then
		fail "The output CONFIG must be a JSON object (got '$config')"
		return 0
	fi
	expect_equal PYTHON_VERSIONS_STANDARD "${PYTHON_VERSIONS_STANDARD:-}" "$(jq -c '(.python_versions_standard // []) | sort' <<<"$config")"
	expect_equal PYTHON_VERSIONS_THREADED "${PYTHON_VERSIONS_THREADED:-}" "$(jq -c '(.python_versions_threaded // []) | sort' <<<"$config")"
	expect_equal PYTHON_VERSIONS "${PYTHON_VERSIONS:-}" "$(jq -c '((.python_versions_standard // []) + (.python_versions_threaded // [])) | sort' <<<"$config")"
	expect_equal OS_UBUNTU "${OS_UBUNTU:-}" "$(jq -c '(.os_ubuntu // []) | sort' <<<"$config")"
	expect_equal OS_MACOS "${OS_MACOS:-}" "$(jq -c '(.os_macos // []) | sort' <<<"$config")"
	expect_equal OS_WINDOWS "${OS_WINDOWS:-}" "$(jq -c '(.os_windows // []) | sort' <<<"$config")"
	expect_equal OS_UNIX "${OS_UNIX:-}" "$(jq -c '((.os_ubuntu // []) + (.os_macos // [])) | sort' <<<"$config")"
	expect_equal OS_ALL "${OS_ALL:-}" "$(jq -c '((.os_ubuntu // []) + (.os_macos // []) + (.os_windows // [])) | sort' <<<"$config")"
	key=$(jq -r '.inputs.key // empty' <<<"$CASE")
	if [ -z "$key" ]; then
		[ -z "${VALUE:-}" ] || fail "The output VALUE must be empty without the key input (got '${VALUE:-}')"
	else
		expect_equal VALUE "${VALUE:-}" "$(jq -c --arg k "$key" '.[$k] | if type == "array" then sort else . end' <<<"$config")"
	fi
}

check_bundled_config() {
	[ -z "${BUNDLED_CONFIG:-}" ] || expect_equal CONFIG "${CONFIG:-}" "$(jq -c . "$BUNDLED_CONFIG")"
}

check_expected() {
	local name var want
	while IFS= read -r name; do
		var=$(tr '[:lower:]' '[:upper:]' <<<"$name")
		want=$(jq -c --arg n "$name" '.expected[$n]' <<<"$CASE")
		expect_equal "$var" "${!var:-}" "$want"
	done < <(jq -r '.expected // {} | keys[]' <<<"$CASE")
}

check_unset() {
	local name names rule
	rule=$(jq -c '.unset // empty' <<<"$CASE")
	[ -n "$rule" ] || return 0
	if [ "$rule" = '"all"' ]; then
		names="CONFIG $LIST_OUTPUTS VALUE"
	else
		names=$(jq -r '[.unset[] | ascii_upcase] | join(" ")' <<<"$CASE")
	fi
	for name in $names; do
		[ -z "${!name:-}" ] || fail "The output $name must not be set after a failure (got '${!name}')"
	done
}

main() {
	local expect
	id=$(jq -r '.id' <<<"${CASE:?CASE must be set}")
	expect=$(jq -r '.expect' <<<"$CASE")

	if [ "${OUTCOME:-}" != "$expect" ]; then
		fail "The outcome must be '$expect' (got '${OUTCOME:-}')"
		return 1
	fi
	if [ "$expect" = "success" ]; then
		check_lists
		[ "$errors" -ne 0 ] || check_against_config
		check_bundled_config
		check_expected
	else
		check_unset
	fi
	[ "$errors" -eq 0 ] || return 1
	echo "✅ Case $id: outcome $OUTCOME"
}

main "$@"
