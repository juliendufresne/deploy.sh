#!/usr/bin/env bash

function extract_archive
{
    declare -r releases_path="$1"
    declare -r archive_filename="$2"
    declare -r release_name="$3"

    declare -r archive_dir="$(basename --suffix=.tar.bz2 "$archive_filename")"
    declare -r output_file="$(mktemp)"

    declare hostname
    get_hostname "hostname"

    cd "$releases_path" &>"$output_file" || {
        error "Server $hostname: Unable to enter release directory $releases_path."

        printf >&2 'Following is the output of the command\n'
        printf >&2 '######################################\n'
        cat "$output_file" >&2
        rm "$output_file"

        return "1"
    }

    tar --extract --file "$archive_filename" &>"$output_file" || {
        error "Server $hostname: Unable to extract archive $archive_filename."

        printf >&2 'Following is the output of the command\n'
        printf >&2 '######################################\n'
        cat "$output_file" >&2
        rm "$output_file"

        return "1"
    }

    if [[ "$archive_dir" != "$release_name" ]]
    then
        mv "$archive_dir" "$release_name" &>"$output_file" || {
            error "Server $hostname: Unable to move extracted archive $archive_dir in $release_name."
    
            printf >&2 'Following is the output of the command\n'
            printf >&2 '######################################\n'
            cat "$output_file" >&2
            rm "$output_file"
    
            return "1"
        }
    fi

    rm "$archive_filename" &>"$output_file" || {
        error "Server $hostname: Unable to remove archive $archive_filename."

        printf >&2 'Following is the output of the command\n'
        printf >&2 '######################################\n'
        cat "$output_file" >&2
        rm "$output_file"

        return "1"
    }

    rm "$output_file"

    return "0"
}
