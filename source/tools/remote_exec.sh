#!/usr/bin/env bash

include "tools/push_file_to_servers.sh"

function remote_exec_ensure_var_exists
{
    # simple vars
    for defined_variable_name in "DEPLOY_REMOTE_SCRIPT_FILE_ON_LOCAL"
    do
        if ! [[ -v "$defined_variable_name" ]]
        then
            DEPLOY_REMOTE_SCRIPT_FILE_ON_LOCAL=""
            error "Something unexpected happened: $defined_variable_name should be defined"

            return 1
        fi
    done

    # arrays
    for defined_variable_name in "FILTERED_DEPLOY_SERVER_LIST" "DEPLOY_REMOTE_SCRIPT_FILES" "DEPLOY_SSH_OPTIONS"
    do
        if ! declare -p $defined_variable_name 2>/dev/null | grep -q "^declare \-[aA]"
        then
            FILTERED_DEPLOY_SERVER_LIST=()
            DEPLOY_REMOTE_SCRIPT_FILES=()
            DEPLOY_SSH_OPTIONS=()
            error "Something unexpected happened: $defined_variable_name should be defined and should be an array"

            return 1
        fi
    done

    return 0
}
readonly -f "remote_exec_ensure_var_exists"

function remote_exec_command_on_server_name
{
    declare -r index_on_config_servers="$1"
    declare -r command_name="$2"
    shift
    shift

    remote_exec_ensure_var_exists || return $?
    declare -a ssh_command_options=("-T")
    if [[ "${#DEPLOY_SSH_OPTIONS[@]}" -gt 0 ]]
    then
        ssh_command_options+=("${DEPLOY_SSH_OPTIONS[@]}")
    fi

    for deploy_ssh_server in "${!FILTERED_DEPLOY_SERVER_LIST[@]}"
    do
        if [[ "$deploy_ssh_server" != "$index_on_config_servers" ]]
        then
            continue
        fi
        declare server="${FILTERED_DEPLOY_SERVER_LIST[$deploy_ssh_server]}"

        ssh "${ssh_command_options[@]}" "$server" "$command_name" "$@" || return $?
    done

    return 0
}
readonly -f "remote_exec_command_on_server_name"

function remote_exec_function
{
    declare -r function_name="$1"
    declare -i server_index=0
    shift

    remote_exec_ensure_var_exists || return $?

    if [[ -z "$DEPLOY_REMOTE_SCRIPT_FILE_ON_LOCAL" ]]
    then
        DEPLOY_REMOTE_SCRIPT_FILE_ON_LOCAL="$(mktemp -t deploy.XXXXXXXXXX)"
    fi

    if ! [[ -s "$DEPLOY_REMOTE_SCRIPT_FILE_ON_LOCAL" ]]
    then
        create_remote_script_file || {
            return 1
        }
    fi

    declare -a ssh_command_options=("-T")
    if [[ "${#DEPLOY_SSH_OPTIONS[@]}" -gt 0 ]]
    then
        ssh_command_options+=("${DEPLOY_SSH_OPTIONS[@]}")
    fi

    for deploy_ssh_server in "${!FILTERED_DEPLOY_SERVER_LIST[@]}"
    do
        declare server="${FILTERED_DEPLOY_SERVER_LIST[$deploy_ssh_server]}"
        server_index=$((server_index + 1))

        if is_verbose
        then
            declare server_name="$deploy_ssh_server"
            declare regex='^[0-9]+$'
            [[ "$server_name" =~ $regex ]] && server_name="#$server_name"
            display_title "server \e[32m$server_name\e[39;49m"
            increase_title_level
        fi

        ssh "${ssh_command_options[@]}" "$server" bash -c "'
#!/usr/bin/env bash
source "${DEPLOY_REMOTE_SCRIPT_FILES["$deploy_ssh_server"]}"
declare -g TITLE_LEVEL=${TITLE_LEVEL}
${function_name} $server_index $@ || exit \"\$?\"
'" || return $?

        is_verbose && decrease_title_level
    done

    return 0
}
readonly -f "remote_exec_function"

