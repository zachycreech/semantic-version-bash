#!/bin/bash

# Ensure the user provided the correct number of arguments
if [ "$#" -ne 4 ]; then
  echo "Usage: $0 -p previous_version -n new_version -r release_notes -t access_token"
  exit 1
fi


while getopts "p:n:r:t:" opt; do 
  case $opt in 
    p)
      previous_version=$OPTARG
      ;;
    n)
      new_version=$OPTARG
      ;;
    r)
      unformatted_release_notes=$OPTARG
      ;;
    t)
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

if [ -z "$previous_version" ] || [ -z "$new_version" ] || [ -z "$unformatted_release_notes" ] || [ -z "$access_token" ]; then
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
     --request POST "https://gitlab.scanifly.com/api/v4/projects/116/releases"

echo "Created release for version: $new_version"

