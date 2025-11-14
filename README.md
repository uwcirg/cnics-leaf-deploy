# CNICS Leaf Deployment
Configuration for CNICS Leaf site

## Setup
Clone this repo to your desired location, including the `--recurse-submodules` argument to initialize all git submodules

    LEAF_CHECKOUT_PATH=$HOME/leaf-environments
    git clone --recurse-submodules https://github.com/uwcirg/leaf-environments $LEAF_CHECKOUT_PATH

### Prerequisites
- Traefik-based VM
- `git lfs`
- Keycloak deploymment

### Configure
Copy `default.env` to `.env` and modify as necessary. Uncommented entries are required and may need to be provided if a default is empty or inappropriate.

    cp ${LEAF_CHECKOUT_PATH}/dev/default.env ${LEAF_CHECKOUT_PATH}/dev/.env

#### Generate a Signing Key
Generate a JWT signing key, by following Leaf instructions for [3 - Create a JWT Signing Key - Leaf Docs](https://leafdocs.rit.uw.edu/installation/installation_steps/3_jwt/) and save `cert.pem`, `key.pem` and `leaf.pfx` to `${LEAF_CHECKOUT_PATH}/dev/cnics/keys/`

    openssl req -nodes -x509 -newkey rsa:2048 -days 3650 \
        -keyout ${LEAF_CHECKOUT_PATH}/dev/cnics/keys/key.pem \
        -out ${LEAF_CHECKOUT_PATH}/dev/cnics/keys/cert.pem \
        -subj "/CN=urn:leaf:issuer:cnics.leaf.${INSTITUTION:-cirg}.${TLD:-uw.edu}"

    # load docker compose environment variables into current shell
    source .env

    JWT_KEY_PW="$CNICS_JWT_KEY_PW"
    openssl pkcs12 -export \
        -in ${LEAF_CHECKOUT_PATH}/dev/cnics/keys/cert.pem \
        -inkey ${LEAF_CHECKOUT_PATH}/dev/cnics/keys/key.pem \
        -out ${LEAF_CHECKOUT_PATH}/dev/cnics/keys/leaf.pfx \
        -password pass:${JWT_KEY_PW}

Keys need to be readable by the API container. To make all keys readable, run the command below

    chmod -R o+r ${LEAF_CHECKOUT_PATH}/dev/*/keys

#### Configure Keycloak

##### Create the Keycloak realm
Create a new Keycloak realm for production and staging.

##### Create a Keycloak client for Leaf
Follow the instructions for [Keycloak OIDC Auth Provider](https://oauth2-proxy.github.io/oauth2-proxy/7.3.x/configuration/oauth_provider/) to create the OpenID client with the appropriate mappers.

##### Configure SSO
This part is unfortunately pretty complicated, at least for UW NetID.

##### Add groups to Keycloak realm
Add the "leaf_users" and "leaf_admin" groups to the realm, and then add those groups to users.

## Deploy
Pull the latest docker images and start all containers

    docker compose pull
    docker compose up --detach

After 10+ minutes, Leaf should be available at `https://${LEAF_DOMAIN}`, or `https://${SITE}.${LEAF_DOMAIN}`. If any services fail to start, re-run `docker compose up --detach`

## Loading Clinical Data
To load a site-specific dataset into its corresponding database, invoke mysql as follows (manually replacing ${SITE} with the desired site)

    sql_file_path=/srv/www/leaf-scripts/cnics_data.phosphorus.2024.03.14.19.07.reduced.sql
    docker compose exec -T clin-db bash -c 'mysql --user=root --password=${MYSQL_ROOT_PASSWORD} ${SITE}' < $sql_file_path

