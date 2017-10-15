#!/bin/bash
#
# This code is licensed.  For details, please see the license file at
# https://github.com/gitprime/gitprime-tools/blob/master/LICENSE.md
#

# This script is intended to install the GitPrime tool set into
# a location specified.

# Some variables we need and will be setting

# The home directory for the tools
if [[ ! -z "${GITPRIME_TOOLS_HOME}" ]];
then
    GPT_HOME="${GITPRIME_TOOLS_HOME}"
else
    GPT_HOME=0
fi

# The base URL for tickets
if [[ ! -z "${GITPRIME_TOOLS_TICKET_URL}" ]];
then
    GPT_TICKET_URL="${GITPRIME_TOOLS_TICKET_URL}"
else
    GPT_TICKET_URL=0
fi

# Just a placeholder, we'll overwrite it
GPT_COLOR_ENABLED=""

# Setup colors for logging and stuff
#
# NOTE:  This is somewhat duplicated from the common.sh in library.  Sadly,
# NOTE:  we don't have it locally when this script is run, so we have to
# NOTE:  duplicate it.
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
                normal="$(tput sgr0)"
            fi
        fi

        export GPT_COLOR_ENABLED=1
    fi
}

# This is a simple log method.  It's not as advanced as we'd like,
# but it does the job.
#
# NOTE:  This is somewhat duplicated from the common.sh in library.  Sadly,
# NOTE:  we don't have it locally when this script is run, so we have to
# NOTE:  duplicate it.
function log_root()
{
    setup_colors

    MESSAGE="$*"

    HEADER="${bold}[GP-TOOLS]${normal}"

	echo -e "${HEADER} ${MESSAGE}"
}

# Parse the command line arguments we accept
function parse_options()
{
    output=0

    while test -n "$1"; do
        case "$1" in
            --home)
                GPT_HOME=$2
                shift 2
                ;;

            --ticket-base-url)
                GPT_TICKET_URL=$2
                shift 2
                ;;

            --help)
                output=2
                shift 1
                ;;

            *)
                shift
                ;;
        esac
    done

    return ${output}
}

# This function prints the help for the tool
function print_help()
{

}

# This method reacts to the given error code.  If the code is non-zero
# the method exits the script and logs the given message.
#
# NOTE:  This is totally duplicated from the common.sh in library.  Sadly,
# NOTE:  we don't have it locally when this script is run, so we have to
# NOTE:  duplicate it.
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

# Handles an exit based on the given code.
# All other parameters are treated as a message to log before exiting.
#
# NOTE:  This is totally duplicated from the common.sh in library.  Sadly,
# NOTE:  we don't have it locally when this script is run, so we have to
# NOTE:  duplicate it.
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