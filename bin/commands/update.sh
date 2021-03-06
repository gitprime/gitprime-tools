#!/usr/bin/env bash
#
# This code is licensed.  For details, please see the license file at
# https://github.com/gitprime/gitprime-tools/blob/master/LICENSE.md
#

# The purpose of this command is simple:  Install the git hooks into
# the given git repository.  If none is specified, we'll check the
# local directory for a valid .git directory/database and assume
# this is where the user wants them.

# We need some includes
# shellcheck source=../../library/common.sh
source "${GITPRIME_TOOLS_HOME}/library/common.sh"
# shellcheck source=../../library/cli.sh
source "${GITPRIME_TOOLS_HOME}/library/cli.sh"

# The clone URL to use with GitHub to get the tools
INSTALL_ARCHIVE_BASE_URL="https://github.com/gitprime/gitprime-tools/archive/"

RELEASE_API_URL="https://api.github.com/repos/gitprime/gitprime-tools/releases"

UPDATE_TEMP_DIRECTORY=-1

# The required show_help function
function show_help() {
  log.info "The update command will attempt to update your version of the GitPrime"
  log.info "tool set."

  log.info

  show_argument_info
}

function add_arguments() {
  add_cli_argument "version" "v" ${GPT_ARG_TYPE_VALUE} 0 "The version number to update to.  Defaults to the latest."
  add_cli_argument "allow-prerelease" "p" ${GPT_ARG_TYPE_FLAG} 0 "If set, the updater will use pre-release versions of the tools."
  add_cli_argument "directory" "d" ${GPT_ARG_TYPE_VALUE} 0 "The directory where you want your new GitPrime Tools installation."
  add_cli_argument "ticket-url" "t" ${GPT_ARG_TYPE_VALUE} 0 "The URL of your ticket server to include in commit messages."
  add_cli_argument "list" "l" ${GPT_ARG_TYPE_FLAG} 0 "List the available updates"
}

