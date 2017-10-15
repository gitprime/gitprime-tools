#!/bin/bash
#
# This code is licensed.  For details, please see the license file at
# https://github.com/gitprime/gitprime-tools/blob/master/LICENSE.md
#
# This file contains functions used by git tools.

# This function retrieves a ticket number from the given content
# using the given regex.  It will only use the first uncommented
# line of the file.
#
# parameter: regex
# parameter: content to scan
function find_ticket_number()
{
	TMP_REGEX="$1"

	TMP_CONTENT="$2"

	# We first need to find the first line of the txt that isn't a comment
	TMP_FIRST_LINE=0

	while read -r TMP_LINE
	do
		TMP_LINE_TEST=$(echo -e "${TMP_LINE}" | tr -d '[:space:]')

		if [[ "${TMP_LINE_TEST:0:1}" != "#" ]];
		then
			TMP_FIRST_LINE="${TMP_LINE}"

			break
		fi
	done <<< "${TMP_CONTENT}"

	TMP_TICKET_NUM=$(echo "${TMP_FIRST_LINE}" | grep -oE "${TMP_REGEX}")

	if [[ $? == 0 ]];
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