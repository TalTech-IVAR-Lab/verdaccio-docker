#!/bin/bash
#
# Script to deploy Verdaccio server running with Docker Compose with optional ZeroTier One network.


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
VERDACCIO_CONFIG_VOLUME="verdaccio_conf/_data/"


# variables
USE_HTTPS=false
ZEROTIER_NETWROK_ID=""


# functions
function function_log_message {
  echo -e "${LIGHTGREEN}** $1${NOCOLOR}"
}

function function_print_usage {
  echo -e "   "
  echo -e "  Deployment options:"
  echo -e "    -z   ZeroTier One network ID to connect to."
  echo -e "   "
}


# parse flag arguments
while getopts 'kbi:c' flag; do
  case "${flag}" in
    h) USE_HTTPS=true;;
    z) ZEROTIER_NETWROK_ID=${OPTARG};;
    *) function_print_usage
       kill -INT $$ ;;
  esac
done


# install Docker and Docker Compose
sudo apt update
sudo apt install -y docker docker-compose


# ZeroTier installation and connection (https://www.zerotier.com/download/)
if [ "$INSTANCE_ADDRESS" != "$EMPTY_STRING" ]
then
  function_log_message "Installing ZeroTier One"
  sudo apt install gpg
  curl -s 'https://raw.githubusercontent.com/zerotier/ZeroTierOne/master/doc/contact%40zerotier.com.gpg' | gpg --import && \
  if z=$(curl -s 'https://install.zerotier.com/' | gpg); then echo "$z" | sudo bash; fi

  function_log_message "Connecting to ZeroTier network ID '$ZEROTIER_NETWROK_ID'"
  zerotier-one join $ZEROTIER_NETWROK_ID
fi

# deploy Verdaccio Docker to create volumes
docker-compose up -d

# generate SSL certificates for HTTPS
if [ $USE_HTTPS ]
then
  sudo apt install -y openssl

  sudo openssl genrsa -out verdaccio-key.pem 2048
  sudo openssl req -new -sha256 -key verdaccio-key.pem -out verdaccio-csr.pem
  sudo openssl x509 -req -in verdaccio-csr.pem -signkey verdaccio-key.pem -out verdaccio-cert.pem

  sudo mv verdaccio-csr.pem ${DOCKER_VOLUMES_ROOT}${VERDACCIO_CONFIG_VOLUME}verdaccio-csr.pem
  sudo mv verdaccio-key.pem ${DOCKER_VOLUMES_ROOT}${VERDACCIO_CONFIG_VOLUME}verdaccio-key.pem
  sudo mv verdaccio-cert.pem ${DOCKER_VOLUMES_ROOT}${VERDACCIO_CONFIG_VOLUME}verdaccio-cert.pem
fi

# copy our configuration into Verdaccio Docker volume
sudo cp config.yaml ${DOCKER_VOLUMES_ROOT}${VERDACCIO_CONFIG_VOLUME}config.yaml

# re-deploy Verdaccio Docker to let it notice configuration changes
docker-compose up -d --force-recreate

# TODO: copy config over to Verdaccio Docker volume?
