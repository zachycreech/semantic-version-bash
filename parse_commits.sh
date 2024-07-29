#!/bin/bash

# Function to show usage
usage() {
  echo "Usage: -b branch -t accessToken"
  exit 1
}

b_flag=false;
t_flag=false;

while getopts "b:t:" opt; do
  case $opt in 
    b)
      b_flag=true
      branch=$OPTARG
      ;;
    t)
      t_flag=true
      access_token=$OPTARG
      ;;
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

if [ "$b_flag" = false ] || [ "$t_flag" = false ]; then
  usage
fi

# Fetch the latest commits
git fetch deploy-target "$branch" 

# Get the latest commits
commits=$(git log --pretty=format:"%s" deploy-target/"$branch")

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
    *"build:"*) echo "patch" ;;
    *"chore:"*) echo "patch" ;;
    *"perf:"*) echo "patch" ;;
    *"refactor:"*) echo "patch" ;;
    *"revert:"*) echo "patch" ;;
    *) echo "false" ;;
  esac
}

for commit_message in $commits; do
  current_release_type=$(determine_release_type "$commit_message")
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
done

echo "Determined highest release type: $highest_release_type"

# Check if release_type is false
if [ "$highest_release_type" == "false" ]; then
  echo "No relevant commits for tagging."
  exit 0
fi

# Check if the second argument is provided
if [ "$highest_release_type" != "false" ]; then
  echo "Creating tags with $highest_release_type"
  ./create_tags.sh -i "$highest_release_type" -t "$access_token" 
fi

