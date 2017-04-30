#!/usr/bin/env bash

declare -r DEPLOY_SCRIPT_ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$DEPLOY_SCRIPT_ROOT_DIR/lib/loader.bash"

loader_addpath "$DEPLOY_SCRIPT_ROOT_DIR/source"

load main.sh "$@"
