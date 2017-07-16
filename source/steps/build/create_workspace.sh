#!/usr/bin/env bash

function create_workspace_ensure_var_exists
{
    for defined_variable_name in "VERBOSE" "VERY_VERBOSE" "DEBUG"
    do
        if ! [[ -v "$defined_variable_name" ]]
        then
            VERBOSE=
            VERY_VERBOSE=
            DEBUG=
            error "Something unexpected happened: $defined_variable_name should be defined"

            return 1
        fi
    done

    return 0
}
readonly -f "create_workspace_ensure_var_exists"

function create_workspace
{
    do_not_run_twice || return $?
    ${VERBOSE} && display_title 1 "Creating workspace"
    create_workspace_ensure_var_exists || return $?

    declare -n workspace_dir="$1"
    declare -r revision="$2"

    _WORKSPACE_DIR="$(mktemp --directory --dry-run -t deploy.XXXXXXXXXX)"
    workspace_dir="$_WORKSPACE_DIR/$revision"

    ${VERY_VERBOSE} && printf "    workspace: \e[32m$workspace_dir\e[39m\n"

    if [[ -e "$workspace_dir" ]]
    then
        error "Unable to create workspace $workspace_dir. Directory already exists."

        return 1
    fi

    declare -r output_file="$(mktemp -t deploy.XXXXXXXXXX)"
    if ! mkdir --parents "$workspace_dir" &>"$output_file"
    then
        error "Unable to create directory $workspace_dir."

        >&2 printf 'Following is the output of the command\n'
        >&2 printf '######################################\n'
        cat "$output_file"
        rm "$output_file"

        return 1
    fi

    rm "$output_file"

    return 0
}
readonly -f "create_workspace"
