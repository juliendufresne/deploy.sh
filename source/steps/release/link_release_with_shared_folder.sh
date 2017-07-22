#!/usr/bin/env bash

function link_release_with_shared_folder_ensure_var_exists
{
    # arrays
    for defined_variable_name in "DEPLOY_SHARED_ITEMS"
    do
        if ! declare -p $defined_variable_name 2>/dev/null | grep -q "^declare \-[aA]"
        then
            DEPLOY_SHARED_ITEMS=()
            error "Something unexpected happened: $defined_variable_name should be defined and should be an array"

            return 1
        fi
    done

    return 0
}
readonly -f "link_release_with_shared_folder_ensure_var_exists"

function link_release_with_shared_folder
{
    link_release_with_shared_folder_ensure_var_exists || return $?
    [[ "${#DEPLOY_SHARED_ITEMS[@]}" -eq 0 ]] && return "0"

    declare -r release_path="$1"
    declare -r shared_path="$2"

    reset_title_level
    display_title "Linking release with shared items"
    increase_title_level

    remote_exec_function "link_shared_to_release" "$release_path" "$shared_path" "${DEPLOY_SHARED_ITEMS[@]}" || return $?
    call_remote_hook "post_link_release_with_shared_folder" true "$release_path" "$shared_path" || return $?

    return 0
}
readonly -f "link_release_with_shared_folder"
