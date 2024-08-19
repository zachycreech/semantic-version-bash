#!/bin/bash

# Function to show usage
usage() {
    echo "Usage: $0 -v major|minor|patch|release -t accesstoken -u project_url -w webhook_url [-o versionOverride]"
    exit 1
}

version_override=""

while getopts "v:t:u:w:o:" opt; do
    case $opt in
        v) version=$OPTARG ;;
        t) access_token=$OPTARG ;;
        u) project_url=$OPTARG ;;
        w) webhook_url=$OPTARG ;;
        o) version_override=$OPTARG ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            usage
            ;;
        :)
            echo "Option -$OPTARG requires an argument." >&2
            usage
            ;;
    esac
done

if [ -z "$version" ] || [ -z "$access_token" ] || [ -z "$project_url" ] || [ -z "$webhook_url" ]; then
    usage
fi

# Fetch the latest tags from the remote
git fetch --tags

# Get the latest staging tag
latest_staging_tag=$(git tag --list 'staging.*' | sort -V | tail -n 1)
latest_production_tag=$(git tag -l --sort=-v:refname | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' | head -n 1)

if [ -z "$latest_staging_tag" ]; then
    latest_staging_tag="staging.1.0.0"
fi

if [ -n "$version_override" ]; then
    latest_staging_tag="staging.$version_override"
    echo "Overriding Version with $version_override"
    git tag "$latest_staging_tag"

    echo "Created Staging Override tag: $latest_staging_tag"
    git push deploy-target "$latest_staging_tag"
    git fetch --all
    echo "Remove override and run again"
    exit 0
else
    echo "No version override set."
fi

# Remove the "staging." prefix to get the version part
latest_version="${latest_staging_tag#staging.}"

# Split the version into parts
IFS='.' read -r -a version_parts <<< "$latest_version"

# Increment the version based on the provided argument
case "$version" in
    major)
        ((version_parts[0]++))
        version_parts[1]=0
        version_parts[2]=0
        ;;
    minor)
        ((version_parts[1]++))
        version_parts[2]=0
        ;;
    patch)
        ((version_parts[2]++))
        ;;
    release)
        new_version="$latest_version"

        tag_exists() {
            git rev-parse "$1" >/dev/null 2>&1
        }

        increment_version() {
            version=$1
            if [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
                base_version=$(echo "$version" | grep -oE '^[0-9]+(\.[0-9]+){2}')
                last_digit=$(( ${version##*.} + 1 ))
                echo "${base_version}.$last_digit"
            else
                last_digit=1
                echo "${version}.$last_digit"
            fi

        }

        tag_exists() {
            git rev-parse "$1" >/dev/null 2>&1
        }

        while tag_exists "$new_version"; do
            new_version=$(increment_version "$new_version")
        done

        git tag "$new_version"
        git push deploy-target "$new_version"
        echo "Created new production tag: $new_version"
        git fetch --all
        release_notes=$(git log --pretty=format:"%h - %s" $latest_production_tag..$new_version)
        ./create_release.sh -p"$latest_production_tag" -n"$new_version" -r"$release_notes" -t"$access_token" -u"$project_url" -w"$webhook_url"
        exit 0
        ;;
    *)
        usage
        ;;
esac

# Create the new version string
new_version="staging.${version_parts[0]}.${version_parts[1]}.${version_parts[2]}"

# Create the new tag
git tag "$new_version"

# Push the tag to the remote repository
git push deploy-target "$new_version"

echo "Created new tag: $new_version"

git fetch --all

# Create Release Notes
staging_release_notes=$(git log --pretty=format:"%h - %s" $latest_staging_tag..$new_version)

./create_release.sh -p"$latest_staging_tag" -n"$new_version" -r"$staging_release_notes" -t"$access_token" -u"$project_url" -w"$webhook_url"
