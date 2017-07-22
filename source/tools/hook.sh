#!/usr/bin/env bash

function init_custom_hooks
{
    if ! declare -p CUSTOM_HOOKS 2>/dev/null | grep -q "^declare \-A"
    then
        # list of custom hooks ["hook_name" => "function_name_1;function_name_2;..."
        declare -A -g CUSTOM_HOOKS=()
        CUSTOM_HOOKS["build"]=""
        CUSTOM_HOOKS["create_shared_links"]=""
        CUSTOM_HOOKS["pre_send_archive_to_servers"]=""
        CUSTOM_HOOKS["post_extract_archive"]=""
        CUSTOM_HOOKS["post_link_release_with_shared_folder"]=""
        CUSTOM_HOOKS["post_activate_release"]=""
        CUSTOM_HOOKS["post_release"]=""
        CUSTOM_HOOKS["pre_activate_previous_release"]=""
        CUSTOM_HOOKS["post_activate_previous_release"]=""
        CUSTOM_HOOKS["post_rollback"]=""
    fi

    return 0
}
readonly -f "init_custom_hooks"

#
# Usage: add_hook <hook_name> user_defined_function_name_1 [user_defined_function_name_2 ...]
#
function add_hook
{
    # example: pre_generate_revision_file
    declare -r hook_name="$1"
    shift

    init_custom_hooks || return $?
    check_hook_name "$hook_name" || return $?

    for user_defined_function_name in "$@"
    do
        if [[ "${#CUSTOM_HOOKS["$hook_name"]}" -gt 0 ]]
        then
            CUSTOM_HOOKS["$hook_name"]="${CUSTOM_HOOKS[$hook_name]};$user_defined_function_name"
        else
            CUSTOM_HOOKS["$hook_name"]="$user_defined_function_name"
        fi
    done
}
readonly -f "add_hook"

#
# Usage: call_hook <hook-name> [parameter_1 ...]
#
function call_hook
{
    declare -r hook_name="$1"
    declare -i return_code=0
    shift

    init_custom_hooks || return $?
    check_hook_name "$hook_name" || return $?

    if [[ "${#CUSTOM_HOOKS[$hook_name]}" -eq 0 ]]
    then
        return 0
    fi

    display_title "Hook \e[32m$hook_name\e[39m"
    increase_title_level
    IFS=";" read -ra hooks <<< "${CUSTOM_HOOKS[$hook_name]}"

    for user_defined_function_name in "${hooks[@]}"
    do
        check_user_defined_function_exists "$user_defined_function_name" || return $?
        ${user_defined_function_name} "$@" || {
            return_code=$?
            error "hook $hook_name: Something went wrong while calling function named $user_defined_function_name"

            return ${return_code}
        }
    done

    decrease_title_level

    return 0
}
readonly -f "call_hook"

#
# Usage: call_hook <hook-name> [parameter_1 ...]
#
function call_remote_hook
{
    declare -r hook_name="$1"
    declare -r fail_on_first_error="$2"
    declare -i return_code=0
    shift
    shift

    init_custom_hooks || return $?
    check_hook_name "$hook_name" || return $?

    if [[ "${#CUSTOM_HOOKS[$hook_name]}" -eq 0 ]]
    then
        return 0
    fi

    display_title "Hook \e[32m$hook_name\e[39m"
    increase_title_level

    IFS=";" read -ra hooks <<< "${CUSTOM_HOOKS[$hook_name]}"

    for user_defined_function_name in "${hooks[@]}"
    do
        remote_exec_function "$user_defined_function_name" "$@" || {
            return_code=$?
            error "hook $hook_name: Something went wrong while calling function named $user_defined_function_name"

            if ${fail_on_first_error}
            then
                return ${return_code}
            fi
        }
    done
    decrease_title_level

    return ${return_code}
}
readonly -f "call_remote_hook"

function check_hook_name
{
    declare -r hook_name="$1"

    if ! [[ "${CUSTOM_HOOKS[$hook_name]+exists}" ]]
    then
        error "${FUNCNAME[1]}: Unknown hook name '$hook_name'"

        return 1
    fi

    return 0
}
readonly -f "check_hook_name"

function check_user_defined_function_exists
{
    declare -r user_defined_function_name="$1"

    if ! type -t "$user_defined_function_name" | grep -q ^function$
    then
        error "${FUNCNAME[1]}: Unknown function name '$user_defined_function_name'"

        return 1
    fi

    return 0
}
readonly -f "check_user_defined_function_exists"
