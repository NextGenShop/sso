#!/bin/bash
OTHER_ARGUMENTS=()
for arg in "$@"
do
    case $arg in
        -h|--help)
            echo "$0 - set up letsencrypt certificates and startup all containers"
            echo " "
            echo "$0 -e EMAIL -n (DOMAIN_1 DOMAIN_2 ...) [options]"
            echo " "
            echo "options:"
            echo "-h, --help                show brief help"
            echo "-n, --names=DOMAIN_NAMES  domain names used for the certificate as (domain_1 domain_2 ...)"
            echo "-e, --email=EMAIL         valid email address for certificate renewal notifications"
            echo "-a, --arch=ARCHITECTURE   amd64 (default)  | armhf  | arm64"
            echo "-d, --dist=DISTRIBUTION   ubuntu (default) | debian | raspbian"
            exit 0
            ;;
        -n)
            DOMAIN_NAMES="$2"
            shift
            ;;
        --names=*)
            DOMAIN_NAMES="${arg#*=}"
            shift
            ;;
        -e)
            EMAIL="$2"
            shift
            ;;
        --email=*)
            EMAIL="${arg#*=}"
            shift
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

if [ -z "$DOMAIN_NAMES" ]; then
    echo "A list of valid domain names should be provided."
    exit 1
fi

if [ -z "$EMAIL" ]; then
    echo "A valid email hsould be provided."
    exit 1
fi

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

if ! [ -x "$(command -v docker-compose)" ]; then
    sh install_docker.sh -a ${ARCHITECTURE} -d ${DISTRIBUTION}
    exit 1
fi

rsa_key_size=4096
data_path="./nginx/certbot"
domains=(${DOMAIN_NAMES})
email="${EMAIL}"
staging=0 # Set to 1 if you're testing your setup to avoid hitting request limits


if [ ! -e "$data_path/conf/options-ssl-nginx.conf" ] || [ ! -e "$data_path/conf/ssl-dhparams.pem" ]; then
    echo "### Downloading recommended TLS parameters ..."
    mkdir -p "$data_path/conf"
    curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot-nginx/certbot_nginx/_internal/tls_configs/options-ssl-nginx.conf > "$data_path/conf/options-ssl-nginx.conf"
    curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot/certbot/ssl-dhparams.pem > "$data_path/conf/ssl-dhparams.pem"
    echo
fi

echo "### Creating dummy certificate for $domains ..."
path="/etc/letsencrypt/live/$domains"
mkdir -p "$data_path/conf/live/$domains"
docker-compose run --rm --entrypoint "\
    openssl req -x509 -nodes -newkey rsa:$rsa_key_size -days 1\
        -keyout '$path/privkey.pem' \
        -out '$path/fullchain.pem' \
        -subj '/CN=localhost'" certbot
echo


echo "### Starting nginx ..."
docker-compose up --force-recreate -d reverse_proxy
echo

echo "### Deleting dummy certificate for $domains ..."
docker-compose run --rm --entrypoint "\
    rm -Rf /etc/letsencrypt/live/$domains && \
    rm -Rf /etc/letsencrypt/archive/$domains && \
    rm -Rf /etc/letsencrypt/renewal/$domains.conf" certbot
echo


echo "### Requesting Let's Encrypt certificate for $domains ..."
#Join $domains to -d args
domain_args=""
for domain in "${domains[@]}"; do
    domain_args="$domain_args -d $domain"
done

# Select appropriate email arg
case "$email" in
    "") email_arg="--register-unsafely-without-email" ;;
    *) email_arg="--email $email" ;;
esac

# Enable staging mode if needed
if [ $staging != "0" ]; then staging_arg="--staging"; fi

docker-compose run --rm --entrypoint "\
    certbot certonly --webroot -w /var/www/certbot \
        $staging_arg \
        $email_arg \
        $domain_args \
        --rsa-key-size $rsa_key_size \
        --agree-tos \
        --force-renewal" certbot
echo

echo "### Reloading nginx ..."
docker-compose exec reverse_proxy nginx -s reload
