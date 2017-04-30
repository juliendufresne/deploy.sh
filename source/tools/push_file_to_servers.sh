#!/usr/bin/env bash

function push_file_to_servers_ensure_var_exists
{
    # simple vars
    for defined_variable_name in "DEBUG" "VERY_VERBOSE"
    do
        if ! [[ -v "$defined_variable_name" ]]
        then
            DEBUG=
            VERY_VERBOSE=
            error "Something unexpected happened: $defined_variable_name should be defined"

            return "1"
        fi
    done

    # arrays
    for defined_variable_name in "FILTERED_DEPLOY_SERVER_LIST" "DEPLOY_RSYNC_OPTIONS"
    do
        if ! declare -p $defined_variable_name 2>/dev/null | grep -q "^declare \-[aA]"
        then
            FILTERED_DEPLOY_SERVER_LIST=()
            DEPLOY_RSYNC_OPTIONS=()
            error "Something unexpected happened: $defined_variable_name should be defined and should be an array"

            return "1"
        fi
    done

    return "0"
}
readonly -f "push_file_to_servers_ensure_var_exists"

function push_file_to_servers
{
    declare -r file="$1"
    declare -r destination="$2"

    push_file_to_servers_ensure_var_exists || return "$?"

    for deploy_ssh_server in "${!FILTERED_DEPLOY_SERVER_LIST[@]}"
    do
        declare server="${FILTERED_DEPLOY_SERVER_LIST[$deploy_ssh_server]}"
        push_file_to_server "$server" "$file" "$destination" "$deploy_ssh_server" || return "1"
    done

    return "0"
}
readonly -f "push_file_to_servers"

function push_file_to_server
{
    declare -r server="$1"
    declare -r file="$2"
    declare -r destination="$3"
    declare server_name="${4:-}"

    declare regex='^[0-9]+$'
    [[ "$server_name" =~ $regex ]] && server_name="#$server_name"

    push_file_to_servers_ensure_var_exists || return "$?"

    declare -a rsync_options=("--safe-links" "--executability")
    ${VERY_VERBOSE} || rsync_options+=("--quiet")

    if [[ "${#DEPLOY_RSYNC_OPTIONS[@]}" -gt 0 ]]
    then
        rsync_options+=("${DEPLOY_RSYNC_OPTIONS[@]}")
    fi

    declare -r output_file="$(mktemp)"
    rsync "${rsync_options[@]}" "$file" "$server:$destination" &>"$output_file" || {
        error "Unable to send file to server $server_name"

        printf >&2 'Following is the output of the command\n'
        printf >&2 '######################################\n'
        cat "$output_file"
        rm "$output_file"

        return "1"
    }

    ${DEBUG} && cat "$output_file"

    rm "$output_file"

    return "0"
}
readonly -f "push_file_to_server"
