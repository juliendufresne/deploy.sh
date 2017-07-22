#!/usr/bin/env bash

function extract_git_content
{
    do_not_run_twice || return $?
    reset_title_level
    display_title "Retrieving git archive"
    increase_title_level

    declare -r repository_path="$1"
    declare -r workspace="$2"
    declare -r revision="$3"

    is_verbose && printf "    revision: \e[32m${revision}\e[39m\n"

    is_debug && display_title "\e[33mgit --git-dir=\"$repository_path\" archive --format=tar \"$revision\"\e[39m"

    git --git-dir="$repository_path" archive --format=tar "$revision" | (cd "$workspace" && tar xf -) || {
        error "Something went wrong while retrieving git archive for object $revision"

        return 1
    }

    return 0
}
readonly -f "extract_git_content"
