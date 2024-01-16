script_path=$(realpath "$0")
script_directory=$(dirname "$script_path")
cache_path="$script_directory/../.cache"
output_path="$script_directory/../../build"
pack_toml_path="$script_directory/../../pack.toml"

packpiz_location="$cache_path/packwiz"

if [ -e "$packpiz_location" ]; then
    echo "Found packwiz at: $packpiz_location"
else
    echo "Packwiz not found... Downloading..."
    gh run download --repo packwiz/packwiz --name "Linux 64-bit x86" --dir "$cache_path/.dl"
    mv "$cache_path/.dl/packwiz" "$packpiz_location"
    rm -rf "$cache_path/.dl"
fi

run_packwiz_cmd() {
    eval "\"$packpiz_location\" $1"
}

version=$(grep -E '^version\s*=' "$pack_toml_path" | awk -F'"' '{print $2}')

mkdir -p build

run_packwiz_cmd "modrinth export --output build/MossClient-$version.mrpack"