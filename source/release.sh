#!/usr/bin/env bash

#### PRIVATE VARIABLES ####
# declared globally so we can "trap" them on exit

declare -g DEPLOY_REMOTE_SCRIPT_FILE_ON_LOCAL=""
declare -A -g DEPLOY_REMOTE_SCRIPT_FILES=()
declare -g DEPLOY_CURRENT_RELEASE_DIR=

function display_release_help
{
    declare -r green="\e[32m"
    declare -r yellow="\e[33m"
    declare -r reset_foreground="\e[39m"

    printf "
${yellow}Usage:${reset_foreground}
  release [options] <config-file> <archive-file> [<server-name> ...]

${yellow}Arguments:${reset_foreground}
  ${green}config-file${reset_foreground}    Configuration file for the stage
  ${green}archive-file${reset_foreground}   Archive to deploy
  ${green}server-name${reset_foreground}    Reduce the list of server define in the stage-config-file to the one listed. (${yellow}optional${reset_foreground})

${yellow}Options:${reset_foreground}
Note: every options can be defined with environment variable with prefix DEPLOY_*
  ${green}-h, --help${reset_foreground}                    Display this help message
  ${green}-d, --deploy PATH${reset_foreground}             Specify the global deploy path containing /current, /releases and /shared
  ${green}-c, --current CURRENT_PATH${reset_foreground}    Specify the path of the current published version (incompatible with --deploy)
  ${green}-r, --releases RELEASES_PATH${reset_foreground}  Specify where every releases are stored (incompatible with --deploy)
  ${green}-s, --shared SHARED_PATH${reset_foreground}      Specify where every persistent files and directories are stored (incompatible with --deploy)
  ${green}-q, --quiet${reset_foreground}                   Disable output except for errors.
  ${green}-v|vv|vvv, --verbose${reset_foreground}          Increase the verbosity of messages: 1 for normal output, 2 for more verbose output and 3 for debug.
"
}
readonly -f "display_release_help"

function display_release_usage
{
    declare -r green="\e[32m"
    declare -r yellow="\e[33m"
    declare -r reset_foreground="\e[39m"

    printf "${green}release [-h|--help] [-q|--quiet] [-v|vv|vvv|--verbose] [-d|--deploy PATH] [-c|--current CURRENT_PATH] [-r|--releases RELEASES_PATH] [-s|--shared SHARED_PATH] <config-file> <archive-file> [<server-name> ...]${reset_foreground}\n"
}
readonly -f "display_release_usage"

function cleanup_local_script
{
    if ! [[ -z "$DEPLOY_REMOTE_SCRIPT_FILE_ON_LOCAL" ]] && [[ -f "$DEPLOY_REMOTE_SCRIPT_FILE_ON_LOCAL" ]]
    then
        is_verbose && display_title "remove local temporary files"
        rm "$DEPLOY_REMOTE_SCRIPT_FILE_ON_LOCAL"
        DEPLOY_REMOTE_SCRIPT_FILE_ON_LOCAL=""
    fi

    return 0
}
readonly -f "cleanup_local_script"

function cleanup_remote_scripts
{
    declare -r output_file="$(mktemp -t deploy.XXXXXXXXXX)"
    # clean script file on remotes
    # each server store the script file on its own path (different from each other)
    if [[ "${#DEPLOY_REMOTE_SCRIPT_FILES[@]}" -gt 0 ]]
    then
        is_verbose && display_title "remove remote temporary files" && increase_title_level
        for server_name in "${!DEPLOY_REMOTE_SCRIPT_FILES[@]}"
        do
            remote_exec_command_on_server_name "$server_name" "rm" "--preserve-root" "${DEPLOY_REMOTE_SCRIPT_FILES[$server_name]}" &>"$output_file" || {
                warning "Unable to clean temporary script file on server $server_name"
                cat "$output_file"
            }
        done
        is_verbose && decrease_title_level
    fi

    if [[ -v DEPLOY_CURRENT_PUSHED_FILE ]]
    then
        is_verbose && display_title "remove file pushed to remote" && increase_title_level
        for server_name in "${!DEPLOY_REMOTE_SCRIPT_FILES[@]}"
        do
            # --recursive because we might trying to remove a directory
            # --force because the server might not have the file
            remote_exec_command_on_server_name "$server_name" "rm" "--preserve-root" "--recursive" "--force" "$DEPLOY_CURRENT_PUSHED_FILE" &>"$output_file" || {
                warning "Unable to clean temporary script file on server $server_name"
                cat "$output_file"
            }
        done
        is_verbose && decrease_title_level
    fi

    rm "$output_file"

    return 0
}
readonly -f "cleanup_remote_scripts"

function cleanup_deployed_release
{
    if [[ -z "$DEPLOY_CURRENT_RELEASE_DIR" ]]
    then
        return 0
    fi

    is_verbose && display_title "remove release directory" && increase_title_level
    remote_exec_function "remove_currently_deployed_release" "$DEPLOY_CURRENT_RELEASE_DIR"
    is_verbose && decrease_title_level

    return 0
}
readonly -f "cleanup_deployed_release"

function release_cleanup
{
    # we don't want to stop execution on failure here because we clean up everything.
    set +e

    is_verbose && display_title "Cleaning up" && increase_title_level
    cleanup_deployed_release
    cleanup_remote_scripts
    # must be the last one because previous functions uses it
    cleanup_local_script
    is_verbose && decrease_title_level
}
readonly -f "release_cleanup"

function release
{
    do_not_run_twice || return $?

    trap release_cleanup INT TERM EXIT
    declare archive_file
    declare deploy_path
    declare current_path
    declare releases_path
    declare shared_path
    declare -r release_date="$(date --utc "+%Y%m%d%H%M%S")"

    parse_release_command_line "archive_file" "deploy_path" "current_path" "releases_path" "shared_path" "$@" && \
    ssh_test_connection && \
    ensure_directory_structure_exists "$current_path" "$releases_path" "$shared_path" && \
    ensure_shared_links_exists "$shared_path" && \
    send_archive_to_servers "$releases_path" "$archive_file" && \
    extract_archive "$releases_path" "$archive_file" "$release_date" && \
    link_release_with_shared_folder "$releases_path/$release_date" "$shared_path" && \
    activate_release "$current_path" "$releases_path/$release_date" || {
        declare -r -i return_code=$?

        if ! [[ -v DEPLOY_SHOW_USAGE_ON_ERROR ]]
        then
            DEPLOY_SHOW_USAGE_ON_ERROR=true
        fi

        if ${DEPLOY_SHOW_USAGE_ON_ERROR}
        then
            printf "\n"
            display_release_usage
            printf "\n"
        fi

        return ${return_code}
    }

    # if there is an error while cleaning, we still want to continue the execution of the script
    clean_old_releases "$releases_path" "$current_path"
    finish_release "$archive_file"

    return 0
}
readonly -f "release"
