#!/usr/bin/env bash

function command_line_parse_single_option
{
    declare -r error_prefix="$1"
    declare -n _ref="$2"
    declare -r previous_value="$3"
    declare -r new_value="$4"

    if [[ -z "$new_value" ]]
    then
        display_release_usage
        error "$error_prefix: value required."

        return 1
    fi

    if [[ -n "$_ref" ]]
    then
        usage
        error "$error_prefix: Can not specify more than one value."

        return 1
    fi

    _ref="$new_value"

    return 0
}
readonly -f "command_line_parse_single_option"
