#!/usr/bin/env bash
#
# This code is licensed.  For details, please see the license file at
# https://github.com/gitprime/gitprime-tools/blob/master/LICENSE.md
#

# This script is intended to install the GitPrime tool set into
# a location specified.

# Some variables we need and will be setting

# The home directory for the tools
if [[ ! -z "${GITPRIME_TOOLS_HOME}" ]]; then
  GPT_HOME="${GITPRIME_TOOLS_HOME}"
else
  GPT_HOME="${HOME}/.gitprime-tools"
fi

# The directory we're running in so that we can source some stuff
CMD_BASE_DIR=$0

CMD_BASE_DIR=$(dirname "${CMD_BASE_DIR}")

if [[ "${CMD_BASE_DIR}" != "/"* ]]; then
  # We used a relative path, we'll add the current working directory
  CMD_BASE_DIR="$(pwd)/${CMD_BASE_DIR}"
fi

if [[ "${CMD_BASE_DIR}" == *"/bin" ]]; then
  CMD_BASE_DIR=$(dirname "${CMD_BASE_DIR}")
fi

if [[ -d "${GPT_HOME}" ]]; then
  log "Removing previous installation of tools from ${GPT_HOME}"

  rm -fr "${GPT_HOME}"

  react_to_exit_code $? "Unable to remove previous installation from ${GPT_HOME}"
fi

# shellcheck source=../../library/common.sh
source "${CMD_BASE_DIR}/library/common.sh"
# shellcheck source=../../library/cli.sh
source "${CMD_BASE_DIR}/library/cli.sh"

# The base URL for tickets
if [[ ! -z "${GITPRIME_TOOLS_TICKET_URL}" ]]; then
  GPT_TICKET_URL="${GITPRIME_TOOLS_TICKET_URL}"
else
  GPT_TICKET_URL=0
fi

# The header and footer lines where we hide stuff between.
GPT_HEADER_LINE="########################## GitPrime Tools START ##########################"
GPT_FOOTER_LINE="########################## GitPrime Tools STOP  ##########################"

# A tmp directory to do some work in
TMP_DIRECTORY=0

function add_arguments() {
  add_cli_argument "help" "h" ${GPT_ARG_TYPE_FLAG} 0 "Show the help information."
  add_cli_argument "home-directory" "d" ${GPT_ARG_TYPE_VALUE} 0 "The directory where you want your new GitPrime Tools installation."
  add_cli_argument "ticket-url" "t" ${GPT_ARG_TYPE_VALUE} 0 "The URL of your ticket server to include in commit messages."
}

add_arguments

parse_cli_arguments "$@"

if [[ ${#GPT_ARG_PARSER_ERRORS} -gt 0 ]]; then
  log.error "There were invalid command options: "

  show_help

  handle_exit 1
fi

log "About to install the GitPrime Development tools to ${GPT_HOME}."

if [[ ${GPT_TICKET_URL} != 0 ]]; then
  if [[ "${GPT_TICKET_URL}" != *"/" ]]; then
    GPT_TICKET_URL="${GPT_TICKET_URL}/"
  fi

  log "Setting the base ticket URL to: ${GPT_TICKET_URL}"
fi

# Ok, we have enough data to continue, lets validate a few things.
TMP_BASE_DIR=$(dirname "${GPT_HOME}")

if [[ ! -w "${TMP_BASE_DIR}" ]]; then
  handle_exit 100 "No permission to create home directory at ${GPT_HOME}"
fi

cp -R "${CMD_BASE_DIR}" "${GPT_HOME}"

react_to_exit_code $? "Unable to copy installation to ${GPT_HOME}"

export GITPRIME_TOOLS_HOME="${GPT_HOME}"

export GITPRIME_TOOLS_TICKET_URL="${GPT_TICKET_URL}"

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

log "Configuring GitPrime Development Tools to load from ${CHOSEN_ENV_FILE}"

# First thing, we remove any old settings
sed -i "/${GPT_HEADER_LINE}/,/${GPT_FOOTER_LINE}/d" "${CHOSEN_ENV_FILE}"

# Next, we just append our stuff to the end
echo "${GPT_HEADER_LINE}" >>"${CHOSEN_ENV_FILE}"

# Setup the home variable
echo "export GITPRIME_TOOLS_HOME=\"${GPT_HOME}\"" >>"${CHOSEN_ENV_FILE}"

# Setup the ticket variable if we have it
if [[ ${GPT_TICKET_URL} != 0 ]]; then
  echo "export GITPRIME_TOOLS_TICKET_URL=\"${GPT_TICKET_URL}\"" >>"${CHOSEN_ENV_FILE}"
fi

# Set the aliases to load
echo "source ${GPT_HOME}/library/aliases.sh" >>"${CHOSEN_ENV_FILE}"

# Close it out with the footer
echo "${GPT_FOOTER_LINE}" >>"${CHOSEN_ENV_FILE}"

log "Installation completed."
log ""
log.important "The tools have been successfully installed.  However, you will not be able to"
log.important "use them until you have reloaded your shell environment.  It is suggested that"
log.important "you logout and log back in."

handle_exit 0
