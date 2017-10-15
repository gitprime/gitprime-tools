#!/bin/bash
#
# This code is licensed.  For details, please see the license file at
# https://github.com/gitprime/gitprime-tools/blob/master/LICENSE.md
#
function validate_gpt_home()
{
    POTENTIAL_GPT_HOME="$1"

    VALID_GPT_HOME=1

    # The following are directories that we recognize as a valid GITPRIME_TOOLS_HOME
    declare -a TMP_SUBDIRS

    TMP_SUBDIRS[0]="aliases"
    TMP_SUBDIRS[1]="bin"
    TMP_SUBDIRS[2]="git"
    TMP_SUBDIRS[3]="library"
    TMP_SUBDIRS[4]="utility"

    COUNTER=0

    while [[ ${COUNTER} -lt 5 ]];
    do
        COUNTER=$((COUNTER + 1))

        if [[ ! -d "${POTENTIAL_GPT_HOME}/${TMP_SUBDIRS[COUNTER]}" ]];
        then
            VALID_GPT_HOME=0

            break
        fi
    done

    if [[ ${VALID_GPT_HOME} == 1 ]];
    then
        return 0
    fi

    return 1
}

function find_gpt_home()
{
    FOUND_HOME=0

    if [[ -z "${GITPRIME_TOOLS_HOME}" ]];
    then
        # We don't have a GITPRIME_TOOLS_HOME, but we may be able to find one.
        if [[ -d "${HOME}/.gitprime-tools" ]];
        then
            POTENTIAL_GPT_HOME="${HOME}/.gitprime-tools"

            validate_gpt_home "${POTENTIAL_GPT_HOME}"

            if [[ $? == 0 ]];
            then
                FOUND_HOME="${POTENTIAL_GPT_HOME}"
            fi
        fi


        if [[ ${FOUND_HOME} == 0 ]];
        then
            POTENTIAL_GPT_HOME="${BASH_SOURCE[0]}"

            if [[ -h "${POTENTIAL_GPT_HOME}" ]];
            then
                # This was a symlink, so we'll go find the root
                POTENTIAL_GPT_HOME=$(readlink -f "${POTENTIAL_GPT_HOME}")
            fi

            # Now we need the directory name
            POTENTIAL_GPT_HOME=$(dirname "${POTENTIAL_GPT_HOME}")

            # Ok, at this point we should end with /git/hooks.
            if [[ "${POTENTIAL_GPT_HOME}" == *"/git/hooks" ]];
            then
                # Ok, we're pretty sure this is a GitPrime tools home directory,
                # but we need to trim that off the end.
                POTENTIAL_GPT_HOME=${POTENTIAL_GPT_HOME::${#POTENTIAL_GPT_HOME}-10}
            fi
        fi
    else
        # Just use the one we have
        FOUND_HOME="${GITPRIME_TOOLS_HOME}"
    fi

    if [[ ${FOUND_HOME} == 0 ]];
    then
        return 1
    fi

    echo -n "${FOUND_HOME}"
}
