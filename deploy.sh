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
VOLUMES_ROOT="volumes/"
VERDACCIO_CONFIG_VOLUME="verdaccio_conf/"
VERDACCIO_STORAGE_VOLUME="verdaccio_storage/"
VERDACCIO_PLUGINS_VOLUME="verdaccio_plugins/"
VERDACCIO_LOGS_VOLUME="verdaccio_logs/"


# Variables
USE_HTTPS=false
CREATE_HTTPS_CERTS=true
VERDACCIO_PROTOCOL=http
VERDACCIO_PORT=443
VERDACCIO_DOMAIN=""
VERDACCIO_EMAIL=""


# Functions
function function_log_message {
  echo -e "${LIGHTGREEN}> $1${NOCOLOR}"
}

function function_print_usage {
  echo -e "
  Deployment options:
      -h   Add this flag to enable HTTPS.
      -d   Domain name to use for HTTTPS setup.
      -e   Email to use for HTTTPS setup.
      -s   Skip HTTPS certificate generation (use if the certs were already generated before).
      -p   Port this Verdaccio instance should run on.
  "
}

function function_ensure_package_installed {
  PACKAGE_NAME=$1
  if dpkg --get-selections | grep -q "^${PACKAGE_NAME}[[:space:]]*install$" >/dev/null; then
    function_log_message "${PACKAGE_NAME} is already installed."
  else
    function_log_message "Installing ${PACKAGE_NAME}..."
    sudo apt update
    sudo apt install -y ${PACKAGE_NAME}
  fi
}

function function_create_directory_if_doesnt_exist {
  if [ ! -d $1 ]; then
    mkdir -p $1;
  fi
}



# CLI
while getopts 'hsdepz:c' flag; do
  case "${flag}" in
    h) USE_HTTPS=true;;
    s) CREATE_HTTPS_CERTS=false;;
    d) VERDACCIO_DOMAIN=${OPTARG};;
    e) VERDACCIO_EMAIL=${OPTARG};;
    p) VERDACCIO_PORT=${OPTARG};;
    *) function_print_usage
       kill -INT $$ ;;
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
function_create_directory_if_doesnt_exist ${VOLUMES_ROOT}/${VERDACCIO_CONFIG_VOLUME}
function_create_directory_if_doesnt_exist ${VOLUMES_ROOT}/${VERDACCIO_STORAGE_VOLUME}
function_create_directory_if_doesnt_exist ${VOLUMES_ROOT}/${VERDACCIO_PLUGINS_VOLUME}
function_create_directory_if_doesnt_exist ${VOLUMES_ROOT}/${VERDACCIO_LOGS_VOLUME}

# Generate SSL certificates for HTTPS
sudo rm -rf https
if $USE_HTTPS && $CREATE_HTTPS_CERTS; then
  function_log_message "HTTPS is requested."
  function_ensure_package_installed "openssl"

  function_log_message "Generating SSL certificates..."
  SSL_CERTS_PATH="${VOLUMES_ROOT}/${VERDACCIO_CONFIG_VOLUME}"
  sudo openssl genrsa -out ${SSL_CERTS_PATH}/verdaccio-key.pem 2048
  sudo openssl req -new -sha256 -key ${SSL_CERTS_PATH}/verdaccio-key.pem -out ${SSL_CERTS_PATH}/verdaccio-csr.pem
  sudo openssl x509 -req -in ${SSL_CERTS_PATH}/verdaccio-csr.pem -signkey ${SSL_CERTS_PATH}/verdaccio-key.pem -out ${SSL_CERTS_PATH}/verdaccio-cert.pem
fi

# copy our configuration into Verdaccio Docker volume
function_log_message "Copying Verdaccio config to Docker volume..."
sudo cp config.yaml ${VOLUMES_ROOT}/${VERDACCIO_CONFIG_VOLUME}/config.yaml

# generate password file
sudo touch ${VOLUMES_ROOT}/${VERDACCIO_CONFIG_VOLUME}/dolcevita

# configure folder permissions to allow Verdaccio access
#sudo chown -R 10001:65533 ${VOLUMES_ROOT}/${VERDACCIO_CONFIG_VOLUME}
#sudo chown -R 10001:65533 ${VOLUMES_ROOT}/${VERDACCIO_STORAGE_VOLUME}
#sudo chown -R 10001:65533 ${VOLUMES_ROOT}/${VERDACCIO_PLUGINS_VOLUME}
#sudo chown -R 10001:65533 ${VOLUMES_ROOT}/${VERDACCIO_LOGS_VOLUME}

# re-deploy Verdaccio Docker to let it notice configuration changes
function_log_message "Recreating Verdaccio docker-compose..."
sudo docker-compose up -d --force-recreate
