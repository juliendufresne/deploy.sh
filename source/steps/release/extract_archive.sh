#!/usr/bin/env bash

function extract_archive
{
    declare -r releases_path="$1"
    declare -r archive="$2"
    declare -r release_date="$3"
    declare -r archive_filename="$(basename "$archive")"

    ${VERBOSE} && display_title 1 "Extracting archive"

    # Archive will be extracted on every server but may fail on one server. we should remove extracted archive
    DEPLOY_CURRENT_RELEASE_DIR="$releases_path/$release_date"
    remote_exec_function "extract_archive" "$releases_path" "$archive_filename" "$release_date" || return $?
    call_remote_hook "post_extract_archive" "$releases_path/$release_date" || return $?

    return 0
}
readonly -f "extract_archive"
