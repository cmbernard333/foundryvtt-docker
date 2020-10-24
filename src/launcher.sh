#!/bin/sh
# shellcheck disable=SC2039
# busybox supports more features than POSIX /bin/sh

# setup logging
# shellcheck disable=SC2034
# LOG_NAME used in sourced file
LOG_NAME="Launcher"
# shellcheck disable=SC1091
# disable following
source logging.sh

if [ "$1" = "--shell" ]; then
  /bin/sh
  exit $?
fi

# Quote all strings for insertion into json
# busybox does not implement ${VAR@Q} substitution to quote variables

if [[ "${FOUNDRY_AWS_CONFIG:-}" ]]; then
  if [[ $FOUNDRY_AWS_CONFIG == "true" ]];then
    FOUNDRY_AWS_CONFIG=true
  else
    FOUNDRY_AWS_CONFIG=\"${FOUNDRY_AWS_CONFIG}\"
  fi
fi
if [[ "${FOUNDRY_HOSTNAME:-}" ]]; then
  FOUNDRY_HOSTNAME=\"${FOUNDRY_HOSTNAME}\"
fi
if [[ "${FOUNDRY_ROUTE_PREFIX:-}" ]]; then
  FOUNDRY_ROUTE_PREFIX=\"${FOUNDRY_ROUTE_PREFIX}\"
fi
if [[ "${FOUNDRY_SSL_CERT:-}" ]]; then
  FOUNDRY_SSL_CERT=\"${FOUNDRY_SSL_CERT}\"
fi
if [[ "${FOUNDRY_SSL_KEY:-}" ]]; then
  FOUNDRY_SSL_KEY=\"${FOUNDRY_SSL_KEY}\"
fi
if [[ "${FOUNDRY_UPDATE_CHANNEL:-}" ]]; then
  FOUNDRY_UPDATE_CHANNEL=\"${FOUNDRY_UPDATE_CHANNEL}\"
fi
if [[ "${FOUNDRY_WORLD:-}" ]]; then
  FOUNDRY_WORLD=\"${FOUNDRY_WORLD}\"
fi

# make sure the minimum are set
TURN_CONFIGS=1

if [[ "${FOUNDRY_TURN_CONFIGS_URL:-}" ]]; then
  FOUNDRY_TURN_CONFIGS_URL=\"${FOUNDRY_TURN_CONFIGS_URL}\"
else
  TURN_CONFIGS=0
fi

if [[ "${FOUNDRY_TURN_CONFIGS_USERNAME:-}" ]]; then
  FOUNDRY_TURN_CONFIGS_USERNAME=\"${FOUNDRY_TURN_CONFIGS_USERNAME}\"
else
  TURN_CONFIGS=0
fi

if [[ "${FOUNDRY_TURN_CONFIGS_CREDENTIAL:-}" ]]; then
  FOUNDRY_TURN_CONFIGS_CREDENTIAL=\"${FOUNDRY_TURN_CONFIGS_CREDENTIAL}\"
else
  TURN_CONFIGS=0
fi

if [[ $TURN_CONFIGS -eq 1 ]]; then
read -r -d '' FOUNDRY_TURN_CONFIGS <<EOM
[{
    "url": ${FOUNDRY_TURN_CONFIGS_URL:-},
    "username": ${FOUNDRY_TURN_CONFIGS_USERNAME:-},
    "credential": ${FOUNDRY_TURN_CONFIGS_CREDENTIAL:-}
  }
]
EOM
log "Using turnsConfig: ${FOUNDRY_TURN_CONFIGS}"
fi

# Update configuration file
mkdir -p /data/Config >& /dev/null
log "Generating options.json file."
cat <<EOF > /data/Config/options.json
{
  "awsConfig": ${FOUNDRY_AWS_CONFIG:-null},
  "dataPath": "/data",
  "fullscreen": false,
  "hostname": ${FOUNDRY_HOSTNAME:-null},
  "port": 30000,
  "proxyPort": ${FOUNDRY_PROXY_PORT:-null},
  "proxySSL": ${FOUNDRY_PROXY_SSL:-false},
  "routePrefix": ${FOUNDRY_ROUTE_PREFIX:-null},
  "sslCert": ${FOUNDRY_SSL_CERT:-null},
  "sslKey": ${FOUNDRY_SSL_KEY:-null},
  "updateChannel": ${FOUNDRY_UPDATE_CHANNEL:-\"release\"},
  "upnp": ${FOUNDRY_UPNP:-false},
  "world": ${FOUNDRY_WORLD:-null},
  "turnConfigs": ${FOUNDRY_TURN_CONFIGS:-[]}
}
EOF

# Save Admin Access Key if it is set
if [[ "${FOUNDRY_ADMIN_KEY:-}" ]]; then
  log "Setting 'Admin Access Key'."
  echo "${FOUNDRY_ADMIN_KEY}" | ./set_password.js > /data/Config/admin.txt
else
  log_warn "No 'Admin Access Key' has been configured."
  rm /data/Config/admin.txt >& /dev/null || true
fi

# Spawn node with clean environment to prevent credential leaks
log "Starting Foundry Virtual Tabletop."
env -i HOME="$HOME" node "$@"
