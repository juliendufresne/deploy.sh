#!/usr/bin/env bash

function do_not_run_twice
{
    declare -a function_list=("${FUNCNAME[@]}")
    declare -r current_function_name="${function_list[1]}"

    function_list=("${function_list[@]:2}")
    if [[ "${#function_list[@]}" -lt 2 ]]
    then
        return "0"
    fi

    unset 'function_list[${#function_list[@]}-1]'

    for function_name in "${function_list[@]}"
    do
        if [[ "$function_name" = "$current_function_name" ]]
        then
            error "Function name \"$function_name\" is reserved and can only be run internally."

            exit "1"
        fi
    done

    return "0"
}
