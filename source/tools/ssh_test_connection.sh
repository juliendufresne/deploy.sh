#!/usr/bin/env bash

function ssh_test_connection_ensure_var_exists
{
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
    reset_title_level
    display_title "Testing remote server connectivity"
    increase_title_level

    ssh_test_connection_ensure_var_exists || return $?

    declare -i return_code=0
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

        is_verbose && display_title "server \e[32m$server_name\e[39m"

        if is_debug
        then
            declare title="ssh"
            for ssh_command in "${ssh_command_options[@]}"
            do
                title="$title $ssh_command"
            done
            increase_title_level
            display_title "\e[33m$title $server exit\e[39m"
            decrease_title_level
        fi

        declare output_file="$(mktemp -t deploy.XXXXXXXXXX)"
        if ! ssh "${ssh_command_options[@]}" "$server" exit &>"$output_file"
        then
            error_with_output_file "$output_file" "Unable to connect to server $server_name."

            return_code=1
        else
            rm "$output_file"
        fi
    done

    return ${return_code}
}
readonly -f "ssh_test_connection"
