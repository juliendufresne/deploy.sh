#!/usr/bin/env bash

function resolve_option_with_env
{
    declare -n _ref="$1"
    declare -r environment_variable_name="$2"

    if compgen -A variable ${environment_variable_name} &>/dev/null
    then
        _ref="${!environment_variable_name}"
    fi
}
readonly -f "resolve_option_with_env"
