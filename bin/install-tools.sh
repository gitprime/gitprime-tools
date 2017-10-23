#!/usr/bin/env bash
#
# This code is licensed.  For details, please see the license file at
# https://github.com/gitprime/gitprime-tools/blob/master/LICENSE.md
#

# This script is intended to install the GitPrime tool set into
# a location specified.

# Some variables we need and will be setting

# The clone URL to use with GitHub to get the tools
GPT_CLONE_URL="https://github.com/gitprime/gitprime-tools.git"

# The home directory for the tools
if [[ ! -z "${GITPRIME_TOOLS_HOME}" ]]; then
  GPT_HOME="${GITPRIME_TOOLS_HOME}"
else
  GPT_HOME="${HOME}/.gitprime-tools"
fi

# The base URL for tickets
if [[ ! -z "${GITPRIME_TOOLS_TICKET_URL}" ]]; then
  GPT_TICKET_URL="${GITPRIME_TOOLS_TICKET_URL}"
else
  GPT_TICKET_URL=0
fi

# The header and footer lines where we hide stuff between.
GPT_HEADER_LINE="########################## GitPrime Tools START ##########################"
GPT_FOOTER_LINE="########################## GitPrime Tools STOP  ##########################"

# Just a placeholder, we'll overwrite it
INST_GPT_COLOR_ENABLED=0

# A tmp directory to do some work in
TMP_DIRECTORY=0

# Setup colors for logging and stuff
#
# NOTE:  This is somewhat duplicated from the common.sh in library.  Sadly,
# NOTE:  we don't have it locally when this script is run, so we have to
# NOTE:  duplicate it.
function setup_colors() {
  if [[ ${INST_GPT_COLOR_ENABLED} -eq 0 ]]; then
    # We've never set the GPT_COLOR_ENABLED before.  So we should
    # use our nifty logic to setup some color variables
    if test -t 1; then
      # see if it supports colors...
      local COLOR_TEST

      COLOR_TEST=$(tput colors)

      if test -n "${COLOR_TEST}" && test ${COLOR_TEST} -ge 8; then
        bold="$(tput bold)"
        normal="$(tput sgr0)"
      fi
    fi

    export INST_GPT_COLOR_ENABLED=1
  fi
}

# This is a simple log method.  It's not as advanced as we'd like,
# but it does the job.
#
# NOTE:  This is somewhat duplicated from the common.sh in library.  Sadly,
# NOTE:  we don't have it locally when this script is run, so we have to
# NOTE:  duplicate it.
function log() {
  setup_colors

  local MESSAGE="$*"

  local HEADER="${bold}[GP-TOOLS]${normal}"

  echo -e "${HEADER} ${MESSAGE}"
}

# Parse the command line arguments we accept
function parse_options() {
  local OUTPUT=0

  while test -n "$1"; do
    case "$1" in
    --home)
      if test -n "$2"; then
        GPT_HOME=$2
        shift 2
      else
        OUTPUT=3
        shift 1
      fi
      ;;

    --ticket-url)
      if test -n "$2"; then
        GPT_TICKET_URL=$2
        shift 2
      else
        OUTPUT=3
        shift 1
      fi
      ;;

    --help)
      OUTPUT=2
      shift 1
      ;;

    *)
      shift
      ;;
    esac
  done

  return ${OUTPUT}
}

# This function prints the help for the tool
function print_help() {
  log "This script installs the GitPrime Development Tools.  To use the tool"
  log "you can execute the installer with the following options: "
  log ""
  log "   --home:  Sets the home directory where the tools will be installed."
  log "            This defaults to ${HOME}/.gitprime-tools"
  log ""
  log "   --ticket-url:  Sets the base URL used for ticket lookups.  This should"
  log "                  expect that the ticket number will be pre-pended after "
  log "                  the URL.  This value has no default."
  log ""
  log "   --help:  Shows this help information."
  log ""
}

# This method reacts to the given error code.  If the code is non-zero
# the method exits the script and logs the given message.
#
# NOTE:  This is totally duplicated from the common.sh in library.  Sadly,
# NOTE:  we don't have it locally when this script is run, so we have to
# NOTE:  duplicate it.
function react_to_exit_code() {
  local EXIT_CODE=$1

  shift 1

  log_message="$*"

  if [[ ${EXIT_CODE} -ne 0 ]]; then
    handle_exit 1000 "$log_message"
  fi
}

# Handles an exit based on the given code.
# All other parameters are treated as a message to log before exiting.
#
# NOTE:  This is totally duplicated from the common.sh in library.  Sadly,
# NOTE:  we don't have it locally when this script is run, so we have to
# NOTE:  duplicate it.
function handle_exit() {
  local EXIT_CODE=$1

  shift

  if [[ ${TMP_DIRECTORY} -ne 0 ]]; then
    rm -fr "${TMP_DIRECTORY}"
  fi

  if [[ ! -z "$*" ]]; then
    log "Exiting: $*"
  fi

  exit "${EXIT_CODE}"
}

parse_options "$@"

