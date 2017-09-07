#!/usr/bin/env bash

function get_hostname
{
    declare -n _hostname="$1"

    _hostname="$(hostname)"
}

