#!/usr/bin/env bash

function create_archive_ensure_var_exists
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
readonly -f "create_archive_ensure_var_exists"

function create_archive
{
    do_not_run_twice || return $?
    ${VERBOSE} && display_title 1 "Creating archive"
    create_archive_ensure_var_exists || return $?

    declare -r workspace="$1"
    declare -r archive_dir="$2"
    declare -a tar_options=("--create" "--bzip2")
    ${DEBUG} && tar_options+=("--verbose")

    declare -r directory_name="$(basename "$workspace")"
    declare -r archive_file="$archive_dir/$directory_name.tar.bz2"
    ${VERY_VERBOSE} && printf "    archive: \e[32m$archive_file\e[39;49m\n"

    declare -r output_file="$(mktemp -t deploy.XXXXXXXXXX)"
    if ! [[ -d "$archive_dir" ]]
    then
        mkdir --parents "$archive_dir" &>"$output_file" || {
            error "Something went wrong while creating the archive directory $archive_dir"

            >&2 printf 'Following is the output of the command\n'
            >&2 printf '######################################\n'
            cat "$output_file"
            rm "$output_file"

            return 1
        }
    fi

    cd "${workspace}/.."
    tar "${tar_options[@]}" --file "$archive_file" "$directory_name" &>"$output_file" || {
        error "Something went wrong while creating the archive"

        >&2 printf 'Following is the output of the command\n'
        >&2 printf '######################################\n'
        cat "$output_file"
        rm "$output_file"
        cd "$OLDPWD"

        return 1
    }

    rm "$output_file"
    cd "$OLDPWD"

    return 0
}
readonly -f "create_archive"
