#!/usr/bin/env bash

function ensure_directory_structure_exists
{
    declare -r current_path="$1"
    declare -r releases_path="$2"
    declare -r shared_path="$3"

    ${VERBOSE} && display_title 1 "Ensuring directory structure exists on servers"
    remote_exec_function "ensure_directory_structure_exists" "$current_path" "$releases_path" "$shared_path" || return $?

    return 0
}
readonly -f "ensure_directory_structure_exists"
