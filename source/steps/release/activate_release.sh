#!/usr/bin/env bash

function activate_release
{
    declare -r current_path="$1"
    declare -r release_path="$2"

    ${VERBOSE} && action "Activating release"
    remote_exec_function "activate_release" "$current_path" "$release_path" || return "$?"

    return "0"

}
readonly -f "activate_release"
