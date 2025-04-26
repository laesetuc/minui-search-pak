#!/bin/sh
PAK_DIR="$(dirname "$0")"
PAK_NAME="$(basename "$PAK_DIR")"
PAK_NAME="${PAK_NAME%.*}"
set -x

rm -f "$LOGS_PATH/$PAK_NAME.txt"
exec >>"$LOGS_PATH/$PAK_NAME.txt"
exec 2>&1

echo "$0" "$@"
cd "$PAK_DIR" || exit 1
mkdir -p "$USERDATA_PATH/$PAK_NAME"

ARCHITECTURE=arm
if [[ "$(uname -m)" == *"64"* ]]; then
    ARCHITECTURE=arm64
fi

export HOME="$USERDATA_PATH/$PAK_NAME"
export LD_LIBRARY_PATH="$PAK_DIR/lib:$LD_LIBRARY_PATH"
export PATH="$PAK_DIR/bin/$ARCHITECTURE:$PAK_DIR/bin/$PLATFORM:$PAK_DIR/bin:$PATH"

add_game_to_recents() {
    filepath="$1" game_alias="$2"

    filepath="${filepath#"$SDCARD_PATH/"}"
    recents="$SDCARD_PATH/.userdata/shared/.minui/recent.txt"
    if [ -f "$recents" ]; then
        sed -i "#/$filepath\t$game_alias#d" "$recents"
    fi

    rm -f "/tmp/recent.txt"
    printf "%s\t%s\n" "/$filepath" "$game_alias" >"/tmp/recent.txt"
    cat "$recents" >>"/tmp/recent.txt"
    mv "/tmp/recent.txt" "$recents"
}

get_rom_alias() {
    filepath="$1"
    filename="$(basename "$filepath")"
    filename="${filename%.*}"
    filename="$(echo "$filename" | sed 's/([^)]*)//g' | sed 's/\[[^]]*\]//g' | sed 's/[[:space:]]*$//')"
    echo "$filename"
}

get_emu_folder() {
    filepath="$1"
    roms="$SDCARD_PATH/Roms"

    echo "${filepath#"$roms/"}" | cut -d'/' -f1
}

get_emu_name() {
    emu_folder="$1"

    echo "$emu_folder" | sed 's/.*(\([^)]*\)).*/\1/'
}

get_emu_path() {
    emu_name="$1"
    platform_emu="$SDCARD_PATH/Emus/$PLATFORM/${emu_name}.pak/launch.sh"
    if [ -f "$platform_emu" ]; then
        echo "$platform_emu"
        return
    fi

    pak_emu="$SDCARD_PATH/.system/$PLATFORM/paks/Emus/${emu_name}.pak/launch.sh"
    if [ -f "$pak_emu" ]; then
        echo "$pak_emu"
        return
    fi

    return 1
}

show_message() {
    message="$1"
    seconds="$2"

    if [ -z "$seconds" ]; then
        seconds="forever"
    fi

    killall minui-presenter >/dev/null 2>&1 || true
    echo "$message" 1>&2
    if [ "$seconds" = "forever" ]; then
        minui-presenter --message "$message" --timeout -1 &
    else
        minui-presenter --message "$message" --timeout "$seconds"
    fi
}

cleanup() {
    rm -f /tmp/stay_awake
    killall minui-presenter >/dev/null 2>&1 || true
}

main() {
    echo "1" >/tmp/stay_awake
    trap "cleanup" EXIT INT TERM HUP QUIT

    if ! command -v minui-presenter >/dev/null 2>&1; then
        show_message "minui-presenter not found" 2
        return 1
    fi
    if ! command -v minui-keyboard >/dev/null 2>&1; then
        show_message "minui-keyboard not found" 2
        return 1
    fi
    if ! command -v minui-list >/dev/null 2>&1; then
        show_message "minui-list not found" 2
        return 1
    fi

    search_list_file="/tmp/search-list"
    results_list_file="/tmp/results-list"
    previous_search_file="/tmp/search-term"
    minui_ouptut_file="/tmp/minui-output"

    while true; do
        search_term=$(cat "$previous_search_file")

        total=$(cat "$search_list_file" | wc -l)
        if [ "$total" -eq 0 ]; then

            # Get search term
            killall minui-presenter >/dev/null 2>&1 || true
            minui-keyboard --title "Search" --initial-value "$search_term" --show-hardware-group --write-location "$minui_ouptut_file"
            exit_code=$?
            if [ "$exit_code" -eq 2 ] || [ "$exit_code" -eq 3 ]; then
                >"$previous_search_file"
                return $exit_code
            fi
            if [ "$exit_code" -ne 0 ]; then
                show_message "Error entering search term" 2
                return 1
            fi
            search_term=$(cat "$minui_ouptut_file")
            echo "$search_term" > "$previous_search_file"

            # Perform search
            show_message "Searching..."

            find "$SDCARD_PATH/Roms" -type f ! -path '*/\.*' -iname "*$search_term*" ! -name '*.txt' ! -name '*.log' > "$search_list_file"
            total=$(cat "$search_list_file" | wc -l)

            if [ "$total" -eq 0 ]; then
                show_message "Could not find any games." 2
            else
                >"$results_list_file"
                sed -e 's/^[^(]*(/(/' -e 's/)[^/]*\//) /' -e 's/[[:space:]]*$//' "$search_list_file" | jq -R -s 'split("\n")[:-1]' > "$results_list_file"
            fi
        fi

        # Display Results

        total=$(cat "$search_list_file" | wc -l)
        if [ "$total" -gt 0 ]; then
            killall minui-presenter >/dev/null 2>&1 || true
            minui-list --file "$results_list_file" --format json --write-location "$minui_ouptut_file" --write-value state --title "Search: $search_term ($total results)"
            exit_code=$?
            if [ "$exit_code" -eq 0 ]; then
                output=$(cat "$minui_ouptut_file")
                selected_index="$(echo "$output" | jq -r '.selected')"
                file=$(sed -n "$((selected_index + 1))p" "$search_list_file")

                emu_folder=$(get_emu_folder "$file")
                emu_name=$(get_emu_name "$emu_folder")
                emu_path=$(get_emu_path "$emu_name")
                rom_alias=$(get_rom_alias "$file")
                rm -f /tmp/stay_awake

                add_game_to_recents "$file" "$rom_alias"
                killall minui-presenter >/dev/null 2>&1 || true
                exec "$emu_path" "$file"
            else
                >"$results_list_file"
                >"$search_list_file"
            fi
        fi
    done
}

main "$@"
