#!/bin/bash

set -e

PROJECT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." &>/dev/null && pwd)

help() {
  echo ""
  echo "Usage: $0 -s SCRIPT_NAME -t NETWORK [-b] [-l]"
  echo -e "\t-s --script: Script to run"
  echo -e "\t-t --target: Target network to deploy to"
  echo -e "\t-b --broadcast: Broadcast transactions to a network"
  echo -e "\t-h --help: Prints this message"
  exit 1
}

while [ -n "$1" ]; do
  case "$1" in
  -h | --help)
    help
    ;;
  -s | --script)
    [[ ! "$2" =~ ^- ]] && SCRIPT=$2
    shift 2
    ;;
  -t | --target)
    [[ ! "$2" =~ ^- ]] && TARGET=$2
    shift 2
    ;;
  -b | --broadcast)
    BROADCAST=true
    shift
    ;;
  --)
    # remaining options are captured as "$*"
    shift
    break
    ;;
  *)
    echo -e "Unknown option: $1"
    help
    ;;
  esac
done

if [ -z "${TARGET}" ] || [ -z "${SCRIPT}" ]; then
  help
fi

case "${TARGET}" in
local | testnet | mainnet) ;;
*)
  echo -e "Unknown target: ${TARGET}"
  help
  ;;
esac

set -a
source "${PROJECT_DIR}/.env"
source "${PROJECT_DIR}/.env.${TARGET}"
set +a

# script arguments
ARGS="--rpc-url ${RPC_URL}"

# fallback to hardware wallet
ARGS+=" --ledger --hd-paths ${ADMIN_LEDGER_DERIVATION_PATH}"

# broadcast
if [ "${BROADCAST}" = true ]; then
  ARGS+=" --broadcast"
fi

forge script "${PROJECT_DIR}/scripts/${SCRIPT}:Deploy" ${ARGS}
