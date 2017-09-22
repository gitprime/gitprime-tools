#!/bin/bash

REPLICATED_CONTAINER_LIST=$(docker ps -a --format="{{.Names}}")

OLD_IFS=$IFS

IFS=$'\n'

TIMESTAMP=$(date +"%Y-%m-%d-%H-%M-%S")

TMP_LOG_DIR_ROOT=$(mktemp -d)

TMP_LOG_DIR_NAME="replicated-logs-${TIMESTAMP}"

TMP_LOG_DIR="${TMP_LOG_DIR_ROOT}/${TMP_LOG_DIR_NAME}"

mkdir -p "${TMP_LOG_DIR}"

while read -r CONTAINER_NAME; do
 docker logs ${CONTAINER_NAME} >> "${TMP_LOG_DIR}/${CONTAINER_NAME}.log" 2>&1
done <<< "${REPLICATED_CONTAINER_LIST}"

TIMESTAMP=$(date +"%Y-%m-%d-%H-%M-%S")

tar -C "${TMP_LOG_DIR_ROOT}" -czf "replicated-logs-${TIMESTAMP}.tar.gz" ${TMP_LOG_DIR_NAME}

rm -fr ${TMP_LOG_DIR}

IFS=$OLD_IFS
