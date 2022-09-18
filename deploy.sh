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
VOLUMES_ROOT="verdaccio_volumes"
CONFIG_VOLUME="${VOLUMES_ROOT}/conf/"
STORAGE_VOLUME="${VOLUMES_ROOT}/storage/"
PLUGINS_VOLUME="${VOLUMES_ROOT}/plugins/"
LOGS_VOLUME="${VOLUMES_ROOT}/logs/"
VERDACCIO_USER_UID=10001
VERDACCIO_USER_GROUP=65533


# Variables
USE_HTTPS=false
CREATE_HTTPS_CERTS=true
VERDACCIO_PROTOCOL=http
VERDACCIO_PORT=443
VERDACCIO_DOMAIN=""
VERDACCIO_EMAIL=""


# Functions
function_log_message() {
  echo -e "${LIGHTGREEN}> $1${NOCOLOR}"
}

function_print_usage() {
  echo -e "
  Options:
      -h, --https      Add this flag to enable HTTPS.
      -d, --domain     Domain name to use for HTTPS setup.
      -e, --email      Email to use for HTTPS setup.
      -s, --skip-certs Skip HTTPS certificate generation (use if the certs were already generated before).
      -p, --port       Port this Verdaccio instance should run on.
  "
}

function_ensure_package_installed() {
  PACKAGE_NAME=$1
  if dpkg --get-selections | grep -q "^${PACKAGE_NAME}[[:space:]]*install$" >/dev/null; then
    function_log_message "${PACKAGE_NAME} is already installed."
  else
    function_log_message "Installing ${PACKAGE_NAME}..."
    sudo apt update
    sudo apt install -y ${PACKAGE_NAME}
  fi
}

function_create_directory_if_doesnt_exist() {
  if [ ! -d $1 ]; then
    mkdir -p $1;
  fi
}



# CLI (parsing based on https://stackoverflow.com/a/14203146)
while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--https)
      USE_HTTPS=true
      shift;;
    -s|--skip-certs)
      CREATE_HTTPS_CERTS=false
      shift;;
    -d|--domain)
      VERDACCIO_DOMAIN=$2
      shift && shift;;
    -e|--email)
      VERDACCIO_EMAIL=$2
      shift && shift;;
    -p|--port)
      VERDACCIO_PORT=$2
      shift && shift;;
    -*|--*)
      echo -e "Unknown option: $1"
      function_print_usage
      shift;;
  esac
done



# Set environment variables in the .env file
function_log_message "Setting environment variables:"
if $USE_HTTPS; then
  VERDACCIO_PROTOCOL=https
fi
sudo echo -e "VERDACCIO_PORT=${VERDACCIO_PORT}\nVERDACCIO_PROTOCOL=${VERDACCIO_PROTOCOL}\nVERDACCIO_DOMAIN=${VERDACCIO_DOMAIN}\nVERDACCIO_EMAIL=${VERDACCIO_EMAIL}" | sudo tee .env

# Install Docker and Docker Compose
function_ensure_package_installed "docker"
function_ensure_package_installed "docker-compose"

# Create directories
function_log_message "Creating directories..."
function_create_directory_if_doesnt_exist ${CONFIG_VOLUME}
function_create_directory_if_doesnt_exist ${STORAGE_VOLUME}
function_create_directory_if_doesnt_exist ${PLUGINS_VOLUME}
function_create_directory_if_doesnt_exist ${LOGS_VOLUME}

# Generate SSL certificates for HTTPS
rm -rf https
if $USE_HTTPS && $CREATE_HTTPS_CERTS; then
  function_log_message "HTTPS is requested."
  function_ensure_package_installed "openssl"

  function_log_message "Generating SSL certificates..."
  sudo openssl genrsa -out ${CONFIG_VOLUME}/verdaccio-key.pem 2048
  sudo openssl req -new -sha256 -key ${CONFIG_VOLUME}/verdaccio-key.pem -out ${CONFIG_VOLUME}/verdaccio-csr.pem
  sudo openssl x509 -req -in ${CONFIG_VOLUME}/verdaccio-csr.pem -signkey ${CONFIG_VOLUME}/verdaccio-key.pem -out ${CONFIG_VOLUME}/verdaccio-cert.pem
fi

# Copy our configuration into Verdaccio Docker volume
function_log_message "Copying Verdaccio config to Docker volume..."
sudo cp config.yaml ${CONFIG_VOLUME}/config.yaml

# Generate password file
sudo touch ${CONFIG_VOLUME}/dolcevita

# Configure folder permissions to allow Verdaccio access
sudo chown -R ${VERDACCIO_USER_ID}:${VERDACCIO_USER_ID} ${VOLUMES_ROOT}

# Export environment vars required for docker-compose
export VERDACCIO_PROTOCOL
export VERDACCIO_PORT
export VERDACCIO_DOMAIN
export VERDACCIO_EMAIL
export VERDACCIO_USER_UID

# Re-deploy Verdaccio Docker to let it notice configuration changes
function_log_message "Recreating Verdaccio docker-compose..."
docker-compose up -d --force-recreate
