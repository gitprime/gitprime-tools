#!/usr/bin/env bash
#
# This code is licensed.  For details, please see the license file at
# https://github.com/gitprime/gitprime-tools/blob/master/LICENSE.md
#

# The functions in this file are intended to help developers deal with
# bash CLI option parsing.

# We're going to declare a bunch of arrays that we can then use to keep track
# of the args.
declare -a GPT_ARG_PARSER_NAMES
declare -a GPT_ARG_PARSER_SHORT_NAMES
declare -a GPT_ARG_PARSER_DESCRIPTIONS
declare -a GPT_ARG_PARSER_TYPES
declare -a GPT_ARG_PARSER_REQUIREMENTS
declare -a GPT_ARG_PARSER_RESULTS

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
function add_cli_argument()
{

}

function parse_cli_arguments()
{
    echo
}