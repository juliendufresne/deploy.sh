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

            return 1
        fi
    done

    return 0
}
readonly -f "generate_revision_file_ensure_var_exists"

function generate_revision_file
{
    do_not_run_twice || return $?
    ${VERBOSE} && display_title 1 "Generating .REVISION file"
    generate_revision_file_ensure_var_exists || return $?

    declare -r workspace="$1"
    declare -r revision="$2"
    declare -r repository_path="$3"
    declare -r file="$workspace/.REVISION"
    declare -r output_file="$(mktemp -t deploy.XXXXXXXXXX)"
    declare -i return_code=0

    cd "$repository_path"
    git --no-pager show --quiet "$revision" > "$file" 2>"$output_file" || {
        return_code=1
        error "Unable to create revision file $file."

        >&2 printf 'Following is the output of the command\n'
        >&2 printf '######################################\n'
        cat "$output_file"
    }

    rm "$output_file"
    cd "$OLDPWD"

    return ${return_code}
}

readonly -f "generate_revision_file"
