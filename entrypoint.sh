#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'


function generate_password() {
    # We disable exit on error because we close the pipe
    # when we have enough characters, which results in a
    # non-zero exit status
    set +e
    tr -cd '[:alnum:]' < /dev/urandom | fold -w30 | head -n1 | tr -cd '[:alnum:]'
    set -e
}


function initialise_devpi {
  
    echo "[RUN]: Initializing devpi-server"
    devpi-server --restrict-modify root --start --host 127.0.0.1 --port 3141 --init
    devpi-server --status
    devpi use http://localhost:3141
    devpi login root --password=''
    devpi user -m root password="${DEVPI_ROOT_PASSWORD}"
    echo -n "$DEVPI_ROOT_PASSWORD" > "$DEVPI_SERVERDIR/.root_password"
    devpi index -y -c public pypi_whitelist='*'
    devpi logoff
    devpi-server --stop
    devpi-server --status
}

# Properly shutdown devpi server
shutdown() {
    devpi-server --stop  # Kill server
    kill -SIGTERM $TAIL_PID  # Kill log tailing
}


### ###

initialize=no
if [ ! -f "$DEVPI_SERVERDIR/.serverversion" ]; then
    initialize=yes    
fi

# if [ "${1:-}" == "bash" ]; then
#     exec "$@"
# fi

DEVPI_ROOT_PASSWORD="${DEVPI_ROOT_PASSWORD:-}"
if [ -f "$DEVPI_SERVERDIR/.root_password" ]; then
    DEVPI_ROOT_PASSWORD=$(cat "$DEVPI_SERVERDIR/.root_password")
elif [ -z "$DEVPI_ROOT_PASSWORD" ]; then
    DEVPI_ROOT_PASSWORD=$(generate_password)
fi

if [ ! -d "$DEVPI_SERVERDIR" ]; then
    echo "[RUN]: Creating devpi server dir"    
    mkdir -p "$DEVPI_SERVERDIR"    
fi

if [ ! -d "$DEVPI_CLIENTDIR" ]; then
    echo "[RUN]: Creating devpi client dir"    
    mkdir -p "$DEVPI_CLIENTDIR"    
fi   

echo "[RUN]: Installing signal traps"
trap shutdown SIGTERM SIGINT

if [[ $initialize = yes ]]; then
  initialise_devpi
fi

echo "[RUN]: Launching devpi-server"
# Need $DEVPI_SERVERDIR
devpi-server --restrict-modify root --start --host $DEVPI_HOST --port $DEVPI_PORT --theme $DEVPI_THEME

echo "[RUN]: Tailing log"
DEVPI_LOGS=$DEVPI_SERVERDIR/.xproc/devpi-server/xprocess.log
tail -f $DEVPI_LOGS &
TAIL_PID=$!

# Wait until tail is killed
wait $TAIL_PID

# Set proper exit code
wait $DEVPI_PID
EXIT_STATUS=$?
echo "[RUN]: devpi-server stopped, exiting..."