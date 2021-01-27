#!/bin/bash
OTHER_ARGUMENTS=()
for arg in "$@"
do
    case $arg in
        -h|--help)
            echo "$0 - install Docker and docker-compose"
            echo " "
            echo "$0 [options]"
            echo " "
            echo "options:"
            echo "-h, --help                show brief help"
            echo "-a, --arch=ARCHITECTURE   amd64 (default)  | armhf  | arm64"
            echo "-d, --dist=DISTRIBUTION   ubuntu (default) | debian | raspbian"
            exit 0
            ;;
        -a)
            ARCHITECTURE="$2"
            shift
            ;;
        --arch=*)
            ARCHITECTURE="${arg#*=}"
            shift
            ;;
        -d)
            DISTRIBUTION="$2"
            shift
            ;;
        --dist=*)
            DISTRIBUTION="${arg#*=}"
            shift
            ;;
        *)
            OTHER_ARGUMENTS+=("$1")
            shift
            ;;
    esac
done

[ -z "$ARCHITECTURE" ] && export ARCHITECTURE="amd64"
[ -z "$DISTRIBUTION" ] && export DISTRIBUTION="ubuntu"

if [ $ARCHITECTURE != "amd64" ] && [ $ARCHITECTURE != "armhf" ] && [ $ARCHITECTURE != "arm64" ]; then
    echo "Invalid architecture. Should be amd64 | armhf | arm64."
    exit 1
fi

if [ $DISTRIBUTION != "ubuntu" ] && [ $DISTRIBUTION != "debian" ] && [ $DISTRIBUTION != "raspbian" ]; then
    echo "Invalid distribution. Should be ubuntu | debian | raspbian."
    exit 1
fi

# Install prerequisites
apt update
apt-get -y install \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common

# Add GPG key
curl -fsSL https://download.docker.com/linux/${DISTRIBUTION}/gpg | apt-key add -

# Add repository
add-apt-repository \
   "deb [arch=${ARCHITECTURE}] https://download.docker.com/linux/${DISTRIBUTION} \
   $(lsb_release -cs) \
   stable"
apt update

# Install docker
apt-get -y install \
    docker-ce \
    docker-ce-cli \
    containerd.io

# Enable running Docker as non-root
groupadd -f docker
usermod -aG docker $USER

# Install docker-compose
curl -L "https://github.com/docker/compose/releases/download/1.28.0/docker-compose-$(uname -s)-$(uname -m)" \
    -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Reload newly created group
# newgrp docker
