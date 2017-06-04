#!/usr/bin/env bash

#### PRIVATE VARIABLES ####
# declared globally so we can "trap" them on exit

declare -r -g DEPLOY_REMOTE_SCRIPT_FILE_ON_LOCAL="$(mktemp)"
declare -A -g DEPLOY_REMOTE_SCRIPT_FILES=()

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
  ${green}-v|vv|vvv, --verbose${reset_foreground}          Increase the verbosity of messages: 1 for normal output, 2 for more verbose output and 3 for debug.
"
}
readonly -f "display_release_help"

function display_release_usage
{
    declare -r green="\e[32m"
    declare -r yellow="\e[33m"
    declare -r reset_foreground="\e[39m"

    printf "${green}release [-h|--help] [-v|vv|vvv|--verbose] [-d|--deploy PATH] [-c|--current CURRENT_PATH] [-r|--releases RELEASES_PATH] [-s|--shared SHARED_PATH] <config-file> <archive-file> [<server-name> ...]${reset_foreground}\n"
}
readonly -f "display_release_usage"

function release_cleanup
{
    # we don't want to stop execution on failure here because we clean up everything.
    set +e

    [[ -f "$DEPLOY_REMOTE_SCRIPT_FILE_ON_LOCAL" ]] && rm "$DEPLOY_REMOTE_SCRIPT_FILE_ON_LOCAL"

    declare -r output_file="$(mktemp)"
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
    activate_release "$current_path" "$releases_path/$release_date" && \
    clean_old_releases "$releases_path" "$current_path" || {
        declare -r -i return_code=$?

        printf "\n"
        display_release_usage
        printf "\n"

        return ${return_code}
    }

    return 0
}
readonly -f "release"
