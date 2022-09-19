#!/bin/bash
#
# Script to deploy Verdaccio a server running with Docker Compose.


# Color definitions for echo -e output.
# Taken from https://stackoverflow.com/questions/5947742/how-to-change-the-output-color-of-echo -e-in-linux
RED='\e[0;31m'
GREEN='\e[0;32m'
LIGHTGREEN='\e[1;32m'
YELLOW='\e[1;33m'
NOCOLOR='\e[0m'
BLINK='\e[33;5m'


# Constants
EMPTY_STRING=""
CADDY_ROOT="volumes/caddy"
VERDACCIO_ROOT="volumes/verdaccio"
CONFIG_VOLUME="${VERDACCIO_ROOT}/conf/"
STORAGE_VOLUME="${VERDACCIO_ROOT}/storage/"
PLUGINS_VOLUME="${VERDACCIO_ROOT}/plugins/"
LOGS_VOLUME="${VERDACCIO_ROOT}/logs/"
VERDACCIO_USER_UID=10001
VERDACCIO_USER_GROUP=65533
VERDACCIO_PROTOCOL=http
VERDACCIO_PORT=4873


# Variables
DOMAIN=""
EMAIL=""


# Functions
log_message() {
  echo -e "${LIGHTGREEN}> $1${NOCOLOR}"
}

print_usage() {
  echo -e "
  Options:
      -d, --domain     Domain name to use for HTTPS setup.
      -e, --email      Email to use for HTTPS setup.
  "
}

require_variable_set() {
  VAR_NAME=$1
  if [ -z "${!VAR_NAME}" ]; then
    echo -e "Variable '$VAR_NAME' is not set. It is required to set up the server.\nPlease make sure you have passed the corresponding CLI flag."
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

create_directory_if_doesnt_exist() {
  if [ ! -d $1 ]; then
    mkdir -p $1;
  fi
}



# CLI (parsing based on https://stackoverflow.com/a/14203146)
while [[ $# -gt 0 ]]; do
  case $1 in
    -d|--domain)
      DOMAIN=$2
      shift && shift;;
    -e|--email)
      EMAIL=$2
      shift && shift;;
    -*|--*)
      echo -e "Unknown option: $1"
      function_print_usage
      shift;;
  esac
done

# Check if required flags are set
require_variable_set DOMAIN

# Set environment variables in the .env file
log_message "Setting environment variables:"
sudo echo -e "DOMAIN=${DOMAIN}\nEMAIL=${EMAIL}" | sudo tee .env

# Install Docker and Docker Compose
ensure_package_installed "docker"
ensure_package_installed "docker-compose"

# Create directories
log_message "Creating volume directories..."
create_directory_if_doesnt_exist ${CONFIG_VOLUME}
create_directory_if_doesnt_exist ${STORAGE_VOLUME}
create_directory_if_doesnt_exist ${PLUGINS_VOLUME}
create_directory_if_doesnt_exist ${LOGS_VOLUME}
create_directory_if_doesnt_exist ${CADDY_ROOT}

# Generate SSL certificates for HTTPS
rm -rf https
if $USE_HTTPS && $CREATE_HTTPS_CERTS && false; then
  log_message "HTTPS is requested."
  ensure_package_installed "openssl"

  log_message "Generating SSL certificates..."
  sudo openssl genrsa -out ${CONFIG_VOLUME}/verdaccio-key.pem 2048
  sudo openssl req -new -sha256 -key ${CONFIG_VOLUME}/verdaccio-key.pem -out ${CONFIG_VOLUME}/verdaccio-csr.pem
  sudo openssl x509 -req -in ${CONFIG_VOLUME}/verdaccio-csr.pem -signkey ${CONFIG_VOLUME}/verdaccio-key.pem -out ${CONFIG_VOLUME}/verdaccio-cert.pem
fi

# Copy our configuration files into the corresponding volumes
log_message "Copying Verdaccio config to Docker volume..."
sudo cp config.yaml ${CONFIG_VOLUME}/config.yaml
log_message "Copying Caddy config to Docker volume..."
sudo cp Caddyfile ${CADDY_ROOT}/Caddyfile

# Generate password file
log_message "Generating password file..."
sudo touch ${CONFIG_VOLUME}/dolcevita

# Configure folder permissions to allow Verdaccio access
log_message "Configuring Verdaccio folder permissions..."
#sudo chown -R ${VERDACCIO_USER_ID}:${VERDACCIO_USER_GROUP} ${VERDACCIO_ROOT}
sudo chgrp -R ${VERDACCIO_USER_GROUP} ${VERDACCIO_ROOT}

# Export environment vars required for docker-compose
log_message "Exporting environment for docker-compose..."
export VERDACCIO_PROTOCOL
export VERDACCIO_PORT
export VERDACCIO_DOMAIN
export VERDACCIO_EMAIL
export VERDACCIO_USER_UID

# Re-deploy Verdaccio Docker to let it notice configuration changes
log_message "Recreating Verdaccio docker-compose..."
docker-compose up -d --force-recreate
