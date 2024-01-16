if [ -z "$CI" ]; then
    echo "ERROR: this script should only be run on CI builds"
    exit 1
fi

script_path=$(realpath "$0")
script_directory=$(dirname "$script_path")
cache_path="$script_directory/../.cache"
pack_location="$script_directory/../../pack"
pack_toml_path="$pack_location/pack.toml"

packwiz_location="$cache_path/packwiz"

if [ -e "$packwiz_location" ]; then
    echo "Found packwiz at: $packwiz_location"
    chmod +x "$packwiz_location"
else
    echo "Packwiz not found... Downloading..."
    gh run download --repo packwiz/packwiz --name "Linux 64-bit x86" --dir "$cache_path/.dl"
    mv "$cache_path/.dl/packwiz" "$packwiz_location"
    rm -rf "$cache_path/.dl"
    chmod +x "$packwiz_location"
fi

run_packwiz_cmd() {
    eval "\"$packwiz_location\" $1"
}

version=$(grep -E '^version\s*=' "$pack_toml_path" | awk -F'"' '{print $2}')

mkdir -p build

pushd "$pack_location" || exit 1
run_packwiz_cmd "modrinth export --output ../build/MossClient-$version.mrpack"
popd || exit 1