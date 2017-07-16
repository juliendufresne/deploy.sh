#!/usr/bin/env bash

function ssh_test_connection_ensure_var_exists
{
    # simple vars
    for defined_variable_name in "VERBOSE" "VERY_VERBOSE" "DEBUG"
    do
        if ! [[ -v "$defined_variable_name" ]]
        then
            VERBOSE=
            VERY_VERBOSE=
            DEBUG=
            error "Something unexpected happened: $defined_variable_name should be defined"

            return 1
        fi
    done

    # arrays
    for defined_variable_name in "FILTERED_DEPLOY_SERVER_LIST" "DEPLOY_SSH_OPTIONS"
    do
        if ! declare -p $defined_variable_name 2>/dev/null | grep -q "^declare \-[aA]"
        then
            FILTERED_DEPLOY_SERVER_LIST=()
            DEPLOY_SSH_OPTIONS=()
            error "Something unexpected happened: $defined_variable_name should be defined and should be an array"

            return 1
        fi
    done

    return 0
}
readonly -f "ssh_test_connection_ensure_var_exists"

function ssh_test_connection
{
    do_not_run_twice || return $?
    ${VERBOSE} && display_title 1 "Testing remote server connectivity"
    ssh_test_connection_ensure_var_exists || return $?

    declare output_file="$(mktemp -t deploy.XXXXXXXXXX)"
    declare -a ssh_command_options=("-vvv" "-T")
    if [[ "${#DEPLOY_SSH_OPTIONS[@]}" -gt 0 ]]
    then
        ssh_command_options+=("${DEPLOY_SSH_OPTIONS[@]}")
    fi

    for deploy_ssh_server in "${!FILTERED_DEPLOY_SERVER_LIST[@]}"
    do
        declare server="${FILTERED_DEPLOY_SERVER_LIST[$deploy_ssh_server]}"
        declare server_name="$deploy_ssh_server"
        declare regex='^[0-9]+$'
        [[ "$server_name" =~ $regex ]] && server_name="#$server_name"

        ${VERY_VERBOSE} && display_title 2 "server \e[32m$server_name\e[39;49m"

        if ! ssh "${ssh_command_options[@]}" "$server" exit &>"$output_file"
        then
            error "Unable to connect to server $server_name."

            >&2 printf 'Following is the output of the command\n'
            >&2 printf '######################################\n'
            cat "$output_file"
            rm "$output_file"

            return 1
        fi
    done
    rm "$output_file"

    return 0
}
readonly -f "ssh_test_connection"
