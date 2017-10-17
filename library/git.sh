#!/usr/bin/env bash
#
# This code is licensed.  For details, please see the license file at
# https://github.com/gitprime/gitprime-tools/blob/master/LICENSE.md
#
# This file contains functions used by git tools.

# A few constants

# Regex pattern for finding the ticket number in a branch name
BRANCH_TICKET_NUM_REGEX="^([a-zA-Z]{2,8}-[0-9]+)\/"

# Regex pattern for finding a ticket number at the start of a
# commit message
COMMIT_MSG_TICKET_NUM_REGEX="(^|\s)([a-zA-Z]{2,8}-[0-9]+)(:|\s|$)"

# Regex pattern for finding the ticket URL at the end of the
# commit message.
TICKET_URL_REGEX="^http[s]*:\/\/(.*?)\/([a-zA-Z]{2,8}-[0-9]+)$"

# This function retrieves a ticket number from the given content
# using the given regex.  It will only use the first uncommented
# line of the file.
#
# parameter: regex
# parameter: content to scan
#
# Echo's the ticket number if one is found
# Returns 1 if none is found.
function find_ticket_number()
{
	local TMP_REGEX="$1"

	local TMP_CONTENT="$2"

	# We first need to find the first line of the txt that isn't a comment
	local TMP_FIRST_LINE=0

	while read -r TMP_LINE
	do
		local TMP_LINE_TEST=$(echo -e "${TMP_LINE}" | tr -d '[:space:]')

		if [[ "${TMP_LINE_TEST:0:1}" != "#" ]];
		then
			TMP_FIRST_LINE="${TMP_LINE}"

			break
		fi
	done <<< "${TMP_CONTENT}"

    # Define the local variable before we execute.  Otherwise we get weird return codes
	local TMP_TICKET_NUM

	TMP_TICKET_NUM=$(echo "${TMP_FIRST_LINE}" | grep -oE "${TMP_REGEX}")

	if [[ $? -eq 0 ]];
	then
		# We found something, we just need to remove the trailing
		# characters and spaces
		TMP_TICKET_NUM=${TMP_TICKET_NUM%/}
		TMP_TICKET_NUM=${TMP_TICKET_NUM%:}

		TMP_TICKET_NUM=$(echo -e "${TMP_TICKET_NUM}" | tr -d '[:space:]')

		echo -n "${TMP_TICKET_NUM}"

		return 0
	else
	    return 1
	fi
}

# Attempts to find a ticket number from the branch name.
#
function find_branch_ticket_number()
{
    local TMP_OUTPUT=0

	local BRANCH_NAME

	BRANCH_NAME=$(git symbolic-ref --short HEAD)

	if [[ $? -eq 0 ]];
	then
		# Ok we got a branch name.  We just have to parse it.
		TMP_OUTPUT=$(find_ticket_number "${BRANCH_TICKET_NUM_REGEX}" "${BRANCH_NAME}")

		if [[ $? -ne 0 ]];
		then
		    # No go
            TMP_OUTPUT=0
		fi
	fi

	if [[ ${TMP_OUTPUT} -eq 0 ]];
	then
        exit 1
    fi

    echo -n "${TMP_OUTPUT}"
}