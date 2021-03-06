#!/usr/bin/env bash

function finish_release
{
    declare -r archive_file="$1"
    declare -r revision_file="$(mktemp -t deploy.XXXXXXXXXX)"
    extract_revision_file_from_archive "$archive_file" "$revision_file"

    call_hook "post_release" "$revision_file"

    rm "$revision_file"

    return 0
}
readonly -f "finish_release"

function extract_revision_file_from_archive
{
    declare -r archive_file="$1"
    declare -r revision_file="$2"
    declare -r commit="$(basename --suffix=.tar.bz2 "${archive_file}")"
    declare -r output_file="$(mktemp -t deploy.XXXXXXXXXX)"
    declare -i return_code=0

    tar --extract --to-stdout --file "$archive_file" "$commit/.REVISION" > "$revision_file" 2>"$output_file" || {
        return_code=1
        error_with_output_file "$output_file" "Something went wrong while trying to get the .REVISION file from archive $archive_file"
    }

    rm "$output_file"

    return ${return_code}
}
readonly -f "extract_revision_file_from_archive"
