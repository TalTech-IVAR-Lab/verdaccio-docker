#!/bin/bash
#
# Script to remove user from Verdaccio using htpasswd plugin.


# Color definitions for echo -e output.
# Taken from https://stackoverflow.com/questions/5947742/how-to-change-the-output-color-of-echo -e-in-linux
RED='\e[0;31m'
GREEN='\e[0;32m'
LIGHTGREEN='\e[1;32m'
YELLOW='\e[1;33m'
NOCOLOR='\e[0m'
BLINK='\e[33;5m'


# Constants
PASS_FILE_PATH="../volumes/verdaccio/conf/dolcevita"
VERDACCIO_REGISTRY="https://localhost"


# Functions
log_message() {
  echo -e "${LIGHTGREEN}> $1${NOCOLOR}"
}

log_error() {
  echo -e "${RED}> $1${NOCOLOR}"
}

print_usage() {
  echo -e "
  Options:
    -u, --user    Username for the user to be removed.
  "
}

require_variable_set() {
  VAR_NAME=$1
  if [ -z "${!VAR_NAME}" ]; then
    log_error "Variable '$VAR_NAME' is not set. It is required to set up the server.\nPlease make sure you have passed the corresponding CLI flag."
    print_usage
    exit 1
  fi
}

ensure_package_installed() {
  PACKAGE_NAME=$1
  if dpkg --get-selections | grep -q "^${PACKAGE_NAME}[[:space:]]*install$" >/dev/null; then
    log_message "${PACKAGE_NAME} is already installed."
  else
    log_message "Installing ${PACKAGE_NAME}..."
    sudo apt update
    sudo apt install -y ${PACKAGE_NAME}
  fi
}

ensure_npm_module_installed() {
  MODULE_NAME=$1
  if [[ "$(npm list -g $MODULE_NAME)" =~ "empty" ]]; then
    log_message "Installing ${MODULE_NAME} using npm..."
    sudo npm install -g ${MODULE_NAME}
  else
    log_message "${MODULE_NAME} is already installed."
  fi
}


# Variables
USER_NAME=""


# CLI (parsing based on https://stackoverflow.com/a/14203146)
while [[ $# -gt 0 ]]; do
  case $1 in
    -u|--user)
      USER_NAME=$2
      shift && shift;;
    -*|--*)
      echo -e "Unknown option: $1"
      print_usage
      shift;;
  esac
done


# If user is not given, nothing to do here
require_variable_set USER_NAME

# Install required dependencies
ensure_package_installed "npm"
ensure_npm_module_installed "htpasswd"

# Create user
log_message "Remove user '${USER_NAME}'..."
sudo htpasswd -D ${PASS_FILE_PATH} ${USER_NAME}
