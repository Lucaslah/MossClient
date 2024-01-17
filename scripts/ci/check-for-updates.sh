if [ -z "$CI" ]; then
    echo "ERROR: this script should only be run on CI builds"
    exit 1
fi

script_path=$(realpath "$0")
script_directory=$(dirname "$script_path")

source "$script_directory/packwiz.sh"

run_packwiz_cmd "update --all"