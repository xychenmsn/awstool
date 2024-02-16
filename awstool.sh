#!/bin/bash

# set_tz.sh

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

# tail_aws_logs.sh
# Append all arguments passed to the function to the log file
function _app1_log() {
    echo "$@" >> awstool.log
}

# Function to show help information
function _app1_show_help() {
    # Added new option description for --poll-interval / -p
    echo "Tail AWS CloudWatch logs with optional filtering. Version 1"
    echo ""
    echo "Usage: tail_aws_logs --loggroup your_log_group_name [--stream pattern_in_stream_name] [--history history_minutes] [--timezone your_timezone] [--poll-interval seconds]"
    echo "Short form: tail_aws_logs -g your_log_group_name [-s pattern_in_stream_name] [-h history_minutes] [-t your_timezone] [-p seconds]"
    echo ""
    echo "Examples:"
    echo "  tail_aws_logs --loggroup \"billing-qa\" --stream \"payment\" --history 10 --timezone UTC --poll-interval 5"
    echo "  tail_aws_logs -g my-log-group -h 5 -p 10" # Without stream, showing all logs with custom poll interval
    echo "Parameters:"
    echo "  --loggroup, -g : The name of the CloudWatch Log Group (required)."
    echo "  --stream, -s   : The pattern of stream name within the Log Group (optional)."
    echo "  --history, -h  : The history window in minutes to fetch logs from (optional, default is 1)."
    echo "  --timezone, -t : The timezone to display timestamps in (optional, default is America/New_York)."
    echo "  --poll-interval, -p : The interval in seconds between log fetches (optional, default is 5)."
}

# Function to parse options using traditional getopts
function _app1_parse_options() {
    log_group_name=""
    stream_pattern=""
    history_minutes=""
    tz=""
    poll_interval=5 # Default poll interval

    if [ -f ~/.tz ]; then
        tz=$(cat ~/.tz)
    else
        tz="America/New_York" # Default to EST (America/New_York) if ~/.tz does not exist
    fi

    while [[ "$#" -gt 0 ]]; do
        case "$1" in
            --loggroup | -g)
                log_group_name="$2"
                shift 2
                ;;
            --stream | -s)
                stream_pattern="$2"
                shift 2
                ;;
            --history | -h)
                history_minutes="$2"
                shift 2
                ;;
            --timezone | -t)
                tz="$2"
                shift 2
                ;;
            --poll-interval | -p)
                poll_interval="$2" # Capture the poll interval
                shift 2
                ;;
            --help | -?)
                _app1_show_help
                return 1
                ;;
            --)
                shift
                break
                ;;
            *)
                echo "Unknown parameter: $1"
                _app1_show_help
                return 1
                ;;
        esac
    done

    if [[ -z "$log_group_name" ]]; then
        echo "Error: log group name is required."
        _app1_show_help
        return 1
    fi

    history_minutes="${history_minutes:-1}" # Default to 1 minute if not specified
    tz="${tz:-America/New_York}" # Default timezone if not specified

    # echo "log_group_name: $log_group_name"
    # echo "stream_pattern: $stream_pattern"
    # echo "history_minutes: $history_minutes"
    # echo "tz: $tz"
    # echo "poll_interval: $poll_interval" # Display the set poll interval
}


function _app1_get_timestamp() {
    local logs_json="$1"
    echo "$logs_json" | jq -r '.[-1].timestamp // empty'
}

function _app1_format_logs() {
    local logs_json="$1"
    echo "$logs_json" | jq -r '.[] | "\(.eventId) \(.timestamp) \(.message)"' | while read -r line; do
        local event_id=$(echo "$line" | cut -d ' ' -f1) # for future use if we want to ensure unique events
        local timestamp=$(echo "$line" | cut -d ' ' -f2)
        local message=$(echo "$line" | cut -d ' ' -f3-)
        
        local formatted_time=$(TZ="$tz" date -d "@$((timestamp / 1000))" +"%Y-%m-%d %H:%M:%S")
        echo "$formatted_time $message"
    done
}

# Function to fetch logs with optional stream filtering
function _app1_fetch_logs_with_filtering() {
    local start_timestamp="$1"
    local query_params=(
        --log-group-name "$log_group_name"
        --start-time "$start_timestamp"
        --output json
    )

    local query="events[]"
    if [ -n "$stream_pattern" ]; then
        # If a stream pattern is specified, filter events by logStreamName
        query="events[?contains(logStreamName, '$stream_pattern')]"
    fi
    # Append the selection of specific fields to the query
    query+=".{timestamp: timestamp, message: message}"
    # Add the complete query to the query parameters
    query_params+=(--query "$query")

    # _app1_log "aws logs filter-log-events ${query_params[@]}"
    local logs_json=$(aws logs filter-log-events "${query_params[@]}")
    echo "$logs_json"
}

# Main function to tail AWS logs
function tail_aws_logs() {
    _app1_parse_options "$@"

    local parse_status=$?  # Capture the return status of _app1_parse_options

    if [ $parse_status != 0 ]; then
        # If _app1_parse_options returns a non-zero status, stop further execution
        return $parse_status
    fi

    local start_timestamp=$(date --date="$history_minutes minutes ago" +%s%N | cut -b1-13)
    local initial_logs_json=$(_app1_fetch_logs_with_filtering "$start_timestamp")
    _app1_format_logs "$initial_logs_json"

    local last_timestamp=$(_app1_get_timestamp "$initial_logs_json")
    if [[ -z "$last_timestamp" || "$last_timestamp" == "null" ]]; then
        last_timestamp=$(($(date +%s%N) / 1000000))
    fi

    while true; do
        if [[ -n "$last_timestamp" ]]; then
            local next_timestamp=$(($last_timestamp + 1))
            local recent_logs_json=$(_app1_fetch_logs_with_filtering "$next_timestamp")
            local new_timestamp=$(_app1_get_timestamp "$recent_logs_json")
            
            if [[ -n "$new_timestamp" && "$new_timestamp" != "null" ]]; then
                last_timestamp=$new_timestamp
            fi

            _app1_format_logs "$recent_logs_json"
        fi

        echo -n "..."
        sleep $poll_interval # Use the dynamically set poll interval
        echo -ne "\r\033[K"
    done
}

