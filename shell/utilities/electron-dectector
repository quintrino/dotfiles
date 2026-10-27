#!/bin/bash
# Electron Detector / MacNative — MIT licensed. Compatible with macOS Bash 3.2.
# No network calls during scanning. Never modifies application bundles.
VERSION="2.1.0"
export LC_ALL=en_US.UTF-8
json=false quiet=false interactive=false share=false custom=false demo=false
roots=() apps=() names=() sizes=() versions=() evidence=()
count=0 total_kb=0 unknown_sizes=0 skipped=0
usage() {
    cat <<HELP
Electron Detector $VERSION — find the Electron apps on your Mac.
Usage: bash electron-detector.sh [options]
  --path DIRECTORY  Scan a custom folder (repeatable; replaces defaults)
  -u, --user        Include ~/Applications (already included by default)
  -j, --json        JSON report; app names but no personal folder paths
  -q, --quiet       Results without the banner or promotion
  -i, --interactive Offer actions after the report (requires a terminal)
  --share          Print a shareable summary without app names or paths
  --demo           Preview fictional results; does not scan your apps
  --no-color       Disable terminal colors (also respects NO_COLOR)
  -v, --version    Print version
  -h, --help       Show help
Default folders: /Applications and ~/Applications, including subfolders.
Nothing is installed, deleted, launched, or uploaded during a scan.
HELP
}
while [ "$#" -gt 0 ]; do
    case "$1" in
        --path) [ "$#" -ge 2 ] && [ -d "$2" ] || { printf 'Expected an existing directory after --path\n' >&2; exit 2; }; custom=true; roots+=("$2"); shift 2 ;;
        -u|--user) shift ;;
        -j|--json) json=true; shift ;;
        -q|--quiet) quiet=true; shift ;;
        -i|--interactive) interactive=true; shift ;;
        --share) share=true; shift ;;
        --demo) demo=true; shift ;;
        --no-color) NO_COLOR=1; shift ;;
        -v|--version) printf '%s\n' "$VERSION"; exit 0 ;;
        -h|--help) usage; exit 0 ;;
        *) printf 'Unknown option: %s\n' "$1" >&2; exit 2 ;;
    esac
done
if $json && $share; then printf 'Choose either --json or --share.\n' >&2; exit 2; fi
if $demo && { $json || $custom; }; then printf -- '--demo cannot be combined with --json or --path.\n' >&2; exit 2; fi
if [ "$(uname -s)" != Darwin ]; then printf 'This detective needs macOS.\n' >&2; exit 2; fi
if $interactive && { $json || $share || [ ! -t 0 ] || [ ! -t 1 ]; }; then
    printf -- '--interactive requires a terminal and cannot be combined with --json or --share.\n' >&2; exit 2
fi
if ! $custom; then
    roots=(/Applications)
    [ ! -d "$HOME/Applications" ] || roots+=("$HOME/Applications")
fi
mint='' dim='' reset='' yellow='' purple='' green='' bold='' animate=false
if [ -t 1 ] && [ "${TERM:-dumb}" != dumb ]; then animate=true; fi
if [ -t 1 ] && [ -z "${NO_COLOR+x}" ] && [ "${TERM:-dumb}" != dumb ]; then
    mint=$'\033[1;36m'; dim=$'\033[2m'; reset=$'\033[0m'
    yellow=$'\033[1;33m'; purple=$'\033[0;35m'; green=$'\033[1;32m'; bold=$'\033[1m'
