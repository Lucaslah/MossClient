if [ -z "$CI" ]; then
    echo "ERROR: this script should only be run on CI builds"
    exit 1
fi

script_path=$(realpath "$0")
script_directory=$(dirname "$script_path")

source "$script_directory/packwiz.sh"

version=$(grep -E '^version\s*=' "$pack_toml_path" | awk -F'"' '{print $2}')

mkdir -p build

pushd "$pack_location" || exit 1
run_packwiz_cmd "modrinth export --output ../build/MossClient-$version.mrpack"
popd || exit 1