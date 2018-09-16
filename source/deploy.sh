#!/usr/bin/env bash

function display_deploy_help
{
    declare -r green="\e[32m"
    declare -r yellow="\e[33m"
    declare -r reset_foreground="\e[39m"

    printf "
${yellow}Usage:${reset_foreground}
  deploy [options] <config-file> <revision> [<server-name> ...]

${yellow}Arguments:${reset_foreground}
  ${green}config-file${reset_foreground}    Configuration file used both for build and release
  ${green}revision${reset_foreground}       A commit, branch or tag.
  ${green}server-name${reset_foreground}    Reduce the list of server define in the stage-config-file to the one listed. (${yellow}optional${reset_foreground})

${yellow}Options:${reset_foreground}
  ${green}-h, --help${reset_foreground}             Display this help message
  ${green}-p, --repository-path=REPOSITORY_PATH${reset_foreground}    Path of a config file containing extra build action.
  ${green}-u, --repository-url=REPOSITORY_URL${reset_foreground}      Path of a config file containing extra build action.
  ${green}-d, --deploy PATH${reset_foreground}             Specify the global deploy path containing /current, /releases and /shared
  ${green}-c, --current CURRENT_PATH${reset_foreground}    Specify the path of the current published version (incompatible with --deploy)
  ${green}-r, --releases RELEASES_PATH${reset_foreground}  Specify where every releases are stored (incompatible with --deploy)
  ${green}-s, --shared SHARED_PATH${reset_foreground}      Specify where every persistent files and directories are stored (incompatible with --deploy)
  ${green}-q, --quiet${reset_foreground}                              Disable output except for errors.
  ${green}-v|vv|vvv, --verbose${reset_foreground}   Increase the verbosity of messages: 1 for normal output, 2 for more verbose output and 3 for debug
"
}
readonly -f "display_deploy_help"

function deploy_usage
{
    declare -r green="\e[32m"
    declare -r yellow="\e[33m"
    declare -r reset_foreground="\e[39m"

    printf "${green}deploy [-h|--help] [-q|--quiet] [-v|vv|vvv|--verbose] [-p|--repository-path REPOSITORY_PATH] [-u|--repository-url REPOSITORY_URL] [-d|--deploy PATH] [-c|--current CURRENT_PATH] [-r|--releases RELEASES_PATH] [-s|--shared SHARED_PATH] <config-file> <revision> [<server-name> ...]${reset_foreground}\n"
}
readonly -f "deploy_usage"

function deploy
{
    do_not_run_twice || return $?
    declare -r archive_dir="$(mktemp -d)"
    declare -a build_options=("--archive-dir" "$archive_dir")
    declare -a release_options=()
    declare -a option_filter_server=()

    case "${VERBOSITY_LEVEL}" in
        -1)
            build_options+=("-q")
            release_options+=("-q")
            ;;
        1)
            build_options+=("-v")
            release_options+=("-v")
            ;;
        2)
            build_options+=("-vv")
            release_options+=("-vv")
            ;;
        3)
            build_options+=("-vvv")
            release_options+=("-vvv")
        ;;
    esac

    declare -i current_argument_number="0"
    while [[ "$#" -gt 0 ]]
    do
        declare key="$1"
        case "$key" in
            -h|--help)
                display_deploy_help
                # this command must return 0 and stop execution.
                # But return 0 will not stop the execution
                exit "0"
                ;;
            --repository-path=*)
                build_options+=("--repository-path" "${1#*=}")
                ;;
            -p|--repository-path)
                build_options+=("--repository-path" "${2:-}")
                shift
                ;;
            --repository-url=*)
                build_options+=("--repository-url" "${1#*=}")
                ;;
            -u|--repository-url)
                build_options+=("--repository-url" "${2:-}")
                shift
                ;;
            --deploy=*)
                release_options+=("--deploy" "${1#*=}")
                ;;
            -d|--deploy)
                release_options+=("--deploy" "${2:-}")
                shift
                ;;
            --current=*)
                release_options+=("--current" "${1#*=}")
                ;;
            -c|--current)
                release_options+=("--current" "${2:-}")
                shift
                ;;
            --releases=*)
                release_options+=("--releases" "${1#*=}")
                ;;
            -r|--releases)
                release_options+=("--releases" "${2:-}")
                shift
                ;;
            --shared=*)
                release_options+=("--shared" "${1#*=}")
                ;;
            -s|--shared)
                release_options+=("--shared" "${2:-}")
                shift
                ;;
            -*)
                error "Unknown option $1"
                deploy_usage

                return 1
                ;;
            *)
                current_argument_number="$((current_argument_number + 1))"
                case "$current_argument_number" in
                    1)
                        build_options+=("--config-file" "$1")
                        release_options+=("$1")
                        ;;
                    2)
                        build_options+=("$1")
                        ;;
                    *)
                        option_filter_server+=("$1")
                        ;;
                esac
                ;;
        esac
        shift
    done

    section "Building revision"

    DEPLOY_SHOW_USAGE_ON_ERROR=false $0 build "${build_options[@]}" || {
        declare -r -i return_code=$?

        printf "\n"
        deploy_usage
        printf "\n"

        rm --recursive --preserve-root --interactive=never "$archive_dir"

        return ${return_code}
    }

    section_done "revision built"

    # get the archive
    release_options+=("$archive_dir/$(ls -1 "$archive_dir")")
    if [[ "${#option_filter_server[@]}" -gt 0 ]]
    then
        release_options+=("${option_filter_server[@]}")
    fi

    section "Releasing"

    DEPLOY_SHOW_USAGE_ON_ERROR=false $0 release "${release_options[@]}" || {
        declare -r -i return_code=$?

        printf "\n"
        deploy_usage
        printf "\n"

        rm --recursive --preserve-root --interactive=never "$archive_dir"

        return ${return_code}
    }

    section_done "Release done"

    rm --recursive --preserve-root --interactive=never "$archive_dir"

    return 0
}
readonly -f "deploy"
