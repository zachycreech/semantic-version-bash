# Semantic Bash Release Bot

## Semantic Versioning
The goal of this was to create a simple way of doing semantic versioning on a project, with minimum requirements. And to allow it
to be added to any project old or new to begin tracking changes.

This adds the ability to make a version override if you didn't want to startfrom 1.0.0 like similiar bots.

I have also included a Slack webhook that will post the releases formatted. 

## How to Use
You will need to make a container with the Dockerfile and upload it to your container registry.
Copy the sample `.gitlab-ci.yml` file into your project and change the variables at the top of the file to your needs. 


## before_script
This will add the ssh key to your ~/.ssh folder and then add your KNOWN_HOST to the ~/.ssh/known_hosts. Afterwards it adds the `deploy-target` which will be used in the bash scripts for checking/creating tags.

## Bash Scripts
| `Scripts`                 | Description                                                                                            | Options                                                                                         |  
| :------------------------ | :----------------------------------------------------------------------------------------------------- | :----------------------------------------------------------------------------------------------- |
| `create_tags.sh`          | Generates the tags to be used                                                                          | `-v major/minor/patch/release -t access_token -u project_url -w webhook_url -o versionOverride`  |
| `parse_commits.sh`        | Checks commits to decide versioning                                                                    | `-b branch -t access_token -u project_url -w webhook_url -o version_override`                    |
| `format_release_notes.sh` | Helper script to format release notes based currently on GitLab                                        | `-p prev_version -n new_version -r release_notes`                                                |
| `create_release.sh`       | Uses curl to post the release notes, currently set up for GitLab                                       | `-p prev_version -n new_version -r release_notes -t access_token`                                |
| `slack_bot.sh`            | Uses the GitLab API found in your GitLab settings to get release notes, then posts to provided Slack webhook | `-u project_url -w webhook_url -t access_token`                                                  |

## Version Override
If you want to start from a specific version, you will need to change the .gitlab-ci.yml. And push the change to your main branch. <br />
Line 37:    `- /scripts/create_tags.sh -v release -t "$PROJECT_ACCESS_TOKEN" -w "$WEBHOOK_URL" -v` (the verision you want, i.e. 69.69.69)

## Slack bot
I have included the webhooks I used to format the release notes generated into a slack message. You will need to create a bot via slack and add the proper webhook key.

## Hotfix
If you need to commit a hotfix to your production branch, this bot will add X.X.X.1, and if that is found it will increment that final number. 
