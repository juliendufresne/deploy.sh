#!/usr/bin/env bash

# -e: exit as soon as a command exit with a non-zero status code
# -u: prevent from any undefined variable
# -o pipefail: force pipelines to fail on the first non-zero status code
set -euo pipefail
# Avoid using space as a separator (default IFS=$' \t\n')
IFS=$'\n\t'

# include every tools here
include "tools/command_line_parse_single_option.sh"
include "tools/do_not_run_twice.sh"
include "tools/hook.sh"
include "tools/logger.sh"
include "tools/push_file_to_servers.sh"
include "tools/remote_exec.sh"
include "tools/resolve_option_with_env.sh"
include "tools/ssh_test_connection.sh"
include "tools/wrap_command.sh"

# includes every commands here
include "build.sh"
include "delete.sh"
include "deploy.sh"
include "release.sh"
include "rollback.sh"

# includes every steps for build command here
include "steps/build/create_archive.sh"
include "steps/build/create_workspace.sh"
include "steps/build/extract_git_content.sh"
include "steps/build/generate_revision_file.sh"
include "steps/build/parse_build_command_line.sh"

# includes every steps for delete command here
include "steps/delete/parse_delete_command_line.sh"

# includes every steps for release command here
include "steps/release/activate_release.sh"
include "steps/release/clean_old_releases.sh"
include "steps/release/ensure_directory_structure_exists.sh"
include "steps/release/ensure_shared_links_exists.sh"
include "steps/release/extract_archive.sh"
include "steps/release/finish_release.sh"
include "steps/release/link_release_with_shared_folder.sh"
include "steps/release/parse_release_command_line.sh"
include "steps/release/send_archive_to_servers.sh"

# includes every steps for rollback command here
include "steps/rollback/activate_previous_release.sh"
include "steps/rollback/clean_last_release.sh"
include "steps/rollback/find_previous_release.sh"
include "steps/rollback/finish_rollback.sh"
include "steps/rollback/parse_rollback_command_line.sh"

loader_finish


function display_main_help
{
    declare -r green="\e[32m"
    declare -r yellow="\e[33m"
    declare -r reset_foreground="\e[39m"
    printf "
deploy.sh

${yellow}Usage:${reset_foreground}
  command [options] [arguments]

${yellow}Options:${reset_foreground}
  ${green}-h, --help${reset_foreground}             Display this help message
  ${green}-q, --quiet${reset_foreground}            Disable output except for errors.
  ${green}-v|vv|vvv, --verbose${reset_foreground}   Increase the verbosity of messages: 1 for normal output, 2 for more verbose output and 3 for debug

${yellow}Available commands:${reset_foreground}
  ${green}build${reset_foreground}     Build a revision
  ${green}deploy${reset_foreground}    Create a release
  ${green}delete${reset_foreground}    Delete everything on remote server
  ${green}release${reset_foreground}   Release a built revision
  ${green}rollback${reset_foreground}  Rollback to previous released version
"
}
readonly -f "display_main_help"

function main
{
    do_not_run_twice
    declare command_name="deploy"

    declare -g VERBOSITY_LEVEL=0

    if [[ "$#" -ge 1 ]]
    then
        case "$1" in
            # if the first argument correspond to a command name, we shift it in order to pass clean options to the appropriate command
            "deploy"|"delete"|"build"|"release"|"rollback")
                command_name="$1"
                shift
                ;;
            *)
                # if no command name are specified, then a -h or --help option should output the main usage.
                # In case there is a command name specified, this is the job of the command to display its usage if required.
                for option in "$@"
                do
                    case "$option" in
                        -h|--help)
                            display_main_help

                            return 0
                        ;;
                    esac
                done
        esac
    fi

    # we can not change the $@ array outside of this function

    declare -a option_left=()
    for option in "$@"
    do
        case "$option" in
            -q|--quiet)
                VERBOSITY_LEVEL=-1
                ;;
            -v|--verbose)
                VERBOSITY_LEVEL=1
                ;;
            -vv)
                VERBOSITY_LEVEL=2
                ;;
            -vvv)
                VERBOSITY_LEVEL=3
                ;;
            *)
                option_left+=("$option")
        esac
    done
    set -- "${option_left[@]}"

    # deprecated. For compatibility only
    declare -g DEBUG=false
    [[ $VERBOSITY_LEVEL -eq 3 ]] && DEBUG=true
    declare -g VERY_VERBOSE=false
    [[ $VERBOSITY_LEVEL -ge 2 ]] && VERY_VERBOSE=true
    declare -g VERBOSE=false
    [[ $VERBOSITY_LEVEL -ge 1 ]] && VERBOSE=true

    case "$command_name" in
        "build")
            build "$@" || return $?
            ;;
        "delete")
            delete "$@" || return $?
            ;;
        "deploy")
            deploy "$@" || return $?
            ;;
        "release")
            release "$@" || return $?
            ;;
        "rollback")
            rollback "$@" || return $?
            ;;
        *)
            # should not be possible except if developer add a new command in the previous section and did not handle it here
            error "Unknown command $command_name"

            return 1
            ;;
    esac

    return 0
}
readonly -f "main"

main "$@"
