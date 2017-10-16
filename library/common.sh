#!/usr/bin/env bash
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
            local COLOR_TEST

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

# This method is a generic logging method that takes 3 basic levels:
#
#    INFO: General information
#    WARN: Something that should be brought to a user's attention
#    ERROR: Something very serious.
#
# Parameters:
#    level:  The appropriate level
#    message:  The message to log.
function log_root()
{
    setup_colors

    # We'll use level to build a header
    local LEVEL="$1"

    shift 1

    local MESSAGE="$*"

    local HEADER="[GP-TOOLS]"

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

# Logs the given message at an "INFO" level
function log.info
{
    log_root "INFO" "$*"
}

# Alias for the log.info function
function log
{
    log.info "$*"
}

# Logs the given message at a "WARN" level
function log.warn
{
    log_root "WARN" "$*"
}

# Logs the given message at an "ERROR" level
function log.error
{
    log_root "ERROR" "$*"
}

# This method reacts to the given error code.  If the code is non-zero
# the method exits the script and logs the given message.
function react_to_exit_code()
{
    local EXIT_CODE=$1

    shift 1

    log_message="$*"

    if [[ ${EXIT_CODE} != 0 ]];
    then
        handle_exit 1000 "$log_message"
    fi
}

# Handles an exit based on the given code.
# All other parameters are treated as a message to log before exiting.
function handle_exit()
{
    local EXIT_CODE=$1

    shift

    if [[ ! -z "$@" ]];
    then
        if [[ ${EXIT_CODE} == 0 ]];
        then
            log.info "Exiting: $*"
        else
            log.error "Exiting with error: $*"
        fi
    fi

    exit "${EXIT_CODE}"
}

# This validates that a given directory is a valid GPT home directory.
function validate_gpt_home()
{
    local POTENTIAL_GPT_HOME="$1"

    local VALID_GPT_HOME=1

    # The following are directories that we recognize as a valid GITPRIME_TOOLS_HOME
    declare -a TMP_SUB_DIRS

    TMP_SUB_DIRS[0]="bin"
    TMP_SUB_DIRS[1]="bin/commands"
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

# Attempts to find a valid GTP home directory.  It does this with the
# following logic:
#
#    1. Look for the GITPRIME_TOOLS_HOME environment variable to be set
#    2. Look for a .gitprime-tools directory in the user's home directory.
#    3. Use the current running script to try and find one in the root
#
# If a home is found, we echo the full path
# If none can be found, we return 1.
function find_gpt_home()
{
    local STARTING_POINT="$1"

    local FOUND_HOME=0

    local OUTPUT=""

    if [[ -z "${GITPRIME_TOOLS_HOME}" ]];
    then
        # We don't have a GITPRIME_TOOLS_HOME, but we may be able to find one.
        if [[ -d "${HOME}/.gitprime-tools" ]];
        then
            OUTPUT="${HOME}/.gitprime-tools"

            validate_gpt_home "${OUTPUT}"

            if [[ $? == 0 ]];
            then
                FOUND_HOME="${OUTPUT}"
            fi
        fi

        if [[ ${FOUND_HOME} == 0 ]];
        then
            OUTPUT="${STARTING_POINT}"

            if [[ -h "${OUTPUT}" ]];
            then
                # This was a symlink, so we'll go find the root
                OUTPUT=$(readlink -f "${OUTPUT}")
            fi

            # Now we need the directory name
            OUTPUT=$(dirname "${OUTPUT}")

            # Start crawling up the directories until we find a good GPT home.
            while [[ -d "${OUTPUT}" ]];
            do
                validate_gpt_home "${OUTPUT}"

                if [[ $? == 0 ]];
                then
                    # We found one.  Set it for output and break
                    FOUND_HOME="${OUTPUT}"

                    break
                fi

                # None found, so we'll go up another level
                OUTPUT=$(dirname "${OUTPUT}")
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
