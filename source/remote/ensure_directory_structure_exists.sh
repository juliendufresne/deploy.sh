#!/usr/bin/env bash

function ensure_directory_structure_exists
{
    declare -r server_index=$1
    declare -r CURRENT_RELEASE_PATH="$2"
    declare -r RELEASES_ROOT_PATH="$3"
    declare -r SHARED_ROOT_PATH="$4"
    declare hostname
    get_hostname "hostname"

    if [[ -e "$CURRENT_RELEASE_PATH" ]] && ! [[ -h "$CURRENT_RELEASE_PATH" ]]
    then
        error "Server $hostname: File $CURRENT_RELEASE_PATH already exists and is not a symbolic link."

        return 1
    fi

    declare -r output_file="$(mktemp -t deploy.XXXXXXXXXX)"
    for directory in "$RELEASES_ROOT_PATH" "$SHARED_ROOT_PATH"
    do
        if [[ -e "$directory" ]] && ! [[ -d "$directory" ]]
        then
            error "Server $hostname: File $directory already exists and is not a directory."
            rm "$output_file"

            return 1
        fi

        if ! [[ -d "$directory" ]] && ! mkdir --parents "$directory" &>"$output_file"
        then
            error "Server $hostname: Unable to create directory $directory"

            >&2 printf 'Following is the output of the command\n'
            >&2 printf '######################################\n'
            >&2 cat "$output_file"
            rm "$output_file"

            return 1
        fi
    done

    rm "$output_file"

    return 0
}
