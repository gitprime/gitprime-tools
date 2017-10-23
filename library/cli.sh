#!/usr/bin/env bash
#
# This code is licensed.  For details, please see the license file at
# https://github.com/gitprime/gitprime-tools/blob/master/LICENSE.md
#

# The functions in this file are intended to help developers deal with
# bash CLI option parsing.

# We need some common functionality here
# shellcheck source=./common.sh
source "${GITPRIME_TOOLS_HOME}/library/common.sh"

# We're going to declare a bunch of arrays that we can then use to keep track
# of the args and our processing of them
GPT_ARG_PARSER_INDEX=0

declare -a GPT_ARG_PARSER_NAMES
declare -a GPT_ARG_PARSER_SHORT_NAMES
declare -a GPT_ARG_PARSER_DESCRIPTIONS
declare -a GPT_ARG_PARSER_TYPES
declare -a GPT_ARG_PARSER_REQUIREMENTS
declare -a GPT_ARG_PARSER_RESULTS
declare -a GPT_ARG_PARSER_ERRORS

GPT_ARG_TYPE_FLAG=0
GPT_ARG_TYPE_VALUE=1

# This function allows a developer to register an argument.
#
# Parameters
#   long-name:  The long name of the option, for example 'help' for --help
#   short-name: The short name of the option, for example 'h' for -h
#   type: The type of argument.  Can either be 0 for a 'flag' argument that
#         is true/false or 1 for a 'value' which is an argument that has a value
#         follows it.  These are represented by the constants GPT_ARG_TYPE_FLAG
#         and GPT_ARG_TYPE_VALUE
#   required:  0 if the argument isn't requred, 1 if it is
#   description:  A help description of the argument.
function add_cli_argument() {
  local long_name
  local short_name
  local arg_type
  local required
  local description

  # Ok, our variables are declared, lets do a little validation.
  if [[ -z "$1" ]]; then
    log.error "No long name specified for add_cli_argument"

    return 1
  else
    long_name="$1"
  fi

  if [[ -z "$2" ]]; then
    log.error "No short name specified for argument ${long_name}"

    return 1
  else
    short_name="$2"
  fi

  if [[ -z "$3" ]]; then
    log.error "No type specified for argument ${long_name}"

    return 1
  else
    if [[ "$3" == "${GPT_ARG_TYPE_FLAG}" ]]; then
      arg_type=${GPT_ARG_TYPE_FLAG}
    elif [[ "$3" == "${GPT_ARG_TYPE_VALUE}" ]]; then
      arg_type=${GPT_ARG_TYPE_VALUE}
    else
      log.error "Invalid type specified for argument ${long_name}.  Must be equal to GPT_ARG_TYPE_FLAG or GPT_ARG_TYPE_VALUE"

      return 1
    fi
  fi

  if [[ -z "$4" ]]; then
    log.error "No requirement specified for argument ${long_name}"

    return 1
  else
    local arg_test

    arg_test=$(echo "$4" | tr '[:lower:]' '[:upper:]')

    if [ "${arg_test}" == "1" ] || [ "${arg_test}" == "TRUE" ]; then
      required=1
    elif [ "${arg_test}" == "0" ] || [ "${arg_test}" == "FALSE" ]; then
      required=0
    else
      log.error "Invalid requirement specified for argument ${long_name}.  Must be 0 or 1"

      return 1
    fi
  fi

  if [[ ! -z "$5" ]]; then
    description="$5"
  fi

  # Ok, we've validated the data, now we just have to populate our arrays.

  GPT_ARG_PARSER_NAMES[${GPT_ARG_PARSER_INDEX}]="${long_name}"
  GPT_ARG_PARSER_SHORT_NAMES[${GPT_ARG_PARSER_INDEX}]="${short_name}"
  GPT_ARG_PARSER_DESCRIPTIONS[${GPT_ARG_PARSER_INDEX}]="${description}"
  GPT_ARG_PARSER_TYPES[${GPT_ARG_PARSER_INDEX}]=${arg_type}
  GPT_ARG_PARSER_REQUIREMENTS[${GPT_ARG_PARSER_INDEX}]=${required}

  GPT_ARG_PARSER_INDEX=$((GPT_ARG_PARSER_INDEX + 1))
}

function clear_cli_arguments() {
  echo
}

function parse_cli_arguments() {
  local arg_array=("$@")

  declare -a final_args

  # OK, what we need to do here is try and parse these out by each arg
  # We get them in a pretty good format.  However, we don't deal well with
  # "clumped" arguments like -awbc should be 4 short arguments.  if there
  # is no dash, then we assume this is some sort of value that is passed in.

  # First thing we're going to do is look for "short" options and de-clump them
  for ((x = 0; x < ${#arg_array[@]}; x++)); do
    if [[ "${arg_array[x]}" == "-"* ]] && [[ ${arg_array[x]} != "--"* ]]; then
      # Ok, this is a possible clumped set.  What we need to do here is simply
      # expand per character.
      local tmp_str=${arg_array[x]:1}

      for ((y = 0; y < ${#tmp_str}; y++)); do
        local our_char=${tmp_str:$y:1}

        if [[ ${our_char} == "=" ]]; then
          # We need to use the REST of this string
          if [[ ${y} -gt 0 ]]; then
            final_args[-1]="${final_args[-1]}${tmp_str:$y}"

            break
          else
            # This is a weird case, it means they did "-=" as an arg.  We're going
            # to take it as a single character arg and then let it fail later as
            # an unacceptable value.
            final_args+=("-${our_char}")
          fi
        else
          final_args+=("-${our_char}")
        fi
      done
    else
      final_args+=("${arg_array[x]}")
    fi
  done
}
