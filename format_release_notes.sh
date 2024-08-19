#!/bin/bash
format_release_notes(){
    usage() {
        echo "Usage: $0 -p prev_version -n new_version -r release_notes"
        exit 1
    }

    while getopts "p:n:r:" opt; do
        case $opt in
            p) previous_version=$OPTARG ;;
            n) new_version=$OPTARG ;;
            r) unformatted_release_notes=$OPTARG ;;
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

    if [ -z "$previous_version" ] || [ -z "$new_version" ] || [ -z "$unformatted_release_notes" ]; then
        usage
    fi

    project_url="https://gitlab.scanifly.com/cpm/semantic-test"
    release_title="## [$new_version]($project_url/compare/$previous_version...$new_version)"
    declare -A sections=(
        ["feat"]="🚀 Features"
        ["fix"]="🛠 Fixes"
        ["docs"]="📔 Docs"
        ["chore"]="Chores"
        ["ci"]="🦊 CI/CD"
        ["build"]="🦊 Builds"
        ["example"]="📝 Examples"
        ["perf"]="⏩ Performance"
        ["refactor"]="✂️ Refactor"
        ["revert"]="👀 Reverts"
        ["style"]="💈 Style"
        ["test"]="🧪 Tests"
    )

    declare -A notes

    # Filter out merge branch lines from the commit log
    filtered_commit_log=$(echo "$unformatted_release_notes" | grep -vE '^[0-9TZ.-]+ .*Merge branch')

    IFS=$'\n' read -r -d '' -a commit_array <<< "$filtered_commit_log"

    for line in "${commit_array[@]}"; do
        commit_hash=$(echo "$line" | awk '{print $1}' | xargs)
        commit_type=$(echo "$line" | awk -F'- ' '{print $2}' | awk -F': ' '{print $1}' | xargs)
        commit_message=$(echo "$line" | awk -F': ' '{print $2}' | xargs)
        bullet_point="* $commit_message ([${commit_hash}]($project_url/commit/${commit_hash}))\n"

        if [[ -n "${sections[$commit_type]}" ]]; then
            notes[$commit_type]+="$bullet_point"
        fi
    done

    release_notes="$release_title\n\n"

    for section in "${!sections[@]}"; do
        if [ ! -z "${notes[$section]}" ]; then
            release_notes+="### ${sections[$section]}\n${notes[$section]}\n"
        fi
    done

    echo -e "$release_notes"
}
