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
declare -a GPT_ARG_PARSER_COMMANDS

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
#   required:  0 if the argument isn't required, 1 if it is
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

# This function is intended to simply clear out all the previously parsed
# arguments so that we can use it again.
function reset_cli() {
  GPT_ARG_PARSER_NAMES=()
  GPT_ARG_PARSER_SHORT_NAMES=()
  GPT_ARG_PARSER_DESCRIPTIONS=()
  GPT_ARG_PARSER_TYPES=()
  GPT_ARG_PARSER_REQUIREMENTS=()
  GPT_ARG_PARSER_RESULTS=()
  GPT_ARG_PARSER_ERRORS=()
  GPT_ARG_PARSER_COMMANDS=()
}

# A function to create a spacer string for a given column width
function create_spacer() {
  local text_width=$1

  local column_width=$2

  local output=""

  for ((s = 0; s < (column_width - text_width); s++)); do
    output+=" "
  done

  echo "${output}"
}

# This function logs out the argument information in a help-style format.
# I'll freely admit that this is a horrible, terrible piece of code.  On
# linux, bash offers a lot of stuff I could do this easier with.  However,
# Mac is several versions behind on bash, and then also doesn't have a posix
# compliant awk, sed, or grep.
#
# So I've hacked it.  I build a really ugly little columnizer.
function show_argument_info() {
  local col_one_width=6
  local col_two_width=8
  local col_three_width=0

  local term_width=0

  term_width=$(tput cols)

  for ((x = 0; x < ${#GPT_ARG_PARSER_NAMES[@]}; x++)); do
    local long_name
    local description
    local arg_type

    long_name="${GPT_ARG_PARSER_NAMES[x]}"
    description="${GPT_ARG_PARSER_DESCRIPTIONS[x]}"
    arg_type="${GPT_ARG_PARSER_TYPES[x]}"

    local tmp_col_one_width=${#long_name}

    if [[ ${arg_type} -eq ${GPT_ARG_TYPE_VALUE} ]]; then
      tmp_col_one_width=$((tmp_col_one_width + 10))
    else
      tmp_col_one_width=$((tmp_col_one_width + 2))
    fi

    if [[ ${tmp_col_one_width} -gt ${col_one_width} ]]; then
      col_one_width=${tmp_col_one_width}
    fi
  done

  # The last column will be the term-width minus the length of all text before it.
  # That text is the log header, the col_one_width, the col_two_width and 12 chars
  # of spacing in between
  local description_ident=$((col_one_width + 4 + col_two_width + 4))
  col_three_width=$((term_width - description_ident))

  local col_one_spacer
  col_one_spacer=$(create_spacer 6 ${col_one_width})

  # We can do spacers for the second and third, fourth, fifth, etc
  # here because we only ever have one size
  local line_two_spacer=""
  line_two_spacer=$(create_spacer 3 ${description_ident})

  local line_three_spacer=""
  line_three_spacer=$(create_spacer 0 ${description_ident})

  # Log out a header
  # shellcheck disable=SC2154
  log.info "${bold}Option${col_one_spacer}    Required    Description${normal}"

  local desc_array

  for ((x = 0; x < ${#GPT_ARG_PARSER_NAMES[@]}; x++)); do
    log.info
    local long_name
    local short_name
    local description
    local arg_type
    local requirement

    long_name="${GPT_ARG_PARSER_NAMES[x]}"
    short_name="${GPT_ARG_PARSER_SHORT_NAMES[x]}"
    description="${GPT_ARG_PARSER_DESCRIPTIONS[x]}"
    arg_type="${GPT_ARG_PARSER_TYPES[x]}"
    requirement="${GPT_ARG_PARSER_REQUIREMENTS[x]}"

    if [[ ${requirement} -eq 1 ]]; then
      requirement "yes"
    else
      # the trailing space is intentional
      requirement="no "
    fi

    desc_array=()

    if [[ ${#description} -gt ${col_three_width} ]]; then
      # We need to turn the description into properly wrapped lines
      # that fit in their column
      description=$(echo "${description}" | fold -s -w ${col_three_width})

      while read -r desc_line; do
        desc_array+=("${desc_line}")
      done <<<"${description}"
    else
      desc_array[0]="${description}"
    fi

    # Build a spacer for the first column
    local long_name_width=${#long_name}

    if [[ ${arg_type} -eq ${GPT_ARG_TYPE_VALUE} ]]; then
      long_name_width=$((long_name_width + 10))
    else
      long_name_width=$((long_name_width + 2))
    fi

    col_one_spacer=""
    col_one_spacer=$(create_spacer ${long_name_width} ${col_one_width})

    # Logout the main line
    if [[ ${arg_type} -eq ${GPT_ARG_TYPE_VALUE} ]]; then
      log.info "--${long_name}=<value>${col_one_spacer}    ${requirement}         ${desc_array[0]}"
    else
      log.info "--${long_name}${col_one_spacer}    ${requirement}         ${desc_array[0]}"
    fi

    # Log the short name
    log.info " -${short_name}${line_two_spacer}${desc_array[1]}"

    # Log any further description stuff
    for ((y = 2; y < ${#desc_array[@]}; y++)); do
      log.info "${line_three_spacer}${desc_array[y]}"
    done
  done
}

# This function takes a parsed CLI arg and pops it into the right arrays, sets errors, etc.
function handle_cli_argument() {
  local arg_data=$1

  local arg_index=-1

  local arg_key=-1
  local arg_value=-1

  if [[ "${arg_key}" == "-"* ]]; then
    # First, we strip the leading -
    while [[ "${arg_data}" == "-"* ]];
    do
      arg_data=${arg_data:1}
    done
  else
    # For options passed without a flag, we really just want to keep an ordered array of those so the
    # given command can just handle them.
    GPT_ARG_PARSER_COMMANDS+=(arg_data)

    # We can just return, there is no validation to do here.
    return 0
  fi

  if [[ ${arg_data} == "="* ]]; then
    # Hacking for the person that uses an = as an arg flag
    arg_data="GPT_EQUAL_SIGN_ARG${arg_data:1}"
  fi

  IFS='=' read -ra arg_split <<< "$arg_data"

  arg_key=${arg_split[0]}

  if [[ ${#arg_split[@]} > 1 ]]; then
    arg_value=${arg_split[1]}
  fi

  if [[ "${arg_key}" == "GPT_EQUAL_SIGN_ARG" ]]; then
    # Hacking for the person that uses an = as an arg flag
    arg_key="="
  fi

  if [[ ${#arg_key} == 1 ]]; then
    arg_index=$(find_short_argument_index "${arg_key}")
  else
    arg_index=$(find_argument_index "${arg_key}")
  fi

  if [[ ${arg_index} == -1 ]]; then
    GPT_ARG_PARSER_ERRORS+=("Invalid argument: ${arg_key}")
  else
    # Ok, we have a valid argument, we just need to validate it
    local arg_type=${GPT_ARG_PARSER_TYPES[arg_index]}

    local valid=0

    if [[ ${arg_type} == ${GPT_ARG_TYPE_VALUE} ]]; then
      # We need to validate we got a value, otherwise we didn't.
      if [[ ${arg_value} == -1 ]] || [[ -z "${arg_value}" ]]; then
        GPT_ARG_PARSER_ERRORS+=("Argument ${arg_key} requires a value.")
      else
        valid=1
      fi
    else
      # This is just a flag, so we set the value to 1 to show it was on
      arg_value=1

      valid=1
    fi

    if [[ ${valid} == 1 ]]; then
      GPT_ARG_PARSER_RESULTS[arg_index]=${arg_value}
    fi
  fi
}

# This function parses the arguments and their values and stores them so that
# users can get the values appropriately.
#
# returns 0 if successful, 1 if there are errors.
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

    handle_cli_argument "${final_args[-1]}"
  done

  local arg_index=-1
  local arg_long_name=-1

  for arg_long_name in ${GPT_ARG_PARSER_NAMES[@]}; do
    arg_index=$(find_argument_index "${arg_long_name}")

    if [[ ${GPT_ARG_PARSER_REQUIREMENTS[arg_index]} == 1 ]]; then
      if [[ ${GPT_ARG_PARSER_RESULTS[arg_index]} == -1 ]] || [[ -z "${GPT_ARG_PARSER_RESULTS[arg_index]}" ]]; then
        GPT_ARG_PARSER_ERRORS+=("Argument ${arg_long_name} is required.")
      fi
    fi

    if [[ ${GPT_ARG_PARSER_TYPES[arg_index]} == ${GPT_ARG_TYPE_FLAG} ]]; then
      # For flags, we want to make sure we set the value to false if there is no values set
      if [[ ${GPT_ARG_PARSER_RESULTS[arg_index]} == -1 ]] || [[ -z "${GPT_ARG_PARSER_RESULTS[arg_index]}" ]]; then
        GPT_ARG_PARSER_RESULTS[arg_index]=0
      fi
    fi
  done
}

function get_argument_names() {
  echo "${GPT_ARG_PARSER_NAMES[@]}"
}

function find_argument_index() {
  local arg_name=$1

  local output=-1

  for ((x = 0; x < ${#GPT_ARG_PARSER_NAMES[@]}; x++)); do
    if [[ "${arg_name}" == "${GPT_ARG_PARSER_NAMES[x]}" ]]; then
      output=${x}

      break
    fi
  done

  echo ${output}
}

function find_short_argument_index() {
  local arg_name=$1

  local output=-1

  for ((x = 0; x < ${#GPT_ARG_PARSER_SHORT_NAMES[@]}; x++)); do
    if [[ "${arg_name}" == "${GPT_ARG_PARSER_SHORT_NAMES[x]}" ]]; then
      output=${x}

      break
    fi
  done

  echo ${output}
}

# Gets a parsed argument value.  Will echo the value of the given argument.
# Returns 1 if the argument does not exist as well as echos an empty string.
function get_argument_value() {
  local arg_name=$1

  local output=1

  local arg_index

  arg_index=$(find_argument_index "${arg_name}")

  if [[ ${arg_index} -gt -1 ]]; then
    echo "${GPT_ARG_PARSER_RESULTS[arg_index]}"

    output=0
  fi

  return ${output}
}

function get_argument_error() {
  local arg_name=$1

  local output=1

  local arg_index

  arg_index=$(find_argument_index "${arg_name}")

  if [[ ${arg_index} -gt -1 ]]; then
    echo "${GPT_ARG_PARSER_ERRORS[arg_index]}"

    output=0
  fi

  return ${output}
}
