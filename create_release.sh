#!/bin/bash

# Ensure the user provided the correct number of arguments
usage(){
    echo "Usage: $0 -p previous_version -n new_version -r release_notes -t access_token -u project_url"
    exit 1
}

while getopts "p:n:r:t:u:w:" opt; do
    case $opt in
        p) previous_version=$OPTARG ;;
        n) new_version=$OPTARG ;;
        r) unformatted_release_notes=$OPTARG ;;
        t) access_token=$OPTARG ;;
        u) project_url=$OPTARG ;;
        w) webhook_url=$OPTARG ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            exit 1
            ;;
        :)
            echo "Option -$OPTARG requires an argument.">&2
            exit 1
            ;;
    esac
done

if [ -z "$previous_version" ] || [ -z "$new_version" ] || [ -z "$unformatted_release_notes" ] || [ -z "$access_token" ] || [ -z "$webhook_url" ]; then
    usage
fi

echo "$unformatted_release_notes"
source ./format_release_notes.sh
release_notes=$(format_release_notes -p"$previous_version" -n"$new_version" -r"$unformatted_release_notes")

echo "curl POST request"

curl --header "PRIVATE-TOKEN: $access_token" \
    --data "name=Release $new_version" \
    --data "tag_name=$new_version" \
    --data "description=$release_notes" \
    --request POST "$project_url"

echo "Created release for version: $new_version"

./slack_bot.sh -u"$project_url" -w"$webhook_url" -t"$access_token"
