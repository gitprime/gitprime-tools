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

echo "Extracting docker logs for all containers"

# Use those container names to get the docker logs.  This will give us the
# any logging from the entry points.
while read -r CONTAINER_NAME; do
 docker logs ${CONTAINER_NAME} >> "${DOCKER_LOG_DIR}/${CONTAINER_NAME}.log" 2>&1
done <<< "${REPLICATED_CONTAINER_LIST}"

# Get the list of currently running containers.  We're going to use these to try and grab
# the GitPrime Enterprise application logs.  We can only do that for the web, scheduler, and worker
# containers
GITPRIME_CONTAINER_LIST=$(docker ps --format="{{.Names}}" | grep -P "replicated_[0-9a-f]{32}_(web|scheduler|worker)\..*")

echo "Extracting GitPrime Enterprise logs"

# Loop through and get anything in /var/log/gitprime
while read -r CONTAINER_NAME;
do
 mkdir -p "${GITPRIME_LOG_DIR}/${CONTAINER_NAME}"

 # We need a list of log files
 LOG_FILE_NAMES=$(docker exec "${CONTAINER_NAME}" ls /var/log/gitprime/)

 while read -r LOG_FILE_NAME;
 do
    docker cp "${CONTAINER_NAME}:/var/log/gitprime/${LOG_FILE_NAME}" "${GITPRIME_LOG_DIR}/${CONTAINER_NAME}/${LOG_FILE_NAME}"
 done <<< "${LOG_FILE_NAMES}"

done <<< "${GITPRIME_CONTAINER_LIST}"

echo "Creating support bundle..."

SUPPORT_BUNDLE_NAME="replicated-logs-${TIMESTAMP}.tar.gz"

# Tar/GZ it all up
tar -C "${TMP_LOG_DIR_ROOT}" -czf "${SUPPORT_BUNDLE_NAME}" ${TMP_LOG_DIR_NAME}

echo "Created support bundle: ${SUPPORT_BUNDLE_NAME}"

# Clean up after ourselves because we're not slobs
rm -fr ${TMP_LOG_DIR}

# Put IFS back, just because we should
IFS=$OLD_IFS

