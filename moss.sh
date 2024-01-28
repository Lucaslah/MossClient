#! /bin/bash

perf_start_time=$(date +%s)
root=$(dirname "$(realpath "$0")")

# Common folder locations
cache_location="$root/.cache"
pack_location="$root/pack"
build_location="$root/build"

# Common executable locations
packwiz_location="$cache_location/packwiz"

# Common file locations
html_template_location="$root/release/website/mods.html.template"

# Build group counter
declare -i processed_build_groups=0

if [ -z "$MOSS_ENABLED_MODULES" ]; then
    MOSS_ENABLED_MODULES=()
    MOSS_ENABLED_MODULES+=("mrpack")
    MOSS_ENABLED_MODULES+=("mlhtml")
    MOSS_ENABLED_MODULES+=("mljson")
else
    IFS=',' read -ra MOSS_ENABLED_MODULES <<< "$MOSS_ENABLED_MODULES"
fi

is_module_enabled() {
    local target_module="$1"
    for module in "${MOSS_ENABLED_MODULES[@]}"; do
        if [ "$module" == "$target_module" ]; then
            return 0 
        fi
    done
    return 1
}

success() {
    echo -e "\e[1;32;40m$(echo $1 | tr '[:lower:]' '[:upper:]')\e[0m"
}

fail() {
    local perf_end_time=$(date +%s)
    local perf_execution_time=$((perf_end_time - perf_start_time))
    echo -e "\e[1;31;40m$(echo "build failed in $perf_execution_time seconds" | tr '[:lower:]' '[:upper:]')\e[0m"
    exit 1
}

log() {
  local message=$(echo "$1" | tr '[:upper:]' '[:lower:]')
  local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
  echo -e "\e[90m[$timestamp] $message"
}

group_start() {
    perf_current_build_group_start_time=$(date +%s)
    current_build_group="$1"
}

group_end() {
    perf_current_build_group_end_time=$(date +%s)
    perf_current_build_group_execution_time=$((perf_current_build_group_end_time - perf_current_build_group_start_time))

    processed_build_groups+=1

    success "group build $current_build_group (#$processed_build_groups) was successful - completed in $perf_current_build_group_execution_time seconds"

    # Cleanup
    unset current_build_group
    unset perf_current_build_group_start_time
    unset perf_current_build_group_end_time
    unset perf_current_build_group_execution_time
}

trap 'fail' ERR

# Download packwiz if needed
if [ -e "$packwiz_location" ]; then
    log "found packwiz at: $packwiz_location"
    chmod +x "$packwiz_location"
else
    log "downloading packwiz"

    perf_packwiz_download_start_time=$(date +%s)

    gh run download --repo packwiz/packwiz --name "Linux 64-bit x86" --dir "$cache_location/tmp"

    mv "$cache_location/tmp/packwiz" "$packwiz_location"
    rm -rf "$cache_location/tmp"
    chmod +x "$packwiz_location"

    perf_packwiz_download_end_time=$(date +%s)
    perf_packwiz_download_execution_time=$((perf_packwiz_download_end_time - perf_packwiz_download_start_time))

    log "packwiz download completed in $perf_packwiz_download_execution_time seconds"

    # Cleanup of packwiz download perf
    unset perf_packwiz_download_start_time
    unset perf_packwiz_download_end_time
    unset perf_packwiz_download_execution_time
fi

run_packwiz_cmd() {
    pushd "$pack_location" || exit 1
    eval "\"$packwiz_location\" $1"
    popd || exit 1
}

# Cleanup old build
rm -rf "$build_location"

# Create build directory
mkdir -p "$build_location"

pack_version=$(grep -E '^version\s*=' "$pack_location/pack.toml" | awk -F'"' '{print $2}')

if is_module_enabled "mrpack"; then
    # Build modrinth mod-pack
    group_start "mrpack"
    log "starting mrpack build"
    run_packwiz_cmd "modrinth export --output \"$build_location/MossClient-$pack_version.mrpack"\"
    log "result saved to $build_location/MossClient-$pack_version.mrpack"
    group_end
fi

