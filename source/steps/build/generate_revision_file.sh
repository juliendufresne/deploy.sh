#!/usr/bin/env bash

function generate_revision_file
{
    do_not_run_twice || return $?
    reset_title_level
    display_title "Generating .REVISION file"
    increase_title_level

    declare -r workspace="$1"
    declare -r revision="$2"
    declare -r repository_path="$3"
    declare -r file="$workspace/.REVISION"
    declare -r output_file="$(mktemp -t deploy.XXXXXXXXXX)"
    declare -i return_code=0

    is_debug && display_title "\e[33mgit --git-dir=\"$repository_path\" --no-pager show --quiet \"$revision\"\e[39m"

    git --git-dir="$repository_path" --no-pager show --quiet "$revision" >"$file" 2>"$output_file" || {
        return_code=1
        error_with_output_file "$output_file" "Unable to create revision file $file."
    }

    [[ -f "$output_file" ]] && rm "$output_file"

    decrease_title_level

    return ${return_code}
}
readonly -f "generate_revision_file"
