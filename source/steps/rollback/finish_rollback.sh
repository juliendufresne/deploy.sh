#!/usr/bin/env bash

function finish_rollback
{
    call_hook "post_rollback"

    return 0
}
readonly -f "finish_rollback"
