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
function load_and_validate_command()
{
    local output=0

    # An array of functions we require
    declare -a valid_contract_functions

    valid_contract_functions[0]="show_help"
    valid_contract_functions[1]="execute_gpt_command"

    local command_name="$1"

    local command_path="${GITPRIME_TOOLS_HOME}/bin/commands/${command_name}.sh"

    source "${command_path}"

    if [[ -f "${command_path}" ]];
    then
        # We've sourced it in, now we just need to be 100% sure that we have loaded
        # something that we can use.
        for contract_test in "${valid_contract_functions[@]}";
        do
            test_output=$(type -t show_help)

            if [[ $? -eq 0 ]];
            then
                if [[ ${test_output} != "function" ]];
                then
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

            if [[ $? -eq 0 ]];
            then
                validate_gpt_home "${POTENTIAL_GPT_HOME}"

                if [[ $? -eq 0 ]];
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
    source "${GITPRIME_TOOLS_HOME}/library/cli-tools.sh"
else
    # Nope still don't have a home, we need to throw an error
    echo -e "ERROR: GITPRIME_TOOLS_HOME is not set.  Please set it in your .profile or .bashrc."
    echo -e "       This should have been automatically done when you ran the installer from:"
    echo ""
    echo -e "       https://raw.githubusercontent.com/gitprime/gitprime-tools/master/utility/install-tools.sh"

    exit 999
fi

OUR_COMMAND="$1"

shift

OUR_ARGUMENTS=$@

populate_valid_command_array

if array_contains_value "${OUR_COMMAND}" "${GPT_VALID_COMMANDS[@]}";
then
    # Ok, we go this far, now we need to do some logic
    if [[ "${OUR_COMMAND}" == "help" ]];
    then
        # We're going to keep the help logic embedded inside this tool.
        # In the future, we could technically move it out to its own
        # command in the commands directory.
        #
        # To do this, we're going to actually need to load the command
        # if its valid.  This means basically repeating the logic we just did with
        # new arguments
        show_help
    else
        load_and_validate_command "${OUR_COMMAND}"

        if [[ $? == 0 ]];
        then
            # Ok, we're not doing help, instead we're doing the actual action.
            execute_gpt_command "${OUR_COMMAND}" $OUR_ARGUMENTS
        else
            log.error "The command ${OUR_COMMAND} cannot be processed."
        fi
    fi
else
    log.info "Invalid command: ${OUR_COMMAND}"
fi
