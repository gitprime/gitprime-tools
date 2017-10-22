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

# A function to load our subcommands and validate them.
function load_and_validate_command() {
  local output=0

  # An array of functions we require
  declare -a valid_contract_functions

  valid_contract_functions+=("show_help")
  valid_contract_functions+=("add_arguments")
  valid_contract_functions+=("execute_gpt_command")
  valid_contract_functions+=("destroy")

  local command_name="$1"

  local command_path="${GITPRIME_TOOLS_HOME}/bin/commands/${command_name}.sh"

  # shellcheck disable=SC1090
  # Disabled linter because this is completely dynamic
  source "${command_path}"

  if [[ -f "${command_path}" ]]; then
    # We've sourced it in, now we just need to be 100% sure that we have loaded
    # something that we can use.
    for contract_test in "${valid_contract_functions[@]}"; do
      test_output=$(type -t "${contract_test}")

      if [[ $? -eq 0 ]]; then
        if [[ ${test_output} != "function" ]]; then
          # Ok, there is no show_help function, this is invalid.
          log.error "Command processor '${command_name}' is invalid.  It does not include the required '${contract_test}' function."

          output=1
        fi
      else
        log.error "Command processor '${command_name}' is invalid.  It does not include the required '${contract_test}' function."

        output=1
      fi
    done
  else
    # We technically should never get this far, but just in case.
    log.error "Command ${command_name} does not exist in the GitPrime Development Tools home directory."

    output=1
  fi

  return ${output}
}

# First up, we need to be usre we have a home directory
if [[ -z "${GITPRIME_TOOLS_HOME}" ]]; then
  # Before we throw an error here, we're going to try some work to find the
  # home directory of the tools.  It's a cheap hack.
  POTENTIAL_GPT_HOME="${BASH_SOURCE[0]}"

  if [[ -L "${POTENTIAL_GPT_HOME}" ]]; then
    # This was a symlink, so we'll go find the root
    POTENTIAL_GPT_HOME=$(readlink -f "${POTENTIAL_GPT_HOME}")
  fi

  # Now we're going to crawl up the directory tree to find a home
  POTENTIAL_GPT_HOME=$(dirname "${POTENTIAL_GPT_HOME}")

  while [[ -d "${POTENTIAL_GPT_HOME}" ]]; do
    if [[ -f "${POTENTIAL_GPT_HOME}/library/common.sh" ]]; then
      # shellcheck source=../library/common.sh
      source "${POTENTIAL_GPT_HOME}/library/common.sh"

      if [[ $? -eq 0 ]]; then
        validate_gpt_home "${POTENTIAL_GPT_HOME}"

        if [[ $? -eq 0 ]]; then
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

if [[ ! -z "${GITPRIME_TOOLS_HOME}" ]]; then
  # Ok, we have GITPRIME_TOOLS_HOME set.  We can use that as our base for includes
  # shellcheck source=../library/common.sh
  source "${GITPRIME_TOOLS_HOME}/library/common.sh"
  # shellcheck source=../library/cli.sh
  source "${GITPRIME_TOOLS_HOME}/library/cli.sh"
else
  # Nope still don't have a home, we need to throw an error
  echo -e "ERROR: GITPRIME_TOOLS_HOME is not set.  Please set it in your .profile or .bashrc."
  echo -e "       This should have been automatically done when you ran the installer from:"
  echo ""
  echo -e "       https://raw.githubusercontent.com/gitprime/gitprime-tools/master/utility/install-tools.sh"

  exit 999
fi

GPT_FUNCTION_MODE="execute"

OUR_COMMAND="$1"

shift

if [[ "${OUR_COMMAND}" == "help" ]]; then
  # If we got help, we're moving to help mode.
  GPT_FUNCTION_MODE="help"

  OUR_COMMAND="$1"

  shift
fi

declare -a OUR_ARGUMENTS

while [[ ! -z $1 ]]; do
  OUR_ARGUMENTS+=("$1")

  shift
done

populate_valid_command_array

if [[ -z "${OUR_COMMAND}" ]]; then
  # Hmmm no command is specified.  This is fine if we're doing "help"
  # but otherwise we need to throw an error.
  if [[ "${GPT_FUNCTION_MODE}" != "help" ]]; then
    handle_exit 1 "No command was specified. You must specify a command."
  fi

  log.error "GitPrime Development Tools command reference:"
  log.info "Proper syntax: gpt <command name> <options>"
  log.info ""
  log.info "Available Commands:"

  for available_command in "${GPT_VALID_COMMANDS[@]}"; do
    # shellcheck disable=SC2154
    log.info "    ${bold}${available_command}${normal}"
  done

  log.info ""
  log.info "For help on a specific command, you can execute: gpt help <command name>"
else
  # Ok, we got a valid command.  We can execute what we're supposed to.

  if array_contains_value "${OUR_COMMAND}" "${GPT_VALID_COMMANDS[@]}"; then
    load_and_validate_command "${OUR_COMMAND}"

    if [[ $? == 0 ]]; then
      if [[ ${GPT_FUNCTION_MODE} == "help" ]]; then
        add_arguments

        show_help "${OUR_COMMAND}"
      else
        # Ask the tool to add appropriate arguments
        add_arguments

        if [[ ${#OUR_ARGUMENTS[@]} -gt 0 ]]; then
          # We need to parse the arguments.  That means its up to us.
          parse_cli_arguments "${OUR_ARGUMENTS[@]}"
        fi

        # Ok, we're not doing help, instead we're doing the actual action.
        execute_gpt_command
      fi
    else
      log.error "The command ${OUR_COMMAND} cannot be processed."
    fi
  else
    log.info "Invalid command: ${OUR_COMMAND}"
  fi
fi
