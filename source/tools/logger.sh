#!/usr/bin/env bash

if ! [[ -v TITLE_LEVEL ]]
then
    declare -g -i TITLE_LEVEL=1
fi

function increase_title_level
{
    TITLE_LEVEL=$((TITLE_LEVEL + 1))
}

function decrease_title_level
{
    TITLE_LEVEL=$((TITLE_LEVEL - 1))
}

function reset_title_level
{
    TITLE_LEVEL=1
}

function _get_log_file
{
    declare -n _log_file="$1"

    if ! [[ -v DEPLOY_LOG_FILE ]]
    then
        declare -g DEPLOY_LOG_FILE=""
    fi

    if [[ -z "$DEPLOY_LOG_FILE" ]]
    then
        DEPLOY_LOG_FILE="$(dirname "$(mktemp --dry-run -t tmp.XXXXXXXXXX)")/deploy.log"
    fi

    if ! [[ -e "$DEPLOY_LOG_FILE" ]]
    then
        # errors on log file creation should not stop the execution
        touch "$DEPLOY_LOG_FILE" || true
    fi

    _log_file=""
    if [[ -w "$DEPLOY_LOG_FILE" ]]
    then
        _log_file="$DEPLOY_LOG_FILE"
    fi
}

function header
{
    is_quiet && return 0

    declare -r title="$1"
    declare -r underline_char="${2:-=}"
    declare -r -i title_length="$(echo -ne "$title" | sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g" | wc -c)"
    declare -r pad="$(printf %80s|tr ' ' "$underline_char")"

    printf '
