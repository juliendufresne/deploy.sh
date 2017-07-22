#!/usr/bin/env bash

function delete_application
{
    declare -r server_index=$1
    declare -r deploy_to="$2"
    declare -r current_release_path="$3"
    declare -r release_root_path="$4"
    declare -r shared_root_path="$5"
    declare hostname
    get_hostname "hostname"
    declare -r output_file="$(mktemp -t deploy.XXXXXXXXXX)"

    # strategy: failure should not break anything. Ex: we shouldn't have a symbolic link pointing to a non-existent destination

    # Other path does not depend on current release path (but current release path depends on other) so we remove it first
    if [[ -e "$current_release_path" ]]
    then
        rm --preserve-root "$current_release_path" &>"${output_file}" || {
            error_with_output_file "$output_file" "Server $hostname: Unable to remove current release path $current_release_path."

            return 1
        }
    fi

    # release root path contains releases so the current_release_path depends on it
    # it also defines some link towards shared root path so we need to remove it before shared_root_path
    if [[ -e "$release_root_path" ]]
    then
        rm --preserve-root --recursive "$release_root_path" &>"${output_file}" || {
            error_with_output_file "$output_file" "Server $hostname: Unable to remove release root path $release_root_path."

            return 1
        }
    fi

    # lastly (before the main removal) we remove the shared_root_path which should not have anything depending on it.
    if [[ -e "$shared_root_path" ]]
    then
        rm --preserve-root --recursive "$shared_root_path" &>"${output_file}" || {
            error_with_output_file "$output_file" "Server $hostname: Unable to remove shared root path $shared_root_path."

            return 1
        }
    fi

    # only remove the deploy_to folder if it is specified and it does not contain any files.
    # Users may need to store some data within that folder and we should not delete what does not belong to the deploy script

    if [[ -n "$deploy_to" ]]
    then
        if [[ "$(ls -A "$deploy_to")" ]]
        then
            # deploy_to contains some files.
            # Simple warning to tell the user why we didn't removed it

            warning "After removing every items managed by the deployment tools, we found some extra files in the deploy_to ($deploy_to) folder." \
                    "Hence we did not delete the folder in order to let you choose what you want to do with those files."
        else
            rm --preserve-root --recursive "$deploy_to" &>"${output_file}" || {
                error_with_output_file "$output_file" "Server $hostname: Unable to remove deploy_to path $deploy_to."

                return 1
            }
        fi

    fi

    rm "$output_file"

    return 0
}

