#!/usr/bin/env bash

function send_archive_to_servers
{
    declare -r releases_path="$1"
    declare -r archive="$2"
    declare -r archive_filename="$(basename "$archive")"

    ${VERBOSE} && display_title 1 "Sending archive"

    call_hook "pre_send_archive_to_servers" "$archive" || return $?
    push_file_to_servers "$archive" "$releases_path/$archive_filename" || return $?

    return 0
}

readonly -f "send_archive_to_servers"
