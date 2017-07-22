#!/usr/bin/env bash

function create_workspace
{
    do_not_run_twice || return $?
    reset_title_level
    display_title "Creating workspace"
    increase_title_level

    declare -n workspace_dir="$1"
    declare -r revision="$2"

    _WORKSPACE_DIR="$(mktemp --directory --dry-run -t deploy.XXXXXXXXXX)"
    workspace_dir="$_WORKSPACE_DIR/$revision"

    is_verbose && printf "    workspace: \e[32m$workspace_dir\e[39m\n"

    if [[ -e "$workspace_dir" ]]
    then
        error "Unable to create workspace $workspace_dir. Directory already exists."

        return 1
    fi

    declare -a command=("mkdir" "--parents" "$workspace_dir")
    wrap_command "Unable to create directory $workspace_dir." "${command[@]}" || return $?

    return 0
}
readonly -f "create_workspace"
