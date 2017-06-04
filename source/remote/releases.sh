#!/usr/bin/env bash

function clean_oldest_releases
{
    declare -r -i keep_releases="$1"
    declare -r release_directory="$2"
    declare -r link_of_current_release="$3"
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
