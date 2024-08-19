#!/bin/bash

# Function to show usage
usage() {
    echo "Usage: -b branch -t access_token -u project_url -w webhook_url -o version_override"
    exit 1
}

while getopts "b:t:u:w:o:" opt; do
    case $opt in
        b) branch=$OPTARG ;;
        t) access_token=$OPTARG ;;
        u) project_url=$OPTARG ;;
        w) webhook_url=$OPTARG ;;
        o) version_override=$OPTARG ;;
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

if [ -z "$branch" ] || [ -z "$access_token" ] || [ -z "$project_url" ] || [ -z "$webhook_url" ]; then
    usage
fi

# Fetch the latest commits
git fetch deploy-target "$branch"
git fetch --tags

latest_staging_tag=$(git tag --list 'staging.*' | sort -V | tail -n 1)
# Get the latest commits
commits=$(git log "$latest_staging_tag..HEAD" --pretty=format:"%s" deploy-target/"$branch")

highest_release_type="false"

determine_release_type() {
    local commit_message=$1
    if [[ $commit_message == *"breaking:"* ]]; then
        echo "major"
        return
    fi

    case $commit_message in
        *"feat:"*) echo "minor" ;;
        *"fix:"*) echo "patch" ;;
        *"style:"*) echo "patch" ;;
        *"build:"*) echo "patch" ;;
        *"chore:"*) echo "patch" ;;
        *"perf:"*) echo "patch" ;;
        *"test:"*) echo "patch" ;;
        *"refactor:"*) echo "patch" ;;
        *"revert:"*) echo "patch" ;;
        *) echo "false" ;;
    esac
}

IFS=$'\n'
commits_array=($commits)
index=0
length=${#commits_array[@]}

while [ $index -lt $length ]; do
    commit_message=${commits_array[$index]}
    echo "Processing commit message: $commit_message"  # Debug statement
    current_release_type=$(determine_release_type "$commit_message")
    echo "Determined release type: $current_release_type"  # Debug statement

    case $current_release_type in
        "major")
            highest_release_type="major"
            break
            ;;
        "minor")
            if [ "$highest_release_type" != "major" ]; then
                highest_release_type="minor"
            fi
            ;;
        "patch")
            if [ "$highest_release_type" != "major" ] && [ "$highest_release_type" != "minor" ]; then
                highest_release_type="patch"
            fi
            ;;
    esac

    index=$((index + 1))
done
unset IFS

echo "Final highest release type: $highest_release_type"  # Debug statement

if [ -n "$version_override" ]; then
    highest_release_type="patch"
    ./create_tags.sh -v"$highest_release_type" -t"$access_token" -u"$project_url" -w"$webhook_url" -o"$version_override"
fi

if [ "$highest_release_type" == "false" ]; then
    echo "No relevant commits for tagging."
    exit 0
fi

if [ "$highest_release_type" != "false" ] || [ -z "$version_override" ]; then
    echo "Creating tags with $highest_release_type"
    ./create_tags.sh -v"$highest_release_type" -t"$access_token" -u"$project_url" -w"$webhook_url"
fi

