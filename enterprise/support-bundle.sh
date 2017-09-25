#!/bin/bash

# Going to change IFS for the purposes of parsing here
OLD_IFS=$IFS

IFS=$'\n'

# Setup a timestamp for filenames, etc
TIMESTAMP=$(date +"%Y-%m-%d-%H-%M-%S")

# Setup our log directories
TMP_LOG_DIR_ROOT=$(mktemp -d)

TMP_LOG_DIR_NAME="replicated-logs-${TIMESTAMP}"

TMP_LOG_DIR="${TMP_LOG_DIR_ROOT}/${TMP_LOG_DIR_NAME}"

DOCKER_LOG_DIR="${TMP_LOG_DIR}/docker"
GITPRIME_LOG_DIR="${TMP_LOG_DIR}/gitprime"

mkdir -p "${DOCKER_LOG_DIR}"
mkdir -p "${GITPRIME_LOG_DIR}"

# Get the list of as many containers as we can, including ones that have died.
REPLICATED_CONTAINER_LIST=$(docker ps -a --format="{{.Names}}")

# Use those container names to get the docker logs.  This will give us the
# any logging from the entry points.
while read -r CONTAINER_NAME; do
 docker logs ${CONTAINER_NAME} >> "${DOCKER_LOG_DIR}/${CONTAINER_NAME}.log" 2>&1
done <<< "${REPLICATED_CONTAINER_LIST}"

# Get the list of currently running containers.  We're going to use these to try and grab
# the GitPrime Enterprise application logs.
GITPRIME_CONTAINER_LIST=$(docker ps --format="{{.NAMES}}")

# Loop through and get anything in /var/log/gitprime
while read -r CONTAINER_NAME; do
 docker logs ${CONTAINER_NAME} >> "${DOCKER_LOG_DIR}/${CONTAINER_NAME}.log" 2>&1
done <<< "${REPLICATED_CONTAINER_LIST}"

# Tar/GZ it all up
tar -C "${TMP_LOG_DIR_ROOT}" -czf "replicated-logs-${TIMESTAMP}.tar.gz" ${TMP_LOG_DIR_NAME}

# Clean up after ourselves because we're not slobs
rm -fr ${TMP_LOG_DIR}

# Put IFS back, just because we should
IFS=$OLD_IFS