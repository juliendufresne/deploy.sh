#!/usr/bin/env bash

function parse_build_command_line
{
    do_not_run_twice || return $?
    declare -n option_revision="$1"
    declare -n option_archive_dir="$2"
    declare -n option_repository_path="$3"
    declare -n option_repository_url="$4"
    declare option_config_file=""
    shift
    shift
    shift
    shift

    option_revision=""
    option_archive_dir=""
    option_repository_path=""
    option_repository_url=""
    declare -g DEBUG=false
    declare -g VERBOSE=false
    declare -g VERY_VERBOSE=false

    while [[ "$#" -gt 0 ]]
    do
        declare key="$1"
        case "$key" in
            -h|--help)
                display_build_help
                # this command must return 0 and stop execution.
                # But return 0 will not stop the execution
                exit "0"
                ;;
            -v|--verbose)
                VERBOSE=true
                ;;
            -vv)
                VERBOSE=true
                VERY_VERBOSE=true
                ;;
            -vvv)
                VERBOSE=true
                VERY_VERBOSE=true
                DEBUG=true
                ;;
            --archive-dir=*)
                command_line_parse_single_option "option --archive-dir" "option_archive_dir" "$option_archive_dir" "${1#*=}" || return $?
                ;;
            -a|--archive-dir)
                command_line_parse_single_option "option --archive-dir" "option_archive_dir" "$option_archive_dir" "${2:-}" || return $?
                shift
                ;;
            --config-file=*)
                command_line_parse_single_option "option --config-file" "option_config_file" "$option_config_file" "${1#*=}" || return $?
                ;;
            -f|--config-file)
                command_line_parse_single_option "option --config-file" "option_config_file" "$option_config_file" "${2:-}" || return $?
                shift
                ;;
            --repository-path=*)
                command_line_parse_single_option "option --repository-path" "option_repository_path" "$option_repository_path" "${1#*=}" || return $?
                ;;
            -p|--repository-path)
                command_line_parse_single_option "option --repository-path" "option_repository_path" "$option_repository_path" "${2:-}" || return $?
                shift
                ;;
            --repository-url=*)
                command_line_parse_single_option "option --repository-url" "option_repository_url" "$option_repository_url" "${1#*=}" || return $?
                ;;
            -u|--repository-url)
                command_line_parse_single_option "option --repository-url" "option_repository_url" "$option_repository_url" "${2:-}" || return $?
                shift
                ;;
            -*)
                error "Unknown option $1"

                return 1
                ;;
            *)
                command_line_parse_single_option "argument <revision>" "option_revision" "$option_revision" "$1" || return $?
                ;;
        esac
        shift
    done

    # this is - obviously - the only variable that can not be set in the config file
    [[ -z "$option_config_file" ]] && resolve_option_with_env "option_config_file" "DEPLOY_CONFIG_FILE"

    # first load the config file to get default variable values
    if [[ -n "$option_config_file" ]]
    then
        build_option_load_config_file "$option_config_file"
    fi

    # then fill empty var with environment variable
    [[ -z "$option_revision" ]] && resolve_option_with_env "option_revision" "DEPLOY_REVISION"
    [[ -z "$option_archive_dir" ]] && resolve_option_with_env "option_archive_dir" "DEPLOY_ARCHIVE_DIR"
    [[ -z "$option_repository_path" ]] && resolve_option_with_env "option_repository_path" "DEPLOY_REPOSITORY_PATH"
    [[ -z "$option_repository_url" ]] && resolve_option_with_env "option_repository_url" "DEPLOY_REPOSITORY_URL"
    ${VERBOSE} || resolve_option_with_env "VERBOSE" "DEPLOY_VERBOSE"
    ${VERY_VERBOSE} || resolve_option_with_env "VERY_VERBOSE" "DEPLOY_VERY_VERBOSE"
    ${DEBUG} || resolve_option_with_env "DEBUG" "DEPLOY_DEBUG"

    # finally, check that variable are good

    build_option_resolve_git_repository "$option_repository_path" "option_repository_url" || return $?
    build_option_resolve_revision "$option_repository_path" "$option_repository_url" "option_revision" || return $?
    build_option_resolve_archive_dir "option_archive_dir" || return $?

    if ${DEBUG}
    then
        declare -r green="\e[32m"
        declare -r yellow="\e[33m"
        declare -r reset_foreground="\e[39m"
        printf "
