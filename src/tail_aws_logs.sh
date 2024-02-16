#!/bin/bash

# Internal functions prefixed with _

function _get_timestamp() {
    local logs_json="$1"
    echo "$logs_json" | jq -r '.[-1].timestamp // empty'
}

function _format_logs() {
    local logs_json="$1"
    local tz="$2"
    echo "$logs_json" | jq -r '.[] | "\(.eventId) \(.timestamp) \(.message)"' | while read -r line; do
        local event_id=$(echo "$line" | cut -d ' ' -f1)
        local timestamp=$(echo "$line" | cut -d ' ' -f2)
        local message=$(echo "$line" | cut -d ' ' -f3-)
        
        if [[ -z "${processed_event_ids[$event_id]}" ]]; then
            local formatted_time=$(TZ="$tz" date -d "@$((timestamp / 1000))" +"%Y-%m-%d %H:%M:%S")
            echo "$formatted_time $message"
        fi
    done
}

function _fetch_logs_with_filtering() {
    local log_group_name="$1"
    local app_name="$2"
    local start_timestamp="$3"
    local logs_json=$(aws logs filter-log-events \
        --log-group-name "$log_group_name" \
        --start-time "$start_timestamp" \
        --query "events[?contains(logStreamName, '$app_name')]" \
        --output json)
    echo "$logs_json"
}

function _fetch_history_logs() {
    local log_group_name="$1"
    local app_name="$2"
    local history_minutes="$3"
    local start_timestamp=$(date --date="$history_minutes minutes ago" +%s%N | cut -b1-13)
    _fetch_logs_with_filtering "$log_group_name" "$app_name" "$start_timestamp"
}

function _fetch_recent_logs() {
    local log_group_name="$1"
    local app_name="$2"
    local start_timestamp="$3"
    _fetch_logs_with_filtering "$log_group_name" "$app_name" "$start_timestamp"
}

# Main function
function tail_aws_logs() {
    if [ "$#" -lt 2 ]; then
        echo "Tool for imitating tail -f for AWS CloudWatch logs."
        echo "Usage: tail_aws_logs <log_group_name> <app_name> [<history_minutes> [<timezone>]]"
        return 1
    fi

    # Check for a .tz file in the user's home directory to set the timezone
    if [ -f ~/.tz ]; then
        tz=$(cat ~/.tz)
    else
        tz="America/New_York" # Default to EST (America/New_York) if ~/.tz does not exist
    fi

    local log_group_name="$1"
    local app_name="$2"
    local history_minutes="${3:-1}" # Default to 1 if not supplied
    local tz="${4:-$tz}" # Use the timezone from ~/.tz if provided, otherwise default to America/New_York
    local poll_interval=5 # Fixed poll interval

    echo "Fetching initial logs for app '$app_name' in log group '$log_group_name' from the last $history_minutes minutes, using timezone $tz."
    local initial_logs_json=$(_fetch_history_logs "$log_group_name" "$app_name" "$history_minutes")
    _format_logs "$initial_logs_json" "$tz"

    local last_timestamp=$(_get_timestamp "$initial_logs_json")
    if [[ -z "$last_timestamp" || "$last_timestamp" == "null" ]]; then
        last_timestamp=$(($(date +%s%N) / 1000000))
    fi

    while true; do
        if [[ -n "$last_timestamp" ]]; then
            local next_timestamp=$(($last_timestamp + 1))
            local recent_logs_json=$(_fetch_recent_logs "$log_group_name" "$app_name" "$next_timestamp")
            local new_timestamp=$(_get_timestamp "$recent_logs_json")
            
            if [[ -n "$new_timestamp" && "$new_timestamp" != "null" ]]; then
                last_timestamp=$new_timestamp
            fi

            _format_logs "$recent_logs_json" "$tz"
        fi

        echo -n "..."
        sleep "$poll_interval"
        echo -ne "\r\033[K"
    done
}
