#!/usr/bin/env bash

function clean_last_release
{
    declare -r server_index=$1
    declare -r link_of_current_release="$2"
    declare -r releases_path="$3"
    declare -i return_code=0
    declare current_release_directory="$(readlink -f "$link_of_current_release")"
    declare hostname
    get_hostname "hostname"

    if [[ -z "$releases_path" ]] || ! [[ -d "$releases_path" ]]
    then
        error "Server $hostname: releases path '$releases_path' does not exists."
        cd "$OLDPWD"

        return 1
    fi

    cd "$releases_path"
    declare last_release="$(ls -1 | sort -rn | head -n 1)"

    # if last release is empty, we should not remove the releases directory (containing all the releases).
    if [[ -z "$last_release" ]]
    then
        error "Server $hostname: Unable to find a release."
        cd "$OLDPWD"

        return 1
    fi

    # only remove last release if it is not the current one
    if [[ "$last_release" = "${current_release_directory#$releases_path/}" ]]
    then
        error "Server $hostname: Can not remove last release. It is actually activated."
        cd "$OLDPWD"

        return 1
    fi

    declare -r output_file="$(mktemp -t deploy.XXXXXXXXXX)"
    rm --recursive --force --preserve-root "$releases_path/$last_release" || {
        return_code=1

        error_with_output_file "$output_file" "Server $hostname: Something went wrong while removing last release '$releases_path/$last_release'"
    }

    [[ -f "$output_file" ]] && rm "$output_file"
    cd "$OLDPWD"

    return ${return_code}
}
function clean_oldest_releases
{
    declare -r server_index=$1
    declare -r -i keep_releases="$2"
    declare -r release_directory="$3"
    declare -r link_of_current_release="$4"
    declare -a releases_to_keep=()
    declare -i return_code=0
    declare current_release_directory="$(readlink -f "$link_of_current_release")"
    declare hostname
    get_hostname "hostname"

    # only add "current" directory if it exists and is in the releases directory
    if [[ -d "$current_release_directory" ]] && [[ "${current_release_directory#$release_directory/}" != "$current_release_directory" ]]
    then
        current_release_directory="${current_release_directory#$release_directory/}"
    else
        current_release_directory=""
    fi

    cd "$release_directory"
    if [[ -d "$current_release_directory" ]]
    then
        releases_to_keep+=("$current_release_directory")
    fi

    while read directory
    do
        # skip no release looking items
        if ! echo "$directory" | grep --quiet --extended-regexp "^[0-9]{14}$"
        then
            continue
        fi

        # check if directory is already listed in the releases to keep (current release)
        for d in "${releases_to_keep[@]}"
        do
            if [[ "$d" = "$directory" ]]
            then
                continue "2"
            fi
        done

        if [[ "${#releases_to_keep[@]}" -lt "$keep_releases" ]]
        then
            releases_to_keep+=("$directory")
            continue
        fi

        rm --recursive --preserve-root "$directory" || {
            return_code=$?
            error "Server $hostname: Unable to remove release $directory."
        }
    done < <(ls -1 --directory */ | sed 's/\/$//' | sort --general-numeric-sort --reverse)

    cd "$OLDPWD"

    return ${return_code}
}

function find_previous_release
{
    declare -r releases_path="$1"
    declare -i return_code=0
    declare hostname
    get_hostname "hostname"

    if [[ -z "$releases_path" ]] || ! [[ -d "$releases_path" ]]
    then
        error "Server $hostname: releases path '$releases_path' does not exists."

        return 1
    fi

    cd "$releases_path"
    # show one directory per line, sort numerically reversed, get the first 2 elements and finally the last one
    ls -1 | sort -rn | head -n 2 | tail -n 1

    return ${return_code}
}

function show_previous_release
{
    declare -r server_index="$1"
    declare -r releases_path="$2"
    declare -i release_index=1
    declare hostname
    get_hostname "hostname"

    if [[ -z "$releases_path" ]] || ! [[ -d "$releases_path" ]]
    then
        error "Server $hostname: releases path '$releases_path' does not exists."

        return 1
    fi

    printf "  Server %s\n" "$hostname"
    cd "$releases_path"
    # show one directory per line, sort numerically reversed
    for release in $(ls -1 | sort -rn)
    do
        if [[ "$release_index" -eq 2 ]]
        then
            printf "\e[1m* %s\e[0m\n" "$release"
        else
            printf "  %s\n" "$release"
        fi
        if [[ "$release_index" -eq 3 ]]
        then
            break
        fi
        release_index=$((release_index + 1))
    done

    printf "\n\n"

    return 0
}

function remove_currently_deployed_release
{
    declare -r server_index="$1"
    declare -r current_release_path="$2"
    declare -i return_code=0
    declare hostname
    get_hostname "hostname"

    if [[ -z "$current_release_path" ]] || ! [[ -d "$current_release_path" ]]
    then
        return 0
    fi

    rm --recursive --preserve-root "$current_release_path" || {
        return_code=$?
        error "Server $hostname: Unable to remove release $directory."
    }

    return ${return_code}
}
