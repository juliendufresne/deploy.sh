#!/usr/bin/env bash

function parse_delete_command_line
{
    do_not_run_twice || return "$?"

    declare -n option_deploy_path="$1"
    declare -n option_current_path="$2"
    declare -n option_releases_path="$3"
    declare -n option_shared_path="$4"
    declare option_config_file=""
    declare -a option_filter_server=("") # empty to avoid unbound variable errors

    shift
    shift
    shift
    shift

    option_deploy_path=""
    option_current_path=""
    option_releases_path=""
    option_shared_path=""
    declare -g DEBUG=false
    declare -g VERBOSE=false
    declare -g VERY_VERBOSE=false

    declare -i current_argument_number="0"

    while [[ "$#" -gt 0 ]]
    do
        declare key="$1"
        case "$key" in
            -h|--help)
                display_release_help
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
            --deploy=*)
                command_line_parse_single_option "option --deploy" "option_deploy_path" "$option_deploy_path" "${1#*=}" || return "$?"
                ;;
            -d|--deploy)
                command_line_parse_single_option "option --deploy" "option_deploy_path" "$option_deploy_path" "${2:-}" || return "$?"
                shift
                ;;
            --current=*)
                command_line_parse_single_option "option --current" "option_current_path" "$option_current_path" "${1#*=}" || return "$?"
                ;;
            -c|--current)
                command_line_parse_single_option "option --current" "option_current_path" "$option_current_path" "${2:-}" || return "$?"
                shift
                ;;
            --releases=*)
                command_line_parse_single_option "option --releases" "option_releases_path" "$option_releases_path" "${1#*=}" || return "$?"
                ;;
            -r|--releases)
                command_line_parse_single_option "option --releases" "option_releases_path" "$option_releases_path" "${2:-}" || return "$?"
                shift
                ;;
            --shared=*)
                command_line_parse_single_option "option --shared" "option_shared_path" "$option_shared_path" "${1#*=}" || return "$?"
                ;;
            -s|--shared)
                command_line_parse_single_option "option --shared" "option_shared_path" "$option_shared_path" "${2:-}" || return "$?"
                shift
                ;;
            -*)
                error "Unknown option $1"

                return "1"
                ;;
            *)
                current_argument_number="$((current_argument_number + 1))"
                case "$current_argument_number" in
                    1)
                        command_line_parse_single_option "argument <server-config-file>" "option_config_file" "$option_config_file" "$1" || return "$?"
                        ;;
                    *)
                        option_filter_server+=("$1")
                        ;;
                esac
                ;;
        esac
        shift
    done

    # this is - obviously - the only variable that can not be set in the config file
    [[ -z "$option_config_file" ]] && resolve_option_with_env "option_config_file" "DEPLOY_CONFIG_FILE"
    delete_option_load_config_file "$option_config_file" || return "$?"
    ${VERBOSE} || resolve_option_with_env "VERBOSE" "DEPLOY_VERBOSE"
    ${VERY_VERBOSE} || resolve_option_with_env "VERY_VERBOSE" "DEPLOY_VERY_VERBOSE"
    ${DEBUG} || resolve_option_with_env "DEBUG" "DEPLOY_DEBUG"

    [[ -z "$option_deploy_path" ]] && resolve_option_with_env "option_deploy_path" "DEPLOY_PATH"
    [[ -z "$option_current_path" ]] && resolve_option_with_env "option_current_path" "DEPLOY_CURRENT_PATH"
    [[ -z "$option_releases_path" ]] && resolve_option_with_env "option_releases_path" "DEPLOY_RELEASES_PATH"
    [[ -z "$option_shared_path" ]] && resolve_option_with_env "option_shared_path" "DEPLOY_SHARED_PATH"
    delete_option_validate_paths "$option_deploy_path" "option_current_path" "option_releases_path" "option_shared_path" || return "$?"

    delete_option_validate_servers "${option_filter_server[@]}" || return "$?"
    delete_option_validate_connect_option || return "$?"

    if ${DEBUG}
    then
        declare -r green="\e[32m"
        declare -r yellow="\e[33m"
        declare -r reset_foreground="\e[39m"
        printf "
