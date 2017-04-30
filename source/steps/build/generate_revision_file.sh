#!/usr/bin/env bash

function generate_revision_file_ensure_var_exists
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
readonly -f "generate_revision_file_ensure_var_exists"

function generate_revision_file
{
    do_not_run_twice || return "$?"
    ${VERBOSE} && action "Generating .REVISION file"
    generate_revision_file_ensure_var_exists || return "$?"

    declare -r workspace="$1"
    declare -r revision="$2"
    declare -r file="$workspace/.REVISION"
    declare -r output_file="$(mktemp)"

    printf "%s\n" "$revision" > "$file" 2>"$output_file" || {
        error "Unable to create revision file $file."

        printf >&2 'Following is the output of the command\n'
        printf >&2 '######################################\n'
        cat "$output_file"
        rm "$output_file"

        return "1"
    }
    rm "$output_file"

    return "0"
}

readonly -f "generate_revision_file"
