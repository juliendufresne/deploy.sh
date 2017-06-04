#!/usr/bin/env bash

function clean_old_releases
{
    [[ -v DEPLOY_MAX_RELEASES ]] || DEPLOY_MAX_RELEASES="0"
    [[ "$DEPLOY_MAX_RELEASES" -eq 0 ]] && return "0"
    declare -r releases_path="$1"
    declare -r current_path="$2"

    ${VERBOSE} && action "Clean old releases"
    remote_exec_function "clean_oldest_releases" "$DEPLOY_MAX_RELEASES" "$releases_path" "$current_path" || return $?

    return 0

}
readonly -f "clean_old_releases"