Resolved inputs
===============

    ${yellow}Arguments:${reset_foreground}
      ${green}stage-config-file${reset_foreground}       $option_config_file
        ${green}DEPLOY_SERVER_LIST${reset_foreground}    $(declare -p FILTERED_DEPLOY_SERVER_LIST | sed -e "s/declare -A FILTERED_DEPLOY_SERVER_LIST='(//" -e "s/)'$//")
        ${green}DEPLOY_SHARED_ITEMS${reset_foreground}   $(declare -p DEPLOY_SHARED_ITEMS | sed -e "s/declare -[aA] DEPLOY_SHARED_ITEMS='(//" -e "s/)'$//")

    ${yellow}Options:${reset_foreground}
      ${green}-d, --deploy PATH${reset_foreground}             $option_deploy_path
      ${green}-c, --current CURRENT_PATH${reset_foreground}    $option_current_path
      ${green}-r, --releases RELEASES_PATH${reset_foreground}  $option_releases_path
      ${green}-s, --shared SHARED_PATH${reset_foreground}      $option_shared_path
      ${green}-v, --verbose${reset_foreground}                 $VERBOSE
      ${green}-vv${reset_foreground}                           $VERY_VERBOSE
      ${green}-vvv${reset_foreground}                          $DEBUG

"
    fi

    return "0"
}
readonly -f "parse_delete_command_line"

function delete_option_load_config_file
{
    declare -r file="$1"

    if [[ -z "$file" ]]
    then
        error "Missing required argument <config-file>"
        return "1"
    fi

    if ! [[ -f "$file" ]]
    then
        error "argument <config-file>: file \"$file\" not found."

        return "1"
    fi

    source "$file" || {
        error "argument <config-file>: Something went wrong while reading file \"$file\"."

        return "1"
    }
    # In case config file has unset those variables
    [[ -v VERBOSE ]] || VERBOSE=false
    [[ -v VERY_VERBOSE ]] || VERY_VERBOSE=false
    [[ -v DEBUG ]] || DEBUG=false

    return "0"
}
readonly -f "delete_option_load_config_file"

function delete_option_validate_paths
{
    declare -r deploy_path="$1"
    declare -n current="$2"
    declare -n releases="$3"
    declare -n shared="$4"

    if [[ -n "$deploy_path" ]]
    then
        if [[ -n "$current" ]] || [[ -n "$releases" ]] || [[ -n "$shared" ]]
        then
            error "Can not specify both the global --deploy path and a specific path (--current, --releases or --shared)"

            return "1"
        fi

        current="$deploy_path/current"
        releases="$deploy_path/releases"
        shared="$deploy_path/shared"

        return "0"
    fi

    if [[ -z "$current" ]] || [[ -z "$releases" ]] || [[ -z "$shared" ]]
    then
        error "Unable to guess on which folders to deploy to."

        return "1"
    fi

    return "0"
}
readonly -f "delete_option_validate_paths"

function delete_option_validate_servers
{
    declare -A filtered_server_list=()

    if ! declare -p DEPLOY_SERVER_LIST 2>/dev/null | grep -q "^declare \-[aA]" || [[ "${#DEPLOY_SERVER_LIST[@]}" -eq 0 ]]
    then
        error "No server specified." \
              "Your config file must define a DEPLOY_SERVER_LIST variable." \
              "This variable must be an array."

        printf >&2 "\nTIPS: for better output, define an associative variable like so:
  declare -Ag DEPLOY_SERVER_LIST=([\"server 1\"]=\"user@server1\" [\"server 2\"]=\"user@server2\")
"

        return "1"
    fi

    for filtered_server_index in "$@"
    do
        if [[ -z "$filtered_server_index" ]]
        then
            continue
        fi
        if ! [[ "${DEPLOY_SERVER_LIST["$filtered_server_index"]+exists}" ]]
        then
            error "Server name \"$filtered_server_index\" does not exists in DEPLOY_SERVER_LIST"

            return "1"
        fi
        filtered_server_list["$filtered_server_index"]="${DEPLOY_SERVER_LIST[$filtered_server_index]}"
    done

    declare -Ag FILTERED_DEPLOY_SERVER_LIST=()
    if [[ "${#filtered_server_list[@]}" -gt 0 ]]
    then
        for key in "${!filtered_server_list[@]}"
        do
            FILTERED_DEPLOY_SERVER_LIST["$key"]="${filtered_server_list["$key"]}"
        done
    else
        for key in "${!DEPLOY_SERVER_LIST[@]}"
        do
            FILTERED_DEPLOY_SERVER_LIST["$key"]="${DEPLOY_SERVER_LIST["$key"]}"
        done
    fi

    return "0"
}
readonly -f "delete_option_validate_servers"

function delete_option_validate_connect_option
{
    ! [[ -v DEPLOY_SSH_OPTIONS ]] && declare -ag DEPLOY_SSH_OPTIONS=()
    ! [[ -v DEPLOY_RSYNC_OPTIONS ]] && declare -ag DEPLOY_RSYNC_OPTIONS=()

    for option in "DEPLOY_SSH_OPTIONS" "DEPLOY_RSYNC_OPTIONS"
    do
        if ! declare -p "$option" 2>/dev/null | grep -q "^declare \-[aA]"
        then
            error "$option must be an array."

            return "1"
        fi
    done

    return "0"
}
readonly -f "delete_option_validate_connect_option"
