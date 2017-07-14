#!/usr/bin/env bash

function ensure_shared_links_exists_ensure_var_exists
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
readonly -f "ensure_shared_links_exists_ensure_var_exists"

function ensure_shared_links_exists
{
    ensure_shared_links_exists_ensure_var_exists || return $?
    [[ "${#DEPLOY_SHARED_ITEMS[@]}" -eq 0 ]] && return 0

    declare -r shared_path="$1"

    ${VERBOSE} && display_title 1 "Ensuring shared links exists on servers"
    remote_exec_function "ensure_shared_links_exists" "$shared_path" "${DEPLOY_SHARED_ITEMS[@]}" || return $?

    return 0
}
readonly -f "ensure_shared_links_exists"
