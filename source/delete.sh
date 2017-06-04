#!/usr/bin/env bash

function delete_help
{
    declare -r green="\e[32m"
    declare -r yellow="\e[33m"
    declare -r reset_foreground="\e[39m"

    printf "
${yellow}Usage:${reset_foreground}
  delete [options] <server-config-file> [<server-name> ...]

${yellow}Arguments:${reset_foreground}
  ${green}server-config-file${reset_foreground}  File containing every server information required to create and deploy a new release.
  ${green}server-name${reset_foreground}             Reduce the list of server define in the stage-config-file to the one listed. (${yellow}optional${reset_foreground})

${yellow}Options:${reset_foreground}
  ${green}-h, --help${reset_foreground}                    Display this help message
  ${green}-d, --deploy PATH${reset_foreground}             Specify the global deploy path containing /current, /releases and /shared
  ${green}-c, --current CURRENT_PATH${reset_foreground}    Specify the path of the current published version (incompatible with --deploy)
  ${green}-r, --releases RELEASES_PATH${reset_foreground}  Specify where every releases are stored (incompatible with --deploy)
  ${green}-s, --shared SHARED_PATH${reset_foreground}      Specify where every persistent files and directories are stored (incompatible with --deploy)
  ${green}-v|vv|vvv, --verbose${reset_foreground}          Increase the verbosity of messages: 1 for normal output, 2 for more verbose output and 3 for debug
"
}
readonly -f "delete_help"

function delete_usage
{
    declare -r green="\e[32m"
    declare -r yellow="\e[33m"
    declare -r reset_foreground="\e[39m"

    printf "${green}delete [-h|--help] [-v|vv|vvv|--verbose] [-d|--deploy PATH] [-c|--current CURRENT_PATH] [-r|--releases RELEASES_PATH] [-s|--shared SHARED_PATH] <server-config-file> [<server-name> ...]${reset_foreground}\n"
}
readonly -f "delete_usage"

function delete
{
    declare deploy_path
    declare current_path
    declare releases_path
    declare shared_path

    parse_delete_command_line "deploy_path" "current_path" "releases_path" "shared_path" "$@" && \
    ssh_test_connection && \
    action "Deleting application on servers" && \
    remote_exec_function "delete_application" "$deploy_path" "$current_path" "$releases_path" "$shared_path" || {
        declare -r -i return_code=$?

        printf "\n"
        delete_usage
        printf "\n"

        return ${return_code}
    }

    return 0
}
readonly -f "delete"
