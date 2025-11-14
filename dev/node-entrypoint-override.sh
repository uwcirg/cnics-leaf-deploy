#!/bin/sh
set -eu

repo_path="$(cd "$(dirname "$0")" && pwd)"
cmdname="$(basename "$0")"

usage() {
    cat << USAGE >&2
Usage:
    $cmdname command

    Docker entrypoint script
    Wrapper script that executes docker-related tasks before running given command

USAGE
    exit 1
}

if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    usage
    exit 0
fi


write_env_to_json() {
    # write project-specific environment variables to app config file
    local json_file="$1"

    # only write environment variables containing "REACT_"
    local json_contents="$(printenv | grep '^REACT_' | sed 's/\([^=]*\)=\(.*\)/"\1":"\2"/' | paste -sd, -)"
    echo "{${json_contents}}" > "$json_file"
}

substitute_leaf_jwt_issuer() {
    # workaround for leaf needing this hardcoded in the config file
    local json_file="/app/API/appsettings.json"

    # substitute $LEAF_JWT_ISSUER in to appsettings.json:Jwt.Issuer
    sed -E 's/"Issuer": "(.*?)"/"Issuer": "${LEAF_JWT_ISSUER}"/' $json_file > $json_file
}

write_env_to_json /app/public/env.json
substitute_leaf_jwt_issuer

echo $cmdname complete
echo executing given command $@
exec "$@"
