
# Function to display a list of timezones and allow the user to select one
function set_tz() {
    local timezones=("America/New_York" "America/Chicago" "America/Denver" "America/Los_Angeles" "Europe/London" "Europe/Berlin" "Asia/Tokyo" "Asia/Hong_Kong" "Australia/Sydney")
    echo "Select a timezone:"
    for i in "${!timezones[@]}"; do
        printf "%d) %s\n" $((i+1)) "${timezones[$i]}"
    done

    local choice
    read -p "Enter number (1-${#timezones[@]}): " choice

    # Validate the input
    if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt "${#timezones[@]}" ]; then
        echo "Invalid selection. Please try again."
        return 1
    fi

    local selected_timezone="${timezones[$choice-1]}"
    echo "You selected: $selected_timezone"

    # Write the selected timezone to ~/.tz file
    echo "$selected_timezone" > ~/.tz
    echo "Timezone saved to ~/.tz"
}
