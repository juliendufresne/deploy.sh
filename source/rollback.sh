#!/usr/bin/env bash

#### PRIVATE VARIABLES ####
# declared globally so we can "trap" them on exit

declare -g DEPLOY_REMOTE_SCRIPT_FILE_ON_LOCAL=""
declare -A -g DEPLOY_REMOTE_SCRIPT_FILES=()
declare -g DEPLOY_CURRENT_rollback_DIR=

function display_rollback_help
{
    declare -r green="\e[32m"
    declare -r yellow="\e[33m"
    declare -r reset_foreground="\e[39m"

    printf "
${yellow}Usage:${reset_foreground}
  rollback [options] <config-file>

${yellow}Arguments:${reset_foreground}
  ${green}config-file${reset_foreground}    Configuration file for the stage

${yellow}Options:${reset_foreground}
Note: every options can be defined with environment variable with prefix DEPLOY_*
  ${green}-h, --help${reset_foreground}                    Display this help message
  ${green}-d, --deploy PATH${reset_foreground}             Specify the global deploy path containing /current, /rollbacks and /shared
  ${green}-c, --current CURRENT_PATH${reset_foreground}    Specify the path of the current published version (incompatible with --deploy)
  ${green}-r, --releases RELEASES_PATH${reset_foreground}  Specify where every releases are stored (incompatible with --deploy)
  ${green}-s, --shared SHARED_PATH${reset_foreground}      Specify where every persistent files and directories are stored (incompatible with --deploy)
  ${green}-v|vv|vvv, --verbose${reset_foreground}          Increase the verbosity of messages: 1 for normal output, 2 for more verbose output and 3 for debug.
"
}
readonly -f "display_rollback_help"

function display_rollback_usage
{
    declare -r green="\e[32m"
    declare -r yellow="\e[33m"
    declare -r reset_foreground="\e[39m"

    printf "${green}rollback [-h|--help] [-v|vv|vvv|--verbose] [-d|--deploy PATH] [-c|--current CURRENT_PATH] [-r|--releases RELEASES_PATH] [-s|--shared SHARED_PATH] <config-file>${reset_foreground}\n"
}
readonly -f "display_rollback_usage"

function rollback_cleanup_local_script
{
    if ! [[ -z "$DEPLOY_REMOTE_SCRIPT_FILE_ON_LOCAL" ]] && [[ -f "$DEPLOY_REMOTE_SCRIPT_FILE_ON_LOCAL" ]]
    then
        rm "$DEPLOY_REMOTE_SCRIPT_FILE_ON_LOCAL"
        DEPLOY_REMOTE_SCRIPT_FILE_ON_LOCAL=""
    fi

    return 0
}
readonly -f "rollback_cleanup_local_script"

function rollback_cleanup_remote_scripts
{
    declare -r output_file="$(mktemp -t deploy.XXXXXXXXXX)"
    # clean script file on remotes
    # each server store the script file on its own path (different from each other)
    if [[ "${#DEPLOY_REMOTE_SCRIPT_FILES[@]}" -gt 0 ]]
    then
        for server_name in "${!DEPLOY_REMOTE_SCRIPT_FILES[@]}"
        do
            remote_exec_command_on_server_name "$server_name" "rm" "--preserve-root" "${DEPLOY_REMOTE_SCRIPT_FILES[$server_name]}" &>"$output_file" || {
                warning "Unable to clean temporary script file on server $server_name"
                cat "$output_file"
            }
        done
    fi

    rm "$output_file"

    return 0
}
readonly -f "rollback_cleanup_remote_scripts"

function rollback_cleanup
{
    # we don't want to stop execution on failure here because we clean up everything.
    set +e

    rollback_cleanup_local_script
    rollback_cleanup_remote_scripts
}
readonly -f "rollback_cleanup"

function rollback
{
    do_not_run_twice || return $?

    trap rollback_cleanup INT TERM EXIT
    declare deploy_path
    declare current_path
    declare releases_path
    declare shared_path
    declare rollback_to_release

    rollback_to_release=""

    parse_rollback_command_line "deploy_path" "current_path" "releases_path" "shared_path" "$@" && \
    ssh_test_connection && \
    find_previous_release "$releases_path" "rollback_to_release" && \
    activate_previous_release "$current_path" "$releases_path/$rollback_to_release" "$shared_path" || {
        declare -r -i return_code=$?

        if ! [[ -v DEPLOY_SHOW_USAGE_ON_ERROR ]]
        then
            DEPLOY_SHOW_USAGE_ON_ERROR=true
        fi

        if ${DEPLOY_SHOW_USAGE_ON_ERROR}
        then
            printf "\n"
            display_rollback_usage
            printf "\n"
        fi

        return ${return_code}
    }

    clean_last_release "$current_path" "$releases_path"
    finish_rollback

    return 0
}
readonly -f "rollback"