\e[33m  %b\e[39;49m
\e[33m  %*.*s\e[39;49m

' "$title" '0' "$title_length" "$pad"

}

function section
{
    is_quiet && return 0

    header "$1" "-"
}

####
# Print the description of a section
####
#
# Output will looks like the following:
#  // This is a description
#  // A line of more than 80 characters will be cut into several lines. You
#  // can pass more than one argument. Each argument will be print in a
#  // separated line.
#  // Output accepts color.
#
function section_description
{
    is_quiet && return 0

    declare -r prefix='  // '
    declare -i current_string_output_length='0'
    declare -i index='0'
    declare -r -i terminal_length='80'
    declare -i -r max_message_length="$((terminal_length - ${#prefix}))"
    declare color="\e[39;49m"
    declare message
    declare message_to_display

    for message in "$@"
    do
        printf '%s' "$prefix"
        for message_to_display in "$(echo -ne "$message" | sed -r "s/\x1B/\n-/g")"
        do
            if echo -ne "$message_to_display" | grep -q ^'-\[[0-9][0-9]*\(;[0-9][0-9]*\)*[m|K]'
            then
                color="\e$(echo -ne "$message_to_display" | grep -o ^'-\[[0-9][0-9]*\(;[0-9][0-9]*\)*[m|K]'|sed 's/^-//')"
                message_to_display="$(echo -ne "$message_to_display" | sed -r "s/-\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g")"
            fi

            index='0'
            while (( index++ < "${#message_to_display}" ))
            do
                character="${message_to_display:index-1:1}"
                printf '%b%s%b' "$color" "$character" "\e[39;49m"
                current_string_output_length="$((current_string_output_length + 1))"
                if [[ "$current_string_output_length" -eq "$max_message_length" ]]
                then
                    current_string_output_length='0'
                    printf '\n'
                    printf '%s' "$prefix"
                fi
            done
        done
        printf '\n'
        current_string_output_length='0'
    done
    printf '\n'
}

function section_done
{
    is_quiet && return 0

    declare is_first_line=true
    declare -r prefix_first=' [OK] '
    declare -r prefix_other='      '
    declare -r color="\e[37;42m"
    declare -r reset="\e[39;49m"
    declare -r pad='                                                                                '
    declare -r -i terminal_length='80'
    declare -r -i fold_length="$((terminal_length - ${#prefix_other} - 1 - 2))"

    printf '\n'
    printf ' %b%*.*s%b\n' "$color" '0' "$((terminal_length - 1))" "$pad" "$reset"
    for message in "$@"
    do
        index='0'
        for output in $(echo -ne "$message" | sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g" | fold --spaces --bytes --width=$fold_length)
        do
            if ${is_first_line}
            then
                printf ' %b%s' "$color" "$prefix_first"
                is_first_line=false
            else
                printf ' %b%s' "$color" "$prefix_other"
            fi

            printf '%s%*.*s%b\n' "$output" '0' "$((terminal_length - ${#output} - ${#prefix_other} - 1))" "$pad" "$reset"
        done
    done
    printf ' %b%*.*s%b\n' "$color" '0' "$((terminal_length - 1))" "$pad" "$reset"
}

function display_title
{
    is_quiet && return 0

    # level should be one-based (starting from 1). Level 0 is considered a section
    declare -r name="$1"
    declare -r symbols=" >+-*ø§"
    declare symbol="§"

    if [[ "${TITLE_LEVEL}" -lt "${#symbols}" ]]
    then
        symbol=${symbols:${TITLE_LEVEL}:1}
    fi

    # display (level * 2) spaces
    printf ' %.0s' `seq 1 $((TITLE_LEVEL * 2))`
    printf '\e[35m%s\e[34m %b\e[0m\n' "${symbol}" "$name"
}

function warning
{
    block " [WARNING] " "\e[90;43m" "/dev/stderr" "$@"
}

function error
{
    block " [ERROR] " "\e[37;101m" "/dev/stderr" "$@"
}

function block
{
    declare is_first_line=true
    declare -r prefix_first="$1"
    declare -r color="$2"
    declare -r redirection="$3"
    declare -r reset="\e[39;49m"
    declare -r pad='                                                                                '
    declare -r -i terminal_length='80'
    declare -a params=()
    declare log_file
    _get_log_file "log_file"

    shift
    shift
    shift

    declare prefix_other
    printf -v prefix_other '%*.*s' '0' "${#prefix_first}" "$pad"
    declare -r -i fold_length="$((terminal_length - ${#prefix_other} - 1 - 2))"

    printf '\n' >"$redirection"
    printf ' %b%*.*s%b\n' "$color" '0' "$((terminal_length - 1))" "$pad" "$reset" >"$redirection"

    for message in "$@"
    do
        params+=("$message")
    done

    if is_debug
    then
        params+=("occurred on ${BASH_SOURCE[1]}:${BASH_LINENO[1]}")
    fi

    for message in "${params[@]}"
    do
        while read output
        do
            if ${is_first_line}
            then
                printf ' %b%s' "$color" "$prefix_first" >"$redirection"
                is_first_line=false
            else
                printf ' %b%s' "$color" "$prefix_other" >"$redirection"
            fi

            printf '%s%*.*s%b\n' "$output" '0' "$((terminal_length - ${#output} - ${#prefix_other} - 1))" "$pad" "$reset" >"$redirection"
        done <<< "$(echo -ne "$message" | sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g" | fold --spaces --bytes --width="$fold_length")"

        [[ -n "$log_file" ]] && printf "[%s] %s %s\n" "$(date "+%Y%m%d%H%M%S")" "$prefix_first" "$message" >> "$log_file"
    done
    printf ' %b%*.*s%b\n' "$color" '0' "$((terminal_length - 1))" "$pad" "$reset" >"$redirection"
}

function error_with_output_file
{
    declare -r output_file="$1"
    shift

    error "$@"

    >&2 printf 'Following is the output of the command\n'
    >&2 printf '######################################\n'
    >&2 cat "$output_file"
    rm "$output_file"
}

function is_quiet
{
    [[ ${VERBOSITY_LEVEL} -eq -1 ]] && return 0

    return 1
}

function is_verbose
{
    [[ ${VERBOSITY_LEVEL} -ge 1 ]] && return 0

    return 1
}

function is_very_verbose
{
    [[ ${VERBOSITY_LEVEL} -ge 2 ]] && return 0

    return 1
}

function is_debug
{
    [[ ${VERBOSITY_LEVEL} -ge 3 ]] && return 0

    return 1
}