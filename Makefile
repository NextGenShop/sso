#!make
include .my-env

all:
	./init_letsencrypt.sh \
		-e ${EMAIL} \
		-n "${KEYCLOAK_HOST} www.${KEYCLOAK_HOST}" \
		-a ${ARCHITECTURE} \
		-d ${DISTRIBUTION}
