#!/usr/bin/env bash

function create_archive
{
    declare -r workspace="$1"
    declare -r archive_dir="$2"
    declare -i return_code=0

    do_not_run_twice || return $?
    reset_title_level
    display_title "Creating archive"
    increase_title_level

    declare -r directory_name="$(basename "$workspace")"
    declare -r archive_file="$archive_dir/$directory_name.tar.bz2"

    is_verbose && printf "    archive: \e[32m$archive_file\e[39m\n"

    create_archive_directory "$archive_dir" && \
    do_create_archive "$workspace" "$archive_file" "$directory_name" || return_code=$?

    return ${return_code}
}
readonly -f "create_archive"

function create_archive_directory
{
    declare -r archive_dir="$1"

    if ! [[ -d "$archive_dir" ]]
    then
        is_debug && printf "archive directory does not exists. Creating it.\n"
        declare -a command=("mkdir" "--parents" "$archive_dir")
        wrap_command "Something went wrong while creating the archive directory $archive_dir" "${command[@]}" || return $?
    fi

    return 0
}
readonly -f "create_archive_directory"

function do_create_archive
{
    declare -r workspace="$1"
    declare -r archive_file="$2"
    declare -r directory_name="$3"
    declare -a tar_options=("--create" "--bzip2")
    is_debug && tar_options+=("--verbose")

    cd "${workspace}/.."
    declare -i return_code=0
    declare -a command=("tar" "${tar_options[@]}" "--file" "$archive_file" "$directory_name")
    wrap_command "Something went wrong while creating the archive" "${command[@]}" || {
        return_code=1
    }

    cd "$OLDPWD"
}
readonly -f "do_create_archive"
