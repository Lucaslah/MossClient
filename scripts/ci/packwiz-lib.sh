script_path=$(realpath "$0")
script_directory=$(dirname "$script_path")
cache_path="$script_directory/../../.cache"
pack_location="$script_directory/../pack"
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
    pushd "$pack_location" || exit 1
    eval "\"$packwiz_location\" $1"
    popd || exit 1
}