# The required execute_gpt_command function
function execute_gpt_command() {
  UPDATE_TEMP_DIRECTORY=$(mktemp -d)

  local new_home="${GITPRIME_TOOLS_HOME}"
  local new_ticket_url="${GITPRIME_TOOLS_TICKET_URL}"

  local version=$(get_argument_value "version")
  local allow_prerelease=$(get_argument_value "allow-prerelease")
  local new_home_test=$(get_argument_value "directory")
  local new_ticket_url_test=$(get_argument_value "ticket-url")
  local do_list=$(get_argument_value "list")

  if [[ ! -z "${new_home_test}" ]] && [[ "${new_home_test}" != "0" ]]; then
    new_home="${new_home_test}"
  fi

  if [[ ! -z "${new_ticket_url_test}" ]] && [[ "${new_ticket_url_test}" != "0" ]]; then
    new_ticket_url="${new_ticket_url_test}"
  fi

  if [[ ${do_list} == 1 ]]; then
    log.warn "GitPrime Tools Releases:"
    log.info
  fi

  local download_url=0

  if [[ -z "${version}" ]]; then
    # Well, crap, we're going to have to go dig around on GitHub to find the latest version of the
    # damn thing.
    #
    # We need to verify that they have jq first
    local has_jq=$(which jq)

    react_to_exit_code $? "You must have the tool 'jq' installed to find the latest version automatically"

    local release_file="${UPDATE_TEMP_DIRECTORY}/releases.json"
    local parsed_release_file="${UPDATE_TEMP_DIRECTORY}/releases.csv"

    curl --url "${RELEASE_API_URL}" --silent --fail --output "${release_file}"

    react_to_exit_code $? "Could not get version data from GitHub"

    jq -r '.[] | "\(.name);\(.created_at);\(.prerelease);\(.tarball_url)"' "${release_file}" > "${parsed_release_file}"

    react_to_exit_code $? "Could not parse release information"

    # Now we have the data, we just need to parse the file line by line and find the best match
    local best_date=0

    local rel_name=0
    local rel_date=0
    local rel_prerelease=0
    local rel_url=0

    while IFS='' read -r line || [[ -n "${line}" ]]; do
      # Parse out the URL and create date
      IFS=';' read -ra arg_split <<< "${line}"

      rel_name="${arg_split[0]}"
      rel_date="${arg_split[1]}"
      rel_prerelease="${arg_split[2]}"
      rel_url="${arg_split[3]}"

      if [[ ${allow_prerelease} == 0 ]]; then
        # We're not allowing pre-releases, so we need to skip this if it is a pre-release
        if [[ "${rel_prerelease}" == "true" ]]; then
          continue
        fi
      fi

      # Convert create_data into an integer so we can compare
      # Macs have a broken date command.  Its just not nearly as functional as the regular one found in most
      # modern *nix systems.  So, to deal with that, we're doing a little test.
      date -j > /dev/null 2>&1

      if [[ $? == 0 ]]; then
        # We have to use the mac date command
        rel_date=$(date -j -f "%Y-%m-%dT%H:%M:%S" "${rel_date}" +"%s" 2>/dev/null)
      else
        # We'll use the good date command
        rel_date=$(date -d "${rel_date}" +"%s")
      fi

      if [[ ${rel_date} -gt ${best_date} ]]; then
        best_date=${rel_date}

        download_url="${rel_url}"

        version="${rel_name}"
      fi

      if [[ ${do_list} == 1 ]]; then
        log.info "  GitPrime Tools Release ${rel_name} (${arg_split[1]}): ${rel_url}"
      fi
    done < "${parsed_release_file}"

    if [[ ${do_list} == 1 ]]; then
      log.info
      log.warn "Latest Release ${version}: ${download_url}"
    fi

    if [[ ${download_url} == 0 ]]; then
      log.error "Unable to find the current download version."

      return 1
    fi
  else
    download_url="${INSTALL_ARCHIVE_BASE_URL}/${version}"
  fi

  if [[ ${do_list} == 1 ]]; then
    # No need to continue
    return 0
  fi

  log.info "Getting download from: ${download_url}"

  local archive_file="${UPDATE_TEMP_DIRECTORY}/update.tar.gz"

  curl --url "${download_url}" --output "${archive_file}" --location --silent --fail

  react_to_exit_code $? "Unable to download update artifact."

  # Ok, we have the archive, now we need to decompress it
  tar -xzf "${archive_file}" --directory "${UPDATE_TEMP_DIRECTORY}"

  react_to_exit_code $? "Unable to decompress update artifact."

  # This should have created a directory with the tools in it.  However, that is going to be labeled with
  # the version number/title.  We'll need to deal with that
  local artifact_dir=$(find "${UPDATE_TEMP_DIRECTORY}" -type d -name "gitprime-gitprime-tools-*")

  if [[ -d "${artifact_dir}" ]]; then
    # Woo hoo! We found the directory, we just need to replace the old one.
    rm -fr ${new_home}

    react_to_exit_code $? "Unable to delete current version of GitPrime tools.  You will have to re-install manually."

    local home_parent=$(dirname ${new_home})

    if [[ ! -d "${home_parent}" ]]; then
      mkdir -p "${home_parent}"

      react_to_exit_code $? "Unable to create GitPrime Tools home: ${new_home}"
    fi

    mv "${artifact_dir}" "${new_home}"

    react_to_exit_code $? "Unable to install GitPrime Tools at ${new_home}"

    if [[ "${new_home}" != "${GITPRIME_TOOLS_HOME}" ]]; then
      update_environment_files "${new_home}" "${new_ticket_url}"

      log.warn "You specified a new home directory that does not match your currently installed version."
      log.warn "You will need to update your reload your shell for changes to take effect."
    fi

    log.info "Successfully updated GitPrime Tools to version ${version}."
  else
    log.error "The expected files were not found in the update artifact."

    return 1
  fi
}

function destroy() {
  # Nothing really to do here.
  if [[ "${UPDATE_TEMP_DIRECTORY}" != 0 ]]; then
    rm -fr "${UPDATE_TEMP_DIRECTORY}"
  fi
}