OPTION_RESULTS=$?

if [[ ${OPTION_RESULTS} -eq 2 ]]; then
  print_help

  handle_exit 1
else
  react_to_exit_code ${OPTION_RESULTS} "Incorrect Options.  See help for more information."
fi

log "About to install the GitPrime Development tools to ${GPT_HOME}."

if [[ ${GPT_TICKET_URL} -ne 0 ]]; then
  # TODO: Make sure the URL has a trailing /
  log "Setting the base ticket URL to: ${GPT_TICKET_URL}"
fi

# Ok, we have enough data to continue, lets validate a few things.
TMP_BASE_DIR=$(dirname "${GPT_HOME}")

if [[ ! -w "${TMP_BASE_DIR}" ]]; then
  handle_exit 100 "No permission to create home directory at ${GPT_HOME}"
fi

# Ok, we need to clone the repo but we need to test for git before we try to clone
git --help > /dev/null 2>&1

if [[ $? -ne 0 ]]; then
  handle_exit 200 "Git does not seem to be present on this system.  Please make sure its installed and in the path."
fi

TMP_DIRECTORY=$(mktemp -d)

react_to_exit_code $? "Could not create appropriate temp directory"

log "Using temporary directory: ${TMP_DIRECTORY}"

git clone "${GPT_CLONE_URL}" "${TMP_DIRECTORY}/gitprime-tools" >/dev/null 2>&1

react_to_exit_code $? "Could not download the GitPrime Developer Tools."

log "Downloaded the installation package"

# Ok, we've cloned it, now we just need to copy it into place or *overwrite* the old version.
if [[ -d "${GPT_HOME}" ]]; then
  rm -fr "${GPT_HOME}"

  react_to_exit_code $? "Could not remove old copy of the GitPrime Developer Tools."
fi

mv "${TMP_DIRECTORY}/gitprime-tools" "${GPT_HOME}"

log "Installed GitPrime Developer Tools at ${GPT_HOME}"

export GITPRIME_TOOLS_HOME="${GPT_HOME}"

export GITPRIME_TOOLS_TICKET_URL="${GPT_TICKET_URL}"

# Ok, now that we've successfully done that, we can actually start using the tools
# that are built into our toolset. We can now load stuff we need
# shellcheck source=../library/common.sh
source "${GITPRIME_TOOLS_HOME}/library/common.sh"

# Our next major step is that we need to add something into the .bashrc or .profile of our
# user so that they have access to the environment and some other stuff.  We need
# to pick which one we want.  I believe we prefer .bashrc
declare -a ENV_FILES

ENV_FILES[0]="${HOME}/.bashrc"
ENV_FILES[1]="${HOME}/.profile"
ENV_FILES[2]="${HOME}/.bash_profile"

CHOSEN_ENV_FILE=0

for TEST_ENV_FILE in "${ENV_FILES[@]}"; do
  if [[ -f "${TEST_ENV_FILE}" ]]; then
    CHOSEN_ENV_FILE="${TEST_ENV_FILE}"

    break
  fi
done

if [[ "${CHOSEN_ENV_FILE}" == "0" ]]; then
  # Hmmm we don't see to have any of them.  We're going to check some things.
  CHOSEN_ENV_FILE=${ENV_FILES[0]}

  log.warn "No environment/profile file could be found.  We're defaulting to ${CHOSEN_ENV_FILE}"
fi

if [[ -f "${CHOSEN_ENV_FILE}" ]]; then
  # We're going to backup the old file
  TMP_DATE=$(date +%Y-%m-%d-%H-%M-%S)

  cp "${CHOSEN_ENV_FILE}" "${CHOSEN_ENV_FILE}.${TMP_DATE}.bak"
fi

log.info "Configuring GitPrime Development Tools to load from ${CHOSEN_ENV_FILE}"

# First thing, we remove any old settings
sed -i "/${GPT_HEADER_LINE}/,/${GPT_FOOTER_LINE}/d" "${CHOSEN_ENV_FILE}"

# Next, we just append our stuff to the end
echo "${GPT_HEADER_LINE}" >>"${CHOSEN_ENV_FILE}"

# Setup the home variable
echo "export GITPRIME_TOOLS_HOME=\"${GPT_HOME}\"" >>"${CHOSEN_ENV_FILE}"

# Setup the ticket variable if we have it
if [[ ${GPT_TICKET_URL} -ne 0 ]]; then
  echo "export GITPRIME_TOOLS_TICKET_URL=\"${GPT_TICKET_URL}\"" >>"${CHOSEN_ENV_FILE}"
fi

# Set the aliases to load
echo "source ${GPT_HOME}/library/aliases.sh" >>"${CHOSEN_ENV_FILE}"

# Close it out with the footer
echo "${GPT_FOOTER_LINE}" >>"${CHOSEN_ENV_FILE}"

log.info "Installation completed."

log.warn "The tools have been successfully installed.  However, you will not be able to"
log.warn "use them until you have reloaded your shell environment.  It is suggested that"
log.warn "you logout and log back in."

handle_exit 0
