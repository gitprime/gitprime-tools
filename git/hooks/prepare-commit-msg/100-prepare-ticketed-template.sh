#!/bin/bash
#
# This code is licensed.  For details, please see the license file at
# https://github.com/gitprime/gitprime-tools/blob/master/LICENSE.md
#

# This is a hook for pre-recieve to validate that all commits in a
# push have the appropriate ticket format.

# First up, we need some includes
if [[ ! -z "${GITPRIME_TOOLS_HOME}" ]];
then
    # Ok, we have GITPRIME_TOOLS_HOME set.  We can use that as our base for includes
    source "${GITPRIME_TOOLS_HOME}/library/common.sh"
    source "${GITPRIME_TOOLS_HOME}/library/git.sh"
fi
