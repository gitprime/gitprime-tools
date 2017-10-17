#!/usr/bin/env bash
#
# This code is licensed.  For details, please see the license file at
# https://github.com/gitprime/gitprime-tools/blob/master/LICENSE.md

# This particular tool is meant to manage all hooks.  It's basically
# a wrapper for the various specific hooks found in the hooks directory.

# We need to know if we can find a home directory for the tools.  This is
# incredibly important.
if [[ ! -z "${GITPRIME_TOOLS_HOME}" ]];
then
    # Ok, we have GITPRIME_TOOLS_HOME set.  We can use that as our base for includes
    source "${GITPRIME_TOOLS_HOME}/library/common.sh"
    source "${GITPRIME_TOOLS_HOME}/library/git.sh"

    log.info "Using GitPrime Tools at ${GITPRIME_TOOLS_HOME}"
else
    # Nope still don't have a home, we need to throw an error
    echo -e "ERROR: GITPRIME_TOOLS_HOME is not set.  Please set it in your .profile or .bashrc."
    echo -e "       This should have been automatically done when you ran the installer from:"
    echo ""
    echo -e "       https://raw.githubusercontent.com/gitprime/gitprime-tools/master/utility/install-tools.sh"

    exit 999
fi

# Ok, now that we're past all that, we can move on with logic
HOOK_ARGUMENTS=$@

HOOK_NAME=$(basename "$0")

declare -a HOOK_DIRECTORIES

# This directory should be the main hooks from the GitPrime tools.
HOOK_DIRECTORIES[0]="${GITPRIME_TOOLS_HOME}/git/hooks/${HOOK_NAME}"

# This directory should be any hooks in the project
HOOK_DIRECTORIES[1]="$(pwd)/.gp-tools/hooks/${HOOK_NAME}"

for HOOK_DIRECTORY in "${HOOK_DIRECTORIES[@]}"
do
    log.info "Doing Hooks In: ${HOOK_DIRECTORY}"

    if [[ -d "${HOOK_DIRECTORY}" ]];
    then
        for HOOK_FILE in "${HOOK_DIRECTORY}"/*
        do
            source "${HOOK_FILE}" ${HOOK_ARGUMENTS}

            if [[ $? -ne 0 ]];
            then
                log.error "Failed to execute hook at ${HOOK_DIRECTORY}/${HOOK_NAME}"

                exit 200
            fi
        done
    fi
done
