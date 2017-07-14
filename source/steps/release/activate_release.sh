#!/usr/bin/env bash

function activate_release
{
    declare -r current_path="$1"
    declare -r release_path="$2"

    ${VERBOSE} && display_title 1 "Activating release"
    remote_exec_function "activate_release" "$current_path" "$release_path" || return $?
    # we should not remove current release dir after it has been activated
    DEPLOY_CURRENT_RELEASE_DIR=

    return 0

}
readonly -f "activate_release"
