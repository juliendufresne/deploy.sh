#!/usr/bin/env bash

function wrap_command
{
    declare -r error_message="$1"
    declare -r command_name="$2"
    shift
    shift

    if is_verbose
    then
        if is_debug
        then
            declare title="$command_name"
            for args in $@
            do
                title="$title $args"
            done

            display_title "\e[33m$title\e[39m"
        fi

        ${command_name} "$@" || {
            error "$error_message"

            return 1
        }
    else
        declare -r output_file="$(mktemp -t deploy.XXXXXXXXXX)"
        ${command_name} "$@" &>"$output_file" || {
            error_with_output_file "$output_file" "$error_message"

            return 1
        }
        rm "$output_file"
    fi

    return 0
}
readonly -f "wrap_command"
