#!/bin/bash
#
# Script to add user to Verdaccio using htpasswd plugin.


# color definitions for echo -e output
# taken from https://stackoverflow.com/questions/5947742/how-to-change-the-output-color-of-echo -e-in-linux
RED='\e[0;31m'
GREEN='\e[0;32m'
LIGHTGREEN='\e[1;32m'
YELLOW='\e[1;33m'
NOCOLOR='\e[0m'
BLINK='\e[33;5m'


# constants
EMPTY_STRING=""
DOCKER_VOLUMES_ROOT="/var/lib/docker/volumes/"
VERDACCIO_CONFIG_VOLUME="verdacciozerotierdocker_conf/_data/"


# functions
function function_log_message {
  echo -e "${LIGHTGREEN}** $1${NOCOLOR}"
}

function function_log_error {
  echo -e "${RED}** $1${NOCOLOR}"
}

function function_print_usage {
  echo -e "   "
  echo -e "  Options:"
  echo -e "    -u   User name."
  # echo -e "    -p   User password."
  # echo -e "    -e   User email."
  echo -e "   "
}


# variables
USER_NAME=""
# USER_PASSWORD=""
# USER_EMAIL=""


# parse flag arguments
while getopts 'u:c' flag; do
  case "${flag}" in
    u) USER_NAME=${OPTARG};;
    # p) USER_PASSWORD=${OPTARG};;
    # e) USER_EMAIL=${OPTARG};;
    *) function_print_usage
       kill -INT $$ ;;
  esac
done


# if user is not given, nothing to do here
if [[ "$USER_NAME" == "$EMPTY_STRING" ]]; then
  function_log_error "Please provide a username to remove ('-u' parameter)"
  kill -INT $$
fi


# install htpasswd
function_log_message "Updating htpasswd"
sudo npm install -g htpasswd


# create user
function_log_message "Removing user '$USER_NAME'"
sudo htpasswd -D ${DOCKER_VOLUMES_ROOT}${VERDACCIO_CONFIG_VOLUME}dolcevita ${USER_NAME}
function_log_message "Done"