fi
# JSON string escaping includes every control byte; never interpolate names as code.
json_string() {
    local value="$1" char n i
    local LC_ALL=C
    printf '"'
    for ((i=0; i<${#value}; i++)); do
        char="${value:i:1}"
        case "$char" in
            '"') printf '\\"' ;; \\) printf '\\\\' ;;
            *) printf -v n '%d' "'$char"
               n=$((n & 255))
               if [ "$n" -lt 32 ]; then printf '\\u%04x' "$n"; else printf '%s' "$char"; fi ;;
        esac
    done
    printf '"'
}
safe_text() { printf '%s' "$1" | tr '[:cntrl:]' '?'; }
pretty_size() {
    if [ "$1" -lt 0 ]; then printf 'unknown';
    elif [ "$1" -ge 1048576 ]; then awk -v n="$1" 'BEGIN {printf "%.1f GiB",n/1048576}';
    else awk -v n="$1" 'BEGIN {printf "%.1f MiB",n/1024}'; fi
}
# A compact layout keeps the report readable in narrow terminal windows.
columns=80
if $animate; then columns=$(tput cols 2>/dev/null) || columns=80; fi
case "$columns" in ''|*[!0-9]*) columns=80 ;; esac
compact=false; [ "$columns" -ge 68 ] || compact=true
rule() { printf '%s  ────────────────────────────────────────────────────────────────%s\n' "$dim" "$reset"; }
progress() {
    local done="$1" total="$2" b filled=0 pct=0
    [ "$total" -eq 0 ] || { filled=$((done*24/total)); pct=$((done*100/total)); }
    printf '\r%s  [' "$mint"
    for ((b=0;b<24;b++)); do
        if [ "$b" -lt "$filled" ]; then printf '▓'; else printf '░'; fi
    done
    printf '] %3d%% (%d/%d)%s' "$pct" "$done" "$total" "$reset"
}
if ! $json && ! $quiet && ! $share; then
    if $compact; then
        printf '\n%s  ⚡ Electron Detector%s\n  Find out what is inside your Mac apps.\n\n' "$mint" "$reset"
    else
        printf '\n%s  ╭────────────────────────────────────────────────────────────────╮\n' "$mint"
        printf '  │  %-50s %10s │\n' 'Electron Detector for macOS' "v$VERSION"
        printf '  │  %-62s│\n' 'Find out what is inside your Mac apps.'
        printf '  ╰────────────────────────────────────────────────────────────────╯%s\n\n' "$reset"
    fi
    if $demo; then printf '  DEMO / fictional apps and sizes. Nothing scanned.\n\n';
    else printf '  🔍 Scanning app folders. Everything stays on your Mac.\n\n'; fi
fi
if $demo; then
    count=42; total_kb=1572864
    names=("Example Editor" "Example Chat" "Example Notes")
    sizes=(786432 524288 262144)
    versions=("1.2.0" "4.0.1" "2.3.0")
    evidence=("Electron Framework.framework" "Electron Framework.framework" "Contents/MacOS/Electron")