if is_module_enabled "mljson"; then
    # Build json mod-list
    group_start "ml-json"
    log "starting json mod-list build"

    build_ml_json() {
        local mods_path="$pack_location/mods"
        local mod_id_regex='\[update.modrinth\]\s*mod-id\s*=\s*"([^"]+)"'
        local mod_ids=()

        for file in "$mods_path"/*; do
            if [ -f "$file" ]; then
                local content=$(cat "$file")

                local mod_id=""
                if [[ $content =~ $mod_id_regex ]]; then
                    mod_id="${BASH_REMATCH[1]}"
                    mod_ids+=("$mod_id")
                fi
            fi
        done

        local mod_ids_string=$(printf "\"%s\"," "${mod_ids[@]}")
        local mod_ids_string=${mod_ids_string%,}
        local encoded_mod_ids_string=$(printf "%s" "$mod_ids_string" | jq -sRr @uri)

        local request_url="https://api.modrinth.com/v2/projects?ids=%5B$encoded_mod_ids_string%5D"

        local response=$(curl -s "$request_url")

        local res_ids=()
        local res_icon_urls=()
        local res_titles=()
        local res_urls=()

        while read -r mod; do
            local id=$(echo "$mod" | jq -r '.id')
            local icon_url=$(echo "$mod" | jq -r '.icon_url')
            local title=$(echo "$mod" | jq -r '.title')

            res_ids+=("$id")
            res_icon_urls+=("$icon_url")
            res_titles+=("$title")
            res_urls+=("https://modrinth.com/mod/$id")
        done <<< "$(echo "$response" | jq -c '.[]')"

        local json_array='['
        for i in $(seq 0 $(( ${#res_ids[@]} - 1 ))); do
            json_array+='{"url":"'${res_urls[i]}'","logo":"'${res_icon_urls[i]}'","name":"'${res_titles[i]}'"},'
        done
        json_array=${json_array%,}
        json_array+=']'

        echo "$json_array" | jq 'sort_by(.name) | .' > "$build_location/mods.json"
    }

    build_ml_json

    log "result saved to $build_location/mods.json"
    group_end
fi

if is_module_enabled "mljson"; then
    # Build html mod-list
    group_start "ml-html"
    log "starting html mod-list build"

    build_ml_html() {
        # Track processed mods
        declare -i total_mods=0

        local html_output='<ul>\n'
        while IFS= read -r line; do
            total_mods+=1
            local name=$(echo "$line" | jq -r '.name')
            local url=$(echo "$line" | jq -r '.url')
            local logo=$(echo "$line" | jq -r '.logo')

            log "processing mod $name"

            html_output+="                <li>\n"
            html_output+="                    <img src=\"$logo\" alt=\"$name\">\n"
            html_output+="                    <a href=\"$url\">$name</a>\n"
            html_output+="                </li>\n"
        done < <(jq -c '.[]' "$build_location/mods.json")
        html_output+='            </ul>'

        sed "s|<!-- MOD_LIST_BUILD_RESULT -->|$html_output|" "$html_template_location" > "$build_location/mods.html"

        log "build finished - processed $total_mods mods"

        # Cleanup
        unset total_mods
    }

    build_ml_html

    log "result saved to $build_location/mods.html"
    group_end
fi

if is_module_enabled "mlraw"; then
    group_start "ml-raw"
    log "starting raw mod-list build"

    build_mlraw() {
        local mods_path="$pack_location/mods"
        local mod_id_regex='\[update.modrinth\]\s*mod-id\s*=\s*"([^"]+)"'
        local mod_name_regex='^\s*name\s*=\s*"([^"]+)"'
        local mod_ids=()
        local mod_names=()
        local html_list=()
        local text_output=""

        for file in "$mods_path"/*; do
            if [ -f "$file" ]; then
                local content=$(cat "$file")

                local mod_id=""
                if [[ $content =~ $mod_id_regex ]]; then
                    mod_id="${BASH_REMATCH[1]}"
                    mod_ids+=("$mod_id")
                fi

                local mod_name=""
                if [[ $content =~ $mod_name_regex ]]; then
                    mod_name="${BASH_REMATCH[1]}"
                    mod_names+=("$mod_name")
                fi

                html_list+=("<li><a href=\"https://modrinth.com/mod/$mod_id\">$mod_name</a></li>")
                text_output+="$mod_id\n"
            fi
        done

        html_content=$(cat <<EOF
<!DOCTYPE html>
<html lang="en">
<body>
    <ul>
        $(IFS=$'\n'; echo "${html_list[*]}")
    </ul>
</body>
</html>
EOF
)

        echo -e "$text_output" > "$build_location/mods.txt"
        echo "$html_content" > "$build_location/mods-raw.html"
    }

    build_mlraw

    log "result saved to $build_location/mods.txt"
    log "result saved to $build_location/mods-raw.html"
    group_end
fi

perf_end_time=$(date +%s)
perf_execution_time=$((perf_end_time - perf_start_time))

log "processed $processed_build_groups groups"
success "build successful - processed build in $perf_execution_time seconds"
