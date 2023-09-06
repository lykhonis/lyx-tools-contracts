#!/bin/bash

set -e

PROJECT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." &>/dev/null && pwd)

help() {
  echo ""
  echo "Usage: $0 -t NETWORK"
  echo -e "\t-t --target: Target network to deploy to"
  echo -e "\t-h --help: Prints this message"
  exit 1
}

while [ -n "$1" ]; do
  case "$1" in
  -h | --help)
    help
    ;;
  -t | --target)
    [[ ! "$2" =~ ^- ]] && TARGET=$2
    shift 2
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

if [ -z "${TARGET}" ]; then
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

SRC_DIR=${PROJECT_DIR}/src

verify() {
  name=$1
  address=$2

  echo "Verifying ${name} at ${address}"

  forge verify-contract \
    --compiler-version 'v0.8.17+commit.8df45f5f' \
    --optimizer-runs 1000 \
    --chain-id ${CHAIN_ID} \
    --verifier blockscout \
    --verifier-url "${BLOCKSCOUT_URL}/api?" \
    --watch \
    ${address} ${name}
}

verifyProxy() {
  name=$1
  address=$2

  echo "Verifying proxy ${name} at ${address}"

  implementationValue=$(
    cast storage \
      --chain ${CHAIN_ID} \
      --rpc-url ${RPC_URL} \
      ${address} 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
  )
  implementationAddress="0x${implementationValue:26:40}"

  echo "Implementation address: ${implementationAddress}"

  verify TransparentUpgradeableProxy ${address}
  verify ${name} ${implementationAddress}
}

verifyProxy Subscriptions ${CONTRACT_SUBSCRIPTIONS_ADDRESS}
