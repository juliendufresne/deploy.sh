#!/usr/bin/env bash

function extract_git_content_ensure_var_exists
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
readonly -f "extract_git_content_ensure_var_exists"

function extract_git_content
{
    do_not_run_twice || return $?
    ${VERBOSE} && action "Retrieving git archive"
    extract_git_content_ensure_var_exists || return $?

    declare -r repository_path="$1"
    declare -r workspace="$2"
    declare -r revision="$3"

    ${VERY_VERBOSE} && action="    revision: \e[32m${revision}\e[39;49m"

    git --git-dir="$repository_path" archive --format=tar "$revision" | (cd "$workspace" && tar xf -) || {
        error "Something went wrong while retrieving git archive for object $revision"

        return 1
    }

    return 0
}

readonly -f "extract_git_content"
