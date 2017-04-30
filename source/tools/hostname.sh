#!/usr/bin/env bash

function get_hostname
{
    declare -n _hostname="$1"

    _hostname="$(host -TtA "$(hostname -s)"|grep "has address"|awk '{ print $1 }')"
    if [[ "$_hostname" = "" ]]
    then
        _hostname="$(hostname -s)"
    fi
}
