#!/usr/bin/env bash
#
# This code is licensed.  For details, please see the license file at
# https://github.com/gitprime/gitprime-tools/blob/master/LICENSE.md
#

# This file serves as the primary entry point for all the command-line
# GitPrime tools.  The idea is that this supports the concept of a
# tool that can be called as follows:
#
#    gp <command> <options>.
#
# Some examples:
#    gp update-tools
#    gp install-git-hooks

# First up, we need to be usre we have a home directory
if [[ -z "${GITPRIME_TOOLS_HOME}" ]];
then
    # Before we throw an error here, we're going to try some work to find the
    # home directory of the tools.  It's a cheap hack.
    POTENTIAL_GPT_HOME="${BASH_SOURCE[0]}"

    if [[ -h "${POTENTIAL_GPT_HOME}" ]];
    then
        # This was a symlink, so we'll go find the root
        POTENTIAL_GPT_HOME=$(readlink -f "${POTENTIAL_GPT_HOME}")
    fi

    # Now we're going to crawl up the directory tree to find a home
    POTENTIAL_GPT_HOME=$(dirname "${POTENTIAL_GPT_HOME}")

    while [[ -d "${POTENTIAL_GPT_HOME}" ]];
    do
        if [[ -f "${POTENTIAL_GPT_HOME}/library/common.sh" ]];
        then
            source "${POTENTIAL_GPT_HOME}/library/common.sh"

            if [[ $? == 0 ]];
            then
                validate_gpt_home "${POTENTIAL_GPT_HOME}"

                if [[ $? == 0 ]];
                then
                    # Found one!
                    GITPRIME_TOOLS_HOME="${POTENTIAL_GPT_HOME}"

                    export GITPRIME_TOOLS_HOME
                fi
            fi

            break
        fi

        # None found, so we'll go up another level
        POTENTIAL_GPT_HOME=$(dirname "${POTENTIAL_GPT_HOME}")
    done
fi

if [[ ! -z "${GITPRIME_TOOLS_HOME}" ]];
then
    # Ok, we have GITPRIME_TOOLS_HOME set.  We can use that as our base for includes
    source "${GITPRIME_TOOLS_HOME}/library/common.sh"
else
    # Nope still don't have a home, we need to throw an error
    echo -e "ERROR: GITPRIME_TOOLS_HOME is not set.  Please set it in your .profile or .bashrc."
    echo -e "       This should have been automatically done when you ran the installer from:"
    echo ""
    echo -e "       https://raw.githubusercontent.com/gitprime/gitprime-tools/master/utility/install-tools.sh"

    exit 999
fi

log.info "GitPrime Tools Called with: $@"