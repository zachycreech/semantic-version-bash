#!/bin/bash

usage(){
    echo "Usage: $0 -u project_url -w webhook_url -t access_token"
    exit 1
}

while getopts ":u:w:t:" opt; do
    case $opt in
        u) project_url=$OPTARG ;;
        w) webhook_url=$OPTARG ;;
        t) access_token=$OPTARG ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            exit 1
            ;;
        :)
            echo "Option -$OPTARG requires an argument." >&2
            exit 1
            ;;
    esac
done

if [ -z "$project_url" ] || [ -z "$webhook_url" ] || [ -z "$access_token" ]; then
    usage
fi

# Returns Tag from gitlab particularly
temp_location=$(curl --silent --header "PRIVATE-TOKEN: $access_token" "$project_url/permalink/latest")
release_tag=$(echo "$temp_location" | sed -n 's/.*moved temporarily to \/api\/v4\/projects\/[0-9]\+\/releases\/\([^"]\+\).*/\1/p')
release_tag=${release_tag%.}

response=$(curl --silent --header "PRIVATE-TOKEN: $access_token" "$project_url/$release_tag")

release_notes=$(echo "$response" | jq -r '.description')
commit_path=$(echo "$response" | jq -r '.commit_path')

if [[ "$release_notes" == "null" || -z "$release_notes" ]]; then
    echo "Release notes not found"
    exit 1
fi

project_name=$(echo "$commit_path" | awk -F'/' '{print $(NF-3)}')


format_release_notes() {
    local notes="$1"
    local project_name="$2"

    # Convert Markdown links to Slack links
    notes=$(echo "$notes" | sed -E 's/\[([^]]+)\]\(([^)]+)\)/<\2|\1>/g')

    # Replace ## with *
    notes=$(echo "$notes" | sed -E 's/^## (.+)/\*\1\*/')

    # Replace ### with a marker for new sections
    notes=$(echo "$notes" | sed -E 's/^### (.+)/NEW_SECTION:\1/')

    # Replace * with •
    notes=$(echo "$notes" | sed -E 's/^\* /• /')

    echo "$notes"
}

# Function to create JSON sections from formatted notes using a for loop
create_sections() {
    local formatted_notes="$1"
    local sections="[]"
    local IFS=$'\n'
    local lines=($formatted_notes)

    for line in "${lines[@]}"; do
        if [[ "$line" == NEW_SECTION:* ]]; then
            section_title="${line#NEW_SECTION:}"
            sections=$(jq --arg section "*${section_title}*" '. += [{"type": "section", "text": {"type": "mrkdwn", "text": $section}}]' <<< "$sections")
        else
            sections=$(jq --arg text "$line" '. += [{"type": "section", "text": {"type": "mrkdwn", "text": $text}}]' <<< "$sections")
        fi
    done

    echo "$sections"
}

# Format the release notes
formatted_notes=$(format_release_notes "$release_notes")

# Create sections from the formatted notes
sections=$(create_sections "$formatted_notes")
project_name="$project_name release notes:"



# JSON payload for the Slack message
payload=$(jq -n \
        --arg project_name "$project_name" \
        --argjson sections "$sections" \
        '{
    "blocks": [
      {
        "type": "header",
        "text": {
          "type": "plain_text",
          "text": $project_name
        }
      }
    ]
    } | .blocks += $sections'
)

# Send the release notes to Slack
curl -X POST -H 'Content-type: application/json' --data "$payload" "$webhook_url"

echo "Release notes sent to Slack."

