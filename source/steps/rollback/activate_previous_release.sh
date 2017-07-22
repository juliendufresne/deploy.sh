#!/usr/bin/env bash

function activate_previous_release
{
    declare -r current_path="$1"
    declare -r release_path="$2"
    declare -r shared_path="$3"

    reset_title_level
    display_title "Activating previous release"
    increase_title_level

    call_remote_hook "pre_activate_previous_release" true "$current_path" "$release_path" "$shared_path" || return $?

    remote_exec_function "activate_release" "$current_path" "$release_path" || return $?
    # at this point, a failure should not produce a rollback
    call_remote_hook "post_activate_previous_release" false "$current_path" "$release_path" "$shared_path"

    return 0
}
readonly -f "activate_previous_release"
