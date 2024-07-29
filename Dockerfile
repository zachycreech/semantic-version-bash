
FROM alpine:latest

# Install necessary packages
RUN apk update && apk add --no-cache \
    openssh-client \
    git \
    bash \
    curl 

# Create a directory for the SSH keys and scripts
RUN mkdir -p /root/.ssh /scripts


# Copy the bash scripts into the container
COPY parse_commits.sh /scripts/parse_commits.sh
COPY create_tags.sh /scripts/create_tags.sh
COPY format_release_notes.sh /scripts/format_release_notes.sh
COPY create_release.sh /scripts/create_release.sh


# Make the scripts executable
RUN chmod +x /scripts/parse_commits.sh /scripts/create_tags.sh
RUN chmod +x /scripts/format_release_notes.sh /scripts/create_release.sh

# Set the entry point to bash
ENTRYPOINT ["/bin/bash"]

