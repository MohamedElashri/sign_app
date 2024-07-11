#!/bin/bash

set -e

# Global variables
VERBOSE=false
CACHE_FILE="$HOME/.sign_app_cache"

# Function to display help information
display_help() {
    echo "Usage: sign-app [OPTIONS]"
    echo "Sign user-installed macOS applications."
    echo
    echo "Options:"
    echo "  -n, --name <app_name>   Sign a specific user-installed app by name"
    echo "  -l, --list              List all user-installed macOS apps"
    echo "  -h, --help              Display this help message"
    echo "  -v, --verbose           Enable verbose output"
    echo "  --update-list           Force update of the cached app list"
    echo "  --check                 Verify if an app is already signed"
    echo "  --force                 Force re-signing even if the app is already signed"
    echo "  --entitlements <file>   Specify custom entitlements file"
    echo "  --backup                Create a backup of the app before signing"
}

# Function to check if codesign is available
check_codesign() {
    if ! command -v codesign &> /dev/null; then
        echo "Error: codesign command not found. Please ensure Xcode Command Line Tools are installed."
        exit 1
    fi
}

# Function to check if an app is a system app
is_system_app() {
    local app_path="$1"
    
    # Check if the app is in /System/Applications
    if [[ "$app_path" == "/System/Applications/"* ]]; then
        return 0
    fi
    
    # Check if the app is signed by Apple
    if codesign -dv "$app_path" 2>&1 | grep -q "Authority=Apple"; then
        return 0
    fi
    
    # Check if the app bundle identifier starts with com.apple.
    local bundle_id=$(osascript -e "id of app \"$app_path\"" 2>/dev/null)
    if [[ "$bundle_id" == com.apple.* ]]; then
        return 0
    fi
    
    return 1
}

# Function to find user-installed apps
find_user_installed_apps() {
    local apps=()
    
    # Search in /Applications (excluding Apple apps)
    while IFS= read -r app; do
        if ! is_system_app "$app"; then
            apps+=("$app")
        fi
    done < <(find /Applications -maxdepth 1 -name "*.app" -type d)
    
    # Search in ~/Applications
    while IFS= read -r app; do
        apps+=("$app")
    done < <(find "$HOME/Applications" -maxdepth 1 -name "*.app" -type d 2>/dev/null)
    
    # Use mdfind to find additional apps, excluding known system apps
    while IFS= read -r app; do
        if ! is_system_app "$app"; then
            apps+=("$app")
        fi
    done < <(mdfind -onlyin / 'kMDItemContentType == "com.apple.application-bundle" && kMDItemKind == "Application"' | grep -v '^/System/' | grep -v '^/Library/')
    
    # Remove duplicates and sort
    printf '%s\n' "${apps[@]}" | sort -u
}

# Function to select an app from the list
select_app() {
    local apps=("$@")
    echo "Select an app to sign:"
    select app in "${apps[@]}"; do
        if [[ -n "$app" ]]; then
            echo "$app"
            return
        else
            echo "Invalid selection. Please try again."
        fi
    done
}

# Function to validate the app
validate_app() {
    local app_path="$1"
    
    if [[ ! -d "$app_path" ]]; then
        echo "Error: App not found: $app_path"
        exit 1
    fi
    
    if is_system_app "$app_path"; then
        echo "Error: Cannot sign system app: $app_path"
        exit 1
    fi
}

# Function to sign the app
sign_app() {
    local app_path="$1"
    local entitlements="$2"
    local force="$3"
    local backup="$4"
    
    validate_app "$app_path"
    
    if [[ "$backup" == "true" ]]; then
        local backup_path="${app_path}_backup_$(date +%Y%m%d%H%M%S)"
        echo "Creating backup: $backup_path"
        cp -R "$app_path" "$backup_path"
    fi
    
    local sign_cmd="codesign --force --deep --sign -"
    
    if [[ -n "$entitlements" ]]; then
        sign_cmd+=" --entitlements \"$entitlements\""
    fi
    
    if [[ "$force" != "true" ]]; then
        if codesign -dv "$app_path" &> /dev/null; then
            echo "App is already signed. Use --force to re-sign."
            exit 0
        fi
    fi
    
    echo "Signing app: $app_path"
    if $VERBOSE; then
        eval "$sign_cmd \"$app_path\""
    else
        eval "$sign_cmd \"$app_path\"" &> /dev/null
    fi
    
    echo "App signed successfully: $app_path"
}

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -n|--name)
            APP_NAME="$2"
            shift 2
            ;;
        -l|--list)
            LIST_APPS=true
            shift
            ;;
        -h|--help)
            display_help
            exit 0
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        --update-list)
            UPDATE_LIST=true
            shift
            ;;
        --check)
            CHECK_ONLY=true
            shift
            ;;
        --force)
            FORCE_SIGN=true
            shift
            ;;
        --entitlements)
            ENTITLEMENTS="$2"
            shift 2
            ;;
        --backup)
            BACKUP=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            display_help
            exit 1
            ;;
    esac
done

# Check for codesign availability
check_codesign

# Main logic
if [[ -n "$APP_NAME" ]]; then
    app_path=$(find /Applications ~/Applications -maxdepth 1 -name "$APP_NAME.app" -type d 2>/dev/null | head -n 1)
    if [[ -z "$app_path" ]]; then
        echo "Error: App not found: $APP_NAME"
        exit 1
    fi
    if [[ "$CHECK_ONLY" == "true" ]]; then
        if codesign -dv "$app_path" &> /dev/null; then
            echo "App is already signed: $app_path"
        else
            echo "App is not signed: $app_path"
        fi
    else
        sign_app "$app_path" "$ENTITLEMENTS" "$FORCE_SIGN" "$BACKUP"
    fi
elif [[ "$LIST_APPS" == "true" || "$UPDATE_LIST" == "true" ]]; then
    if [[ "$UPDATE_LIST" == "true" || ! -f "$CACHE_FILE" ]]; then
        find_user_installed_apps > "$CACHE_FILE"
    fi
    apps=($(cat "$CACHE_FILE"))
    if [[ ${#apps[@]} -eq 0 ]]; then
        echo "No user-installed apps found."
        exit 0
    fi
    selected_app=$(select_app "${apps[@]}")
    if [[ "$CHECK_ONLY" == "true" ]]; then
        if codesign -dv "$selected_app" &> /dev/null; then
            echo "App is already signed: $selected_app"
        else
            echo "App is not signed: $selected_app"
        fi
    else
        sign_app "$selected_app" "$ENTITLEMENTS" "$FORCE_SIGN" "$BACKUP"
    fi
else
    echo "Error: No action specified. Use -h or --help for usage information."
    exit 1
fi