else
# Use NUL-delimited paths and prune bundles, so helpers are not counted as apps.
work=$(mktemp -d "${TMPDIR:-/tmp}/electron-detector.XXXXXX") || exit 1
trap 'rm -rf "$work"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
# Prefix relative roots so find never treats a directory name as an expression.
for ((r=0;r<${#roots[@]};r++)); do
    case "${roots[$r]}" in /*) ;; *) roots[$r]="./${roots[$r]}" ;; esac
done
find -L "${roots[@]}" -type d -name '*.app' -prune -print0 > "$work/apps" 2> "$work/errors"
if [ -s "$work/errors" ]; then
    skipped=$(wc -l < "$work/errors" | tr -d ' ')
    printf 'Some folders could not be read (%s traversal warnings). Results may be incomplete.\n' "$skipped" >&2
fi
candidates=0 processed=0
while IFS= read -r -d '' app; do candidates=$((candidates+1)); done < "$work/apps"
while IFS= read -r -d '' app; do
    if ! $json && ! $quiet && ! $share && $animate; then progress "$processed" "$candidates"; fi
    processed=$((processed+1))
    canonical=$(cd "$app" 2>/dev/null && pwd -P) || { skipped=$((skipped+1)); continue; }
    duplicate=false
    for seen in "${apps[@]}"; do [ "$seen" != "$canonical" ] || { duplicate=true; break; }; done
    $duplicate && continue
    apps+=("$canonical")
    if [ ! -r "$app/Contents" ] || [ ! -x "$app/Contents" ]; then skipped=$((skipped+1)); continue; fi
    count=$((count+1))
    signal=''
    if [ -d "$app/Contents/Frameworks/Electron Framework.framework" ]; then signal='Electron Framework.framework';
    elif [ -f "$app/Contents/MacOS/Electron" ]; then signal='Contents/MacOS/Electron'; fi
    [ -n "$signal" ] || continue
    name=${app##*/}; name=${name%.app}
    version=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$app/Contents/Info.plist" 2>/dev/null) || version='Unknown'
    size=$(du -sk "$canonical" 2>/dev/null) && size=${size%%[[:space:]]*} || size=-1
    case "$size" in ''|*[!0-9-]*) size=-1 ;; esac
    if [ "$size" -lt 0 ]; then unknown_sizes=$((unknown_sizes+1)); else total_kb=$((total_kb+size)); fi
    # Insertion order: largest bundles first. Parallel arrays preserve arbitrary names.
    pos=${#names[@]}
    while [ "$pos" -gt 0 ] && [ "${sizes[$((pos-1))]}" -lt "$size" ]; do
        names[$pos]=${names[$((pos-1))]}; sizes[$pos]=${sizes[$((pos-1))]}
        versions[$pos]=${versions[$((pos-1))]}; evidence[$pos]=${evidence[$((pos-1))]}
        pos=$((pos-1))
    done
    names[$pos]=$name; sizes[$pos]=$size; versions[$pos]=$version; evidence[$pos]=$signal
done < "$work/apps"
if ! $json && ! $quiet && ! $share && $animate; then
    progress "$processed" "$candidates"; printf '\n\n'
fi
fi
found=${#names[@]}
app_label=apps; [ "$found" -ne 1 ] || app_label=app
percent=0; [ "$count" -eq 0 ] || percent=$((found*100/count))
summary() {
    if $demo; then printf 'DEMO / fictional results; nothing scanned.\n'; fi
    printf 'My Mac app census: %d of %d inspected apps have Electron markers (%d%%).\n' "$found" "$count" "$percent"
    printf 'Detected bundles: %s on disk' "$(pretty_size "$total_kb")"
    [ "$unknown_sizes" -eq 0 ] || printf ' + %d unmeasured' "$unknown_sizes"
    printf '. Not a RAM or battery benchmark.\n'
    [ "$skipped" -eq 0 ] || printf 'Partial scan: %d warnings.\n' "$skipped"
    printf 'No marker found does not prove an app is native.\n'
    printf 'Try it: https://github.com/macnative/electron-detector\n'
    if ! $quiet; then printf 'Explore native alternatives: https://macnative.io/categories\n'; fi
}
if $json; then
    printf '{"schema_version":2,"detector_version":"%s","total_apps":%d,"electron_count":%d,"total_size_kb":%d,"unknown_sizes":%d,"scan_warnings":%d,"electron_apps":[' "$VERSION" "$count" "$found" "$total_kb" "$unknown_sizes" "$skipped"
    for ((i=0;i<found;i++)); do
        [ "$i" -eq 0 ] || printf ','
        printf '{"name":'; json_string "${names[$i]}"
        printf ',"size_kb":'; if [ "${sizes[$i]}" -lt 0 ]; then printf null; else printf '%d' "${sizes[$i]}"; fi
        printf ',"version":'; json_string "${versions[$i]}"
        printf ',"evidence":'; json_string "${evidence[$i]}"; printf '}'
    done
    printf ']}\n'
elif $share; then summary
else
    printf '%s  ✓ Scan complete · %d Electron %s found%s\n' "$green" "$found" "$app_label" "$reset"
    printf '  %d apps inspected · %d%% have Electron markers\n\n' "$count" "$percent"
    if [ "$count" -eq 0 ]; then printf '  No readable app bundles found in the selected folders.\n';
    elif [ "$found" -eq 0 ]; then printf '  No Electron markers spotted in the inspected apps.\n'; fi
    if [ "$found" -gt 0 ]; then
        printf '%s  ⚡ Electron apps · largest first%s\n\n' "$yellow" "$reset"
        if ! $compact; then
            printf '  %s%-32s %12s  %-16s%s\n' "$bold" 'App' 'Disk size' 'App version' "$reset"
            rule
        fi
        for ((i=0;i<found;i++)); do
            display_name=$(safe_text "${names[$i]}")
            display_version=$(safe_text "${versions[$i]}")
            if $compact; then
                printf '  %s%s%s\n    %s · v%s\n' "$bold" "$display_name" "$reset" "$(pretty_size "${sizes[$i]}")" "$display_version"
            else
                # Preserve long and non-ASCII names on their own line. Their
                # terminal cell widths vary; never truncate or misalign columns.
                ascii_name=$(LC_ALL=C printf '%s' "$display_name" | LC_ALL=C tr -cd ' -~')
                if [ "${#display_name}" -gt 32 ] || [ "$ascii_name" != "$display_name" ]; then
                    printf '  %s%s%s\n' "$bold" "$display_name" "$reset"; display_name=''
                fi
                printf '  %-32s %s%12s%s  %s%s%s\n' "$display_name" "$yellow" "$(pretty_size "${sizes[$i]}")" "$reset" "$purple" "$display_version" "$reset"
            fi
        done
        if ! $compact; then rule; fi
    fi
    printf '\n%s  📦 Disk footprint%s\n' "$mint" "$reset"
    printf '  Detected app bundles: %s%s%s' "$bold" "$(pretty_size "$total_kb")" "$reset"
    [ "$unknown_sizes" -eq 0 ] || printf ' + %d unmeasured' "$unknown_sizes"
    printf '\n  Whole app bundles; excludes user data and caches.\n'
    if [ "$found" -gt 0 ] && [ "$total_kb" -gt 0 ] && [ "$unknown_sizes" -eq 0 ]; then
        printf '  Largest: %s (%d%% of the detected footprint)\n' "$(safe_text "${names[0]}")" "$((sizes[0]*100/total_kb))"
    fi
    printf '  This is disk usage, not RAM usage or potential savings.\n'
    printf '  No marker found does not prove an app is native.\n'
    [ "$skipped" -eq 0 ] || printf '  Partial scan: %d warnings (unreadable folders or bundles).\n' "$skipped"
    if ! $quiet; then
        printf '\n%s  💡 Did you know?%s\n' "$yellow" "$reset"
        printf '  Electron bundles Chromium and Node.js inside desktop apps.\n'
        printf '  These apps do not need Chrome installed to run.\n'
        printf '  Curious about actual RAM use? Check Activity Monitor.\n'
        printf '\n%s  ✨ Find your next native Mac app%s\n' "$green" "$reset"
        printf '  Explore alternatives by category → https://macnative.io/categories\n'
        printf '  Keep the apps you love. Try something new where it makes sense.\n'
        printf '\n%s  Tip: --interactive for sharing and evidence; --json for export.%s\n\n' "$dim" "$reset"
    fi
fi
if $interactive; then
    while true; do
        printf '\n  [s] Share text  [c] Copy summary  [e] Explain findings\n'
        printf '  [a] Native alternatives  [q] Done\n  > '
        IFS= read -r choice || break
        case "$choice" in
            s|S) printf '\n'; summary ;;
            c|C) if summary | pbcopy; then printf '  Copied. App names and paths are left out.\n';
                 else printf '  Clipboard unavailable. Choose s to print the summary.\n'; fi ;;
            e|E) for ((i=0;i<found;i++)); do
                     printf '\n  %s\n    %s\n' "$(safe_text "${names[$i]}")" "${evidence[$i]}"
                 done
                 printf '\n  The clues: an Electron framework or executable in a bundle.\n'
                 printf '  A match means the app contains a runtime marker.\n'
                 printf '  No match does not establish which framework it uses.\n'
                 printf '  Sizes cover whole app bundles, excluding user data and caches.\n'
                 printf '  For RAM and CPU use, inspect running apps in Activity Monitor.\n' ;;
            a|A) open 'https://macnative.io/categories' || printf '  Visit https://macnative.io/categories in your browser.\n' ;;
            q|Q|'') break ;;
            *) printf '  Choose s, c, e, a, or q (Enter finishes).\n' ;;
        esac
    done
fi
