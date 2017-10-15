#!/bin/bash
#
# This code is licensed.  For details, please see the license file at
# https://github.com/gitprime/gitprime-tools/blob/master/LICENSE.md
#

# Before we log anything, we need to setup some colors.  We found some neat stuff at:
# https://unix.stackexchange.com/questions/9957/how-to-check-if-bash-can-print-colors.
# This function will setup the colors once if they haven't been already
function setup_colors()
{
    if [[ -z ${GPT_COLOR_ENABLED} ]];
    then
        # We've never set the GPT_COLOR_ENABLED before.  So we should
        # use our nifty logic to setup some color variables
        if test -t 1; then
            # see if it supports colors...
            COLOR_TEST=$(tput colors)

            if test -n "${COLOR_TEST}" && test ${COLOR_TEST} -ge 8;
            then
                bold="$(tput bold)"
                underline="$(tput smul)"
                standout="$(tput smso)"
                normal="$(tput sgr0)"
                black="$(tput setaf 0)"
                red="$(tput setaf 1)"
                green="$(tput setaf 2)"
                yellow="$(tput setaf 3)"
                blue="$(tput setaf 4)"
                magenta="$(tput setaf 5)"
                cyan="$(tput setaf 6)"
                white="$(tput setaf 7)"
            fi
        fi

        export GPT_COLOR_ENABLED=1
    fi
}

function log_root()
{
    setup_colors

    # We'll use level to build a header
    LEVEL="$1"

    shift 1

    MESSAGE="$*"

    HEADER="[GP-TOOLS]"

    if [[ "${LEVEL}" == "ERROR" ]];
    then
        HEADER="${red}${HEADER}"
    fi

    if [[ "${LEVEL}" == "WARN" ]];
    then
        HEADER="${yellow}${HEADER}"
    fi

    HEADER="${bold}${HEADER}${normal}"

	echo -e "${HEADER} ${MESSAGE}"
}

function log.info
{
    log_root "INFO" "$*"
}

function log
{
    log.info "$*"
}

function log.warn
{
    log_root "WARN" "$*"
}

function log.error
{
    log_root "ERROR" "$*"
}


function react_to_exit_code()
{
    exit_code=$1

    shift 1

    log_message="$*"

    if [[ ${exit_code} != 0 ]];
    then
        handle_exit 1000 "$log_message"
    fi
}

function handle_exit()
{
    EXIT_CODE=$1

    shift

    if [[ ! -z "$@" ]];
    then
        log "Exiting: $*"
    fi

    exit "${EXIT_CODE}"
}

function validate_gpt_home()
{
    POTENTIAL_GPT_HOME="$1"

    VALID_GPT_HOME=1

    # The following are directories that we recognize as a valid GITPRIME_TOOLS_HOME
    declare -a TMP_SUB_DIRS

    TMP_SUB_DIRS[0]="aliases"
    TMP_SUB_DIRS[1]="bin"
    TMP_SUB_DIRS[2]="git"
    TMP_SUB_DIRS[3]="library"
    TMP_SUB_DIRS[4]="utility"

    for TMP_SUB_DIR in "${TMP_SUB_DIRS[@]}"
    do
        if [[ ! -d "${POTENTIAL_GPT_HOME}/${TMP_SUB_DIR}" ]];
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
    STARTING_POINT="$1"

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
            POTENTIAL_GPT_HOME="${STARTING_POINT}"

            if [[ -h "${POTENTIAL_GPT_HOME}" ]];
            then
                # This was a symlink, so we'll go find the root
                POTENTIAL_GPT_HOME=$(readlink -f "${POTENTIAL_GPT_HOME}")
            fi

            # Now we need the directory name
            POTENTIAL_GPT_HOME=$(dirname "${POTENTIAL_GPT_HOME}")

            # Start crawling up the directories until we find a good GPT home.
            while [[ -d "${POTENTIAL_GPT_HOME}" ]];
            do
                validate_gpt_home "${POTENTIAL_GPT_HOME}"

                if [[ $? == 0 ]];
                then
                    # We found one.  Set it for output and break
                    FOUND_HOME="${POTENTIAL_GPT_HOME}"

                    break
                fi

                # None found, so we'll go up another level
                POTENTIAL_GPT_HOME=$(dirname "${POTENTIAL_GPT_HOME}")
            done
        fi
    else
        # Just use the one we have set in the environment already
        FOUND_HOME="${GITPRIME_TOOLS_HOME}"
    fi

    if [[ ${FOUND_HOME} == 0 ]];
    then
        return 1
    fi

    echo -n "${FOUND_HOME}"
}
