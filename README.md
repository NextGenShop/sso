# Keycloak based SSO server

This project contains the deployment scripts for an Keycloak based SSO server with TLS included.

## Getting Started

### Dependencies

The scripts are configured for Debian based operating systems (Debian, Ubuntu, Raspbian) on 3 architectures, x86_64 / amd64, ARM and ARM64 / AARCH64.

`build-essential` is required to run the main stript.

All the other missing dependencies will be automatically installed if needed.

**Note: This may overite your existing setup. Do not run this on your working machine.**

A public IP address and open 80/TCP port are required for TLS certificate retrieval.

A public IP address and open 80/TCP and 443/TCP ports are required for accessing the running system.

### Executing the scripts

To run the scripts, first configure the required environment variables according to your setup:

    export EMAIL=[email used]
    export KEYCLOAK_USER=[Keycloak admin username]
    export KEYCLOAK_PASSWORD=[Keycloak admin password]
    export KEYCLOAK_HOST=[hostname of your machine (needed for TLS certificate retrieval)] # www. can be omitted

    export ARCHITECTURE=[amd64 | arm64 | armhf]
    export DISTRIBUTION=[ubuntu | debian | raspbian]

then run

    make
