#!/usr/bin/env bash

function clean_last_release
{
    declare -r current_path="$1"
    declare -r releases_path="$2"

    ${VERBOSE} && display_title 1 "Remove previously activated release"
    remote_exec_function "clean_last_release" "$current_path" "$releases_path" || return $?

    return 0
}
readonly -f "clean_last_release"
