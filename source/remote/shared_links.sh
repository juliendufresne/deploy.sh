#!/usr/bin/env bash

function ensure_shared_links_exists
{
    declare -r shared_directory="$1"
    shift

    if verify_shared_links "$shared_directory" true "$@"
    then
        return "0"
    fi

    call_hook "create_shared_links" "$shared_directory"

    if ! verify_shared_links "$shared_directory" false "$@"
    then
        printf >&2 "\nYou can create a function to handle shared link creation and add it using add_hook \"create_shared_links\" \"your_function_name\"\n"

        return "1"
    fi

    return "0"
}
readonly -f "ensure_shared_links_exists"

function verify_shared_links
{
    declare -r shared_directory="$1"
    declare -r safe_check="$2"
    declare hostname
    get_hostname "hostname"
    shift
    shift

    for item in "$@"
    do
        if ! [[ -e "$shared_directory/$item" ]]
        then
            ! ${safe_check} && error "Server $hostname: Shared item $shared_directory/$item does not exists."

            return "1"
        fi
    done

    return "0"
}
readonly -f "verify_shared_links"

function link_shared_to_release
{
    declare -r new_release_directory="$1"
    declare -r shared_directory="$2"
    declare current_item_parent_dir
    declare link_name
    declare hostname
    get_hostname "hostname"
    shift
    shift

    for item in "$@"
    do
        current_item_parent_dir="$(dirname "$item")"
        link_name="$(basename "$item")"

        if ! [[ -d "$new_release_directory/$current_item_parent_dir" ]]
        then
            mkdir --parents "$new_release_directory/$current_item_parent_dir" || {
                error "Server $hostname: Unable to create parent directory $new_release_directory/$current_item_parent_dir of shared item $item"

                return "1"
            }
        fi

        if [[ -e "$new_release_directory/$item" ]]
        then
            rm --recursive --preserve-root --force "$new_release_directory/$item" || {
                error "Server $hostname: Unable to remove shared item $item from release directory $new_release_directory"

                return "1"
            }
        fi

        cd "$new_release_directory/$current_item_parent_dir" && \
        ln --symbolic "$(realpath --relative-to="$new_release_directory/$current_item_parent_dir" "$shared_directory/$item")" "$link_name" || {
            error "Server $hostname: Unable to create link between shared item $item and release directory $new_release_directory"

            return "1"
        }
    done

    return "0"
}
readonly -f "link_shared_to_release"

function activate_release
{
    declare -r directory_to_current="$1"
    declare -r directory_to_sub_release="$2"
    declare hostname
    get_hostname "hostname"

    ln --no-dereference --force --symbolic "$directory_to_sub_release" "$directory_to_current" || {
        error "Server $hostname: Unable to activate the release"

        return "1"
    }
}
readonly -f "activate_release"
