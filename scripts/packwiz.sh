#! /bin/bash

script_path=$(realpath "$0")
script_directory=$(dirname "$script_path")

source "$script_directory/ci/packwiz-lib.sh"

run_packwiz_cmd "$@"