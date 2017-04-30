#!/usr/bin/env bash

function refresh_local_repository_ensure_var_exists
{
    for defined_variable_name in "VERBOSE" "VERY_VERBOSE" "DEBUG"
    do
        if ! [[ -v "$defined_variable_name" ]]
        then
            VERBOSE=
            VERY_VERBOSE=
            DEBUG=
            error "Something unexpected happened: $defined_variable_name should be defined"

            return "1"
        fi
    done

    return "0"
}
readonly -f "refresh_local_repository_ensure_var_exists"

function refresh_local_repository
{
    do_not_run_twice || return "$?"
    ${VERBOSE} && action "Refreshing local repository"
    refresh_local_repository_ensure_var_exists || return "$?"

    declare -r repository_path="$1"
    declare -r repository_url="$2"

    # no need to update a repository
    if [[ "$repository_path" = "$repository_url" ]]
    then
        return "0"
    fi

    ${VERY_VERBOSE} && printf "    repository: \e[32m$repository_path\e[39;49m\n"

    declare -r output_file="$(mktemp)"
    if ! [[ -d "$repository_path" ]]
    then
        ${VERY_VERBOSE} && sub_action "fresh clone"
        git clone --quiet --mirror "$repository_url" "$repository_path" &>"$output_file" || {
            error "Unable to clone from remote repository $repository_url"

            printf >&2 'Following is the output of the command\n'
            printf >&2 '######################################\n'
            cat "$output_file" >&2
            rm "$output_file"

            return "1"
        }
    fi

    ${VERY_VERBOSE} && sub_action "remote update"
    git --git-dir="$repository_path" remote update &>"$output_file" || {
        error "Unable to refresh git repository from remote $repository_url"

        printf >&2 'Following is the output of the command\n'
        printf >&2 '######################################\n'
        cat "$output_file" >&2
        rm "$output_file"

        return "1"
    }

    rm "$output_file"

    return "0"
}
readonly -f "refresh_local_repository"
