#!/usr/bin/env bash

function extract_archive
{
    declare -r server_index=$1
    declare -r releases_path="$2"
    declare -r archive_filename="$3"
    declare -r release_name="$4"

    declare -r archive_dir="$(basename --suffix=.tar.bz2 "$archive_filename")"
    declare -r output_file="$(mktemp -t deploy.XXXXXXXXXX)"

    declare hostname
    get_hostname "hostname"

    cd "$releases_path" &>"$output_file" || {
        error "Server $hostname: Unable to enter release directory $releases_path."

        >&2 printf 'Following is the output of the command\n'
        >&2 printf '######################################\n'
        >&2 cat "$output_file"
        rm "$output_file"

        return 1
    }

    tar --extract --file "$archive_filename" &>"$output_file" || {
        error "Server $hostname: Unable to extract archive $archive_filename."

        >&2 printf 'Following is the output of the command\n'
        >&2 printf '######################################\n'
        >&2 cat "$output_file"
        rm "$output_file"

        return 1
    }

    if [[ "$archive_dir" != "$release_name" ]]
    then
        mv "$archive_dir" "$release_name" &>"$output_file" || {
            error "Server $hostname: Unable to move extracted archive $archive_dir in $release_name."
    
            >&2 printf 'Following is the output of the command\n'
            >&2 printf '######################################\n'
            >&2 cat "$output_file"
            rm "$output_file"
    
            return 1
        }
    fi

    rm "$archive_filename" &>"$output_file" || {
        error "Server $hostname: Unable to remove archive $archive_filename."

        >&2 printf 'Following is the output of the command\n'
        >&2 printf '######################################\n'
        >&2 cat "$output_file"
        rm "$output_file"

        return 1
    }

    rm "$output_file"

    return 0
}
