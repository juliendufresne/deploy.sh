#!/usr/bin/env bash

function resolve_option_with_env
{
    declare -n _ref="$1"
    declare -r environment_variable_name="$2"

    if ( set -o posix ; set ) | grep -E -q "^$environment_variable_name="
    then
        _ref="${!environment_variable_name}"
    fi
}
readonly -f "resolve_option_with_env"