function remote_exec_function_on_server_name
{
    declare -r index_on_config_servers="$1"
    declare -r function_name="$2"
    shift
    shift
    declare -i server_index=0

    remote_exec_ensure_var_exists || return $?

    if [[ -z "$DEPLOY_REMOTE_SCRIPT_FILE_ON_LOCAL" ]]
    then
        DEPLOY_REMOTE_SCRIPT_FILE_ON_LOCAL="$(mktemp -t deploy.XXXXXXXXXX)"
    fi

    if ! [[ -s "$DEPLOY_REMOTE_SCRIPT_FILE_ON_LOCAL" ]]
    then
        create_remote_script_file || {
            return 1
        }
    fi

    declare -a ssh_command_options=("-T")
    if [[ "${#DEPLOY_SSH_OPTIONS[@]}" -gt 0 ]]
    then
        ssh_command_options+=("${DEPLOY_SSH_OPTIONS[@]}")
    fi

    for deploy_ssh_server in "${!FILTERED_DEPLOY_SERVER_LIST[@]}"
    do
        declare server="${FILTERED_DEPLOY_SERVER_LIST[$deploy_ssh_server]}"

        if [[ "$deploy_ssh_server" = "$index_on_config_servers" ]]
        then
            ssh "${ssh_command_options[@]}" "$server" bash -c "'
#!/usr/bin/env bash
source "${DEPLOY_REMOTE_SCRIPT_FILES["$deploy_ssh_server"]}"
${function_name} $@ || exit \"\$?\"
'" || return $?
            break
        fi
    done

    return 0
}
readonly -f "remote_exec_function_on_server_name"

function create_remote_script_file
{
    declare -Ag DEPLOY_REMOTE_SCRIPT_FILES=()

    # variable interpolation
    cat >"$DEPLOY_REMOTE_SCRIPT_FILE_ON_LOCAL" <<EndOfScript
declare -g VERBOSE=${VERBOSE}
declare -g VERY_VERBOSE=${VERY_VERBOSE}
declare -g DEBUG=${DEBUG}
declare -g -i VERBOSITY_LEVEL=${VERBOSITY_LEVEL}
EndOfScript

    # raw string
    cat >>"$DEPLOY_REMOTE_SCRIPT_FILE_ON_LOCAL" <<'EndOfScript'
load "tools/hostname.sh"
load "tools/hook.sh"
load "tools/logger.sh"
load "remote/delete_application.sh"
load "remote/ensure_directory_structure_exists.sh"
load "remote/extract_archive.sh"
load "remote/releases.sh"
load "remote/shared_links.sh"
EndOfScript

    for custom_hook_name in "${!CUSTOM_HOOKS[@]}"
    do
        if [[ "${#CUSTOM_HOOKS[$custom_hook_name]}" -eq 0 ]]
        then
            continue
        fi
        IFS=";" read -ra hooks <<< "${CUSTOM_HOOKS[$custom_hook_name]}"

        for user_defined_function_name in "${hooks[@]}"
        do
            cat >>"$DEPLOY_REMOTE_SCRIPT_FILE_ON_LOCAL" <<EndOfScript
$(typeset -f "$user_defined_function_name")
add_hook "$custom_hook_name" "$user_defined_function_name"
EndOfScript
        done
    done

    declare -a ssh_command_options=("-T")
    if [[ "${#DEPLOY_SSH_OPTIONS[@]}" -gt 0 ]]
    then
        ssh_command_options+=("${DEPLOY_SSH_OPTIONS[@]}")
    fi

    for deploy_ssh_server in "${!FILTERED_DEPLOY_SERVER_LIST[@]}"
    do
        declare server="${FILTERED_DEPLOY_SERVER_LIST[$deploy_ssh_server]}"

        DEPLOY_REMOTE_SCRIPT_FILES["$deploy_ssh_server"]="$(ssh "${ssh_command_options[@]}" "$server" '/usr/bin/env bash -c "mktemp -t deploy.XXXXXXXXXX"')"
        push_file_to_server "$server" "$DEPLOY_REMOTE_SCRIPT_FILE_ON_LOCAL" "${DEPLOY_REMOTE_SCRIPT_FILES["$deploy_ssh_server"]}" "$deploy_ssh_server" || return $?
    done

    return 0
}
readonly -f "create_remote_script_file"