Resolved inputs
===============

    ${yellow}Arguments:${reset_foreground}
      ${green}revision${reset_foreground}                                 $option_revision
    
    ${yellow}Options:${reset_foreground}
      ${green}-a, --archive-dir=ARCHIVE_DIR${reset_foreground}            $option_archive_dir
      ${green}-f, --config-file=BUILD_CONFIG_FILE${reset_foreground}      $option_config_file
      ${green}-p, --repository-path=REPOSITORY_PATH${reset_foreground}    $option_repository_path
      ${green}-u, --repository-url=REPOSITORY_URL${reset_foreground}      $option_repository_url
      ${green}-v, --verbose${reset_foreground}                            $VERBOSE
      ${green}-vv${reset_foreground}                                      $VERY_VERBOSE
      ${green}-vvv${reset_foreground}                                     $DEBUG

"
    fi

    return 0
}
readonly -f "parse_build_command_line"

function build_option_load_config_file
{
    declare -r file="$1"

    if ! [[ -f "$file" ]]
    then
        error "option --config-file: file \"$file\" not found."

        return 1
    fi

    source "$file" || {
        error "option --config-file: Something went wrong while reading file \"$file\"."

        return 1
    }

    return 0
}
readonly -f "build_option_load_config_file"

function build_option_resolve_git_repository
{
    declare -r option_repository_path="$1"
    declare -n _ref_option_repository_url="$2"

    if [[ -z "$option_repository_path" ]]
    then
        error "You must define where to clone the repository in the build server."

        printf >&2 "
There are multiple ways to define it:
  - command line option ($0 deploy build --repository-path REPOSITORY_PATH)
  - define the variable before running the command (DEPLOY_REPOSITORY_PATH=\"your_path\" $0 deploy build)
  - export the variable once. It will be available for every deploy command (export DEPLOY_REPOSITORY_PATH=\"your_path\")
  - define the variable DEPLOY_REPOSITORY_PATH in your config file
"

        printf >&2 "\nNote: This option will also be used if the path correspond to a git server (initialised with --bare or --mirror).\n"

        return 1
    fi

    if [[ -z "$_ref_option_repository_url" ]]
    then
        if [[ "true" = "$(git --git-dir "$option_repository_path" rev-parse --is-bare-repository 2>/dev/null)" ]]
        then
            _ref_option_repository_url="$option_repository_path"
        else
            error "You must define the remote git repository." \
                  "This option defines the remote repository to use to clone/refresh the local repository."

            printf >&2 "
There are multiple ways to define it:
  - command line option ($0 deploy build --repository-url REPOSITORY_URL)
  - define the variable before running the command (DEPLOY_REPOSITORY_URL=\"git_url\" $0 deploy build)
  - export the variable once. It will be available for every deploy command (export DEPLOY_REPOSITORY_URL=\"git_url\")
  - define the variable DEPLOY_REPOSITORY_URL in your config file
"

            printf >&2 "\nNote: You can also use a local bare repository. In this case, create it and specify its path in the --repository-path option."

            return 1
        fi
    fi

    return 0
}
readonly -f "build_option_resolve_git_repository"

function build_option_resolve_revision
{
    declare -r option_repository_path="$1"
    declare -r option_repository_url="$2"
    declare -n _option_revision="$3"

    if [[ -z "$_option_revision" ]]
    then
        error "Missing argument <revision>"

        return 1
    fi

    # special case: the local repository is a bare repository so we trust its content
    if [[ "$option_repository_path" = "$option_repository_url" ]]
    then
        if ! git --git-dir "$option_repository_path" show-ref "$_option_revision" &>/dev/null
        then
            error "<revision>: The revision $_option_revision does not correspond to any commit, branch or tag in the repository."

            return 1
        fi

        _option_revision="$(git --git-dir "$option_repository_path" show-ref "$_option_revision" | head -n "1" | awk '{ print $1 }')"

        return 0
    fi

    if ! git ls-remote --exit-code --refs "$option_repository_url" "$_option_revision" &>/dev/null
    then

        # it may be caused by an unreachable git remote repository
        if ! git ls-remote --exit-code -h "$option_repository_url" &>/dev/null
        then
            error "The repository $option_repository_url is unreachable."
        else
            error "<revision>: The revision $_option_revision does not correspond to any commit, branch or tag in the repository."
        fi

        return 1
    fi

    _option_revision="$(git ls-remote --exit-code --refs "$option_repository_url" "$_option_revision" | head -n "1" | awk '{ print $1 }')"

    return 0
}
readonly -f "build_option_resolve_revision"

function build_option_resolve_archive_dir
{
    declare -n _ref="$1"

    if [[ -z "$_ref" ]]
    then
        _ref="$(mktemp --directory --dry-run)"
    fi

    return 0
}
readonly -f "build_option_resolve_archive_dir"
