#!/bin/bash
#
# This code is licensed.  For details, please see the license file at
# https://github.com/gitprime/gitprime-tools/blob/master/LICENSE.md
#
# This is a commit-msg hook that captures whether or not a developer
# has appropriately added a ticket number to their commit message. A
# ticket number is valid if it meets the pattern:
#     (^|\s)([a-zA-Z]{2,8}-[0-9]+)(:|\s|$)
# 
# To do this, we follow several steps of logic:
#
#   1. Does the commit message start with a ticket number.  If it does,
#      that is the ticket number we want to use.
#
#   2. If it does not, we check the branch name.  If the branch name
#      follows the format of <ticket number>/<something> we will take
#      the ticket number from there.
#
#   3. Once we have a ticket number, we will insure that the commit
#      message located in the given file starts with the ticket 
#      number we provided.
#
#   4. We will also make sure that there is a URL that contains
#      the ticket number on the last line of the commit message.

# First up, we need some includes
if [[ ! -z "${GITPRIME_TOOLS_HOME}" ]];
then
    # Ok, we have GITPRIME_TOOLS_HOME set.  We can use that as our base for includes
    source "${GITPRIME_TOOLS_HOME}/library/common.sh"
    source "${GITPRIME_TOOLS_HOME}/library/git.sh"
fi

# Regex pattern for finding the ticket number in a branch name
BRANCH_REGEX="^([a-zA-Z]{2,8}-[0-9]+)\/"

# Regex pattern for finding a ticket number at the start of a
# commit message
COMMIT_MSG_REGEX="(^|\s)([a-zA-Z]{2,8}-[0-9]+)(:|\s|$)"

# Regex pattern for finding the ticket URL at the end of the
# commit message.
URL_REGEX="^http[s]*:\/\/(.*?)\/([a-zA-Z]{2,8}-[0-9]+)$"

# First, we need to check the commit message data:
COMMIT_MSG_FILE="$1"

COMMIT_MSG_DATA=$(cat "${COMMIT_MSG_FILE}")

BRANCH_TICKET_NUM=0
COMMIT_MSG_TICKET_NUM=0

FINAL_TICKET_NUM=$(find_ticket_number "${COMMIT_MSG_REGEX}" "${COMMIT_MSG_DATA}")

if [[ $? == 0 ]];
then
	# We found it in the commit msg, so we're going to record that.
	COMMIT_MSG_TICKET_NUM=${FINAL_TICKET_NUM}
else
    # We didn't find it, we'll try again
	BRANCH_NAME=$(git symbolic-ref --short HEAD)
		
	if [[ $? == 0 ]];
	then
		# Ok we got a branch name.  We just have to parse it.
		FINAL_TICKET_NUM=$(find_ticket_number "${BRANCH_REGEX}" "${BRANCH_NAME}")
		
		if [[ $? == 0 ]];
		then
			# We found it!
			BRANCH_TICKET_NUM=${FINAL_TICKET_NUM}
		else
            FINAL_TICKET_NUM=0
		fi
    else
        FINAL_TICKET_NUM=0
	fi
fi

if [[ ${FINAL_TICKET_NUM} == 0 ]];
then
	# Ok, we couldn't find a ticket number at all.  We need to print that out and exit.
	log.error "Could not find a valid ticket number in the commit message."
	log.error "You must supply a ticket number at the beginning of the commit message"
	log.error "or at the beginning of the branch name.  For example:"
	log.error ""
	log.error "   ${bold}Commit Message${normal}: TICK-1234: This is a good message"
	log.error "   ${bold}Branch Name${normal}:    TICK-1234/This-is-a-good-branch"
	
	exit 100
fi

# Little boolean to determine if we need to write out a new message.
WRITE_NEW_MSG=0

# Ok, we were able to find a ticket number.  Now we just need to alter the commit
# msg if we can.
if [[ ${COMMIT_MSG_TICKET_NUM} == 0 ]];
then
	# There was no ticket number at the start of the commit.  We're
	# going to have to add it in.
	COMMIT_MSG_DATA="${FINAL_TICKET_NUM}: ${COMMIT_MSG_DATA}"
	
	WRITE_NEW_MSG=1
fi

# Now we just need to see if there is a URL at the bottom of the commit message.
# This is a bit tricky, since we need to ignore any commented lines in the
# commit message.  So we're going to find the LAST line of text that isn't
# commented and make sure it fits a URL pattern with the ticket number
# in it.
TMP_LAST_LINE=0

while read -r TMP_LINE
do
	TMP_LINE_TEST=$(echo -e "${TMP_LINE}" | tr -d '[:space:]')
	
	if [[ "${TMP_LINE_TEST:0:1}" != "#" ]];
	then
		TMP_LAST_LINE="${TMP_LINE}"
	fi
done <<< "${COMMIT_MSG_DATA}"

if [[ "${GITPRIME_TOOLS_TICKET_URL}" == "" ]];
then
	log.warn "Could not find a base URL for showing tickets.  Please define it using: "
	log.warn "   export GITPRIME_TOOLS_TICKET_URL=<url to your tickets>"
else
    URL_TEST=$(echo "${TMP_LAST_LINE}" | grep -oE "${URL_REGEX}")

    URL_TEST_RESULT=$?

    if [[ ${URL_TEST_RESULT} != 0 ]];
    then
        COMMIT_MSG_DATA=$(echo -e "${COMMIT_MSG_DATA}\n\n${GITPRIME_TOOLS_TICKET_URL}/${FINAL_TICKET_NUM}")

        WRITE_NEW_MESSAGE=1
    fi
fi

if [[ ${WRITE_NEW_MESSAGE} == 1 ]];
then
    echo "${COMMIT_MSG_DATA}" > "${COMMIT_MSG_FILE}"
fi
