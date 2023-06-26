#!/bin/bash

set -e

forge verify-contract \
  --flatten \
  --compiler-version "0.8.17+commit.8df45f5f" \
  --watch \
  --verifier blockscout \
  --verifier-url https://explorer.execution.mainnet.lukso.network/api \
  --chain-id 42 \
  0xd0d8b3edb593d0a209d8805cf608cfd3da3a34a2 Subscriptions
