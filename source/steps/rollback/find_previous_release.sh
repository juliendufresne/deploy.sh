#!/usr/bin/env bash

function find_previous_release
{
    declare -r releases_path="$1"
    declare -n previous_release="$2"

    reset_title_level
    display_title "Finding previous release"
    increase_title_level

    for deploy_ssh_server in "${!FILTERED_DEPLOY_SERVER_LIST[@]}"
    do
        declare found_release="$(remote_exec_function_on_server_name "$deploy_ssh_server" "find_previous_release" "$releases_path")"

        if [[ -z "$found_release" ]]
        then
            error "Unable to find a previous release for server '$deploy_ssh_server'."

            remote_exec_function "show_previous_release" "$releases_path"

            return 1
        fi

        if [[ -n "$previous_release" ]] && [[ "$previous_release" != "$found_release" ]]
        then
            error "Found two different 'previous release' from two servers. Can not rollback to non homogeneous release."

            remote_exec_function "show_previous_release" "$releases_path"

            return 1
        fi

        previous_release="$found_release"
    done

    return 0
}
readonly -f "find_previous_release"
