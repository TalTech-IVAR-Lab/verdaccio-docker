# prepare base image
FROM verdaccio/verdaccio:5
RUN apt update

# install zerotier-cli (from https://www.zerotier.com/download/)
RUN apt install gpg
RUN curl -s 'https://raw.githubusercontent.com/zerotier/ZeroTierOne/master/doc/contact%40zerotier.com.gpg' | gpg --import && \
if z=$(curl -s 'https://install.zerotier.com/' | gpg); then echo "$z" | sudo bash; fi

# connect to zerotier network and start verdaccio
ENTRYPOINT zerotier-cli join $ZEROTIER_NETWORK_ID
