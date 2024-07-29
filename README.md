## Semantic Versioning
The goal of this was to create a simple way of doing semantic versioning on a project, with minimum requirements. And to allow it
to be added to any project old or new to begin tracking changes.

## How to Use
You will need to make a container with the Dockerfile and upload it to your container registry.
Copy the sample `.gitlab-ci.yml` file into your project and change the variables at the top of the file to your needs. <br />
`DEPLOY_TARGET: "git@your-company:your-project.git"` <br />
`MAIN_BRANCH: "your-production-branch"` <br />

`DEVELOP_BRANCH: "your-working-branch"` Note: this is the branch that will increment versions. <br />
`SSH_KEY: "your-project-ssh-key"` Note: In gitlab this needs to be available via the CI/CD Variables. <br />
`PROJECT_ACCESS_TOKEN: "your-project-access-token"` <br />
`KNOWN_HOST: "your-company-repo"` <br />


## before_script
This will add the ssh key to your ~/.ssh folder and then add your KNOWN_HOST to the ~/.ssh/known_hosts. Afterwards it adds the `deploy-target` which will be used in the bash scripts for checking/creating tags.

## Bash Scripts
Script | Useage 
-------| ------ 
|create_tags.sh| -i major/minor/patch/release -t access_token -v versionOverride |
|parse_commits.sh| -b branch -t access_token |
|format_release_notes| -p previous_version -n new_version -r release_notes|
|create_release.sh| -p previous_version -n new_version -r release_notes -t access_token

## Version Override
If you want to start from a specific version, you will need to change the .gitlab-ci.yml. And push the change to your main branch. <br />
Line 35:    `- /scripts/create_tags.sh -i release -t "$PROJECT_ACCESS_TOKEN" -v` (the verision you want, i.e. 1.69.3)

