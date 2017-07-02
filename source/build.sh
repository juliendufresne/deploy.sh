#!/usr/bin/env bash

#### PRIVATE VARIABLES ####
# declared globally so we can "trap" them on exit

declare -g _WORKSPACE_DIR=

function display_build_help
{
    declare -r green="\e[32m"
    declare -r yellow="\e[33m"
    declare -r reset_foreground="\e[39m"

    printf "
${yellow}Usage:${reset_foreground}
  build [options] <revision>

${yellow}Arguments:${reset_foreground}
  ${green}revision${reset_foreground}    A commit, branch or tag.

${yellow}Options:${reset_foreground}
Note: every options can be defined with environment variable with prefix DEPLOY_*
  ${green}-h, --help${reset_foreground}                               Display this help message
  ${green}-a, --archive-dir=ARCHIVE_DIR${reset_foreground}            Specify where to store the produced archive file
  ${green}-f, --config-file=CONFIG_FILE${reset_foreground}            Path of a config file containing extra build action.
  ${green}-p, --repository-path=REPOSITORY_PATH${reset_foreground}    Path of where to store local git repository.
  ${green}-u, --repository-url=REPOSITORY_URL${reset_foreground}      Url of remote repository.
  ${green}-v|vv|vvv, --verbose${reset_foreground}                     Increase the verbosity of messages: 1 for normal output, 2 for more verbose output and 3 for debug.
"
}
readonly -f "display_build_help"

function display_build_usage
{
    declare -r green="\e[32m"
    declare -r yellow="\e[33m"
    declare -r reset_foreground="\e[39m"

    printf "${green}build [-h|--help] [-v|vv|vvv|--verbose] [-a|--archive-dir ARCHIVE_DIR] [-f|--config-file CONFIG_FILE] [-p|--repository-path REPOSITORY_PATH] [-u|--repository-url REPOSITORY_URL] <revision>${reset_foreground}\n"
}
readonly -f "display_build_usage"

function build_cleanup
{
    # we don't want to stop execution on failure here because we clean up everything.
    set +e

    [[ -n "$_WORKSPACE_DIR" ]] && [[ -d "$_WORKSPACE_DIR" ]] && rm --recursive --preserve-root "$_WORKSPACE_DIR"
    # tarball
    [[ -f "$_WORKSPACE_DIR.tar.bz2" ]] && rm "$_WORKSPACE_DIR.tar.bz2"
}
readonly -f "build_cleanup"

function build
{
    do_not_run_twice || return $?

    trap build_cleanup INT TERM EXIT
    declare revision
    declare archive_dir
    declare repository_path
    declare repository_url
    declare workspace

    parse_build_command_line "revision" "archive_dir" "repository_path" "repository_url" "$@" && \
    refresh_local_repository "$repository_path" "$repository_url" && \
    create_workspace "workspace" "$revision" && \
    extract_git_content "$repository_path" "$workspace" "$revision" && \
    generate_revision_file "$workspace" "$revision" "$repository_path" && \
    call_hook "build" "$workspace" "$revision" && \
    create_archive "$workspace" "$archive_dir" || {
        declare -r -i return_code=$?

        printf "\n"
        display_build_usage
        printf "\n"

        return ${return_code}
    }

    return 0
}
readonly -f "build"
