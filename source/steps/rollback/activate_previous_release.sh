#!/usr/bin/env bash

function activate_previous_release
{
    declare -r current_path="$1"
    declare -r release_path="$2"
    declare -r shared_path="$3"

    call_remote_hook "pre_activate_previous_release" true "$current_path" "$release_path" "$shared_path" || return $?

    ${VERBOSE} && display_title 1 "Activating previous release"
    remote_exec_function "activate_release" "$current_path" "$release_path" || return $?
    # at this point, a failure should not produce a rollback
    call_remote_hook "post_activate_previous_release" false "$current_path" "$release_path" "$shared_path"

    return 0
}
readonly -f "activate_previous_release"
