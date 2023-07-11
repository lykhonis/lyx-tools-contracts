#!/bin/bash

set -e

forge verify-contract \
  --compiler-version "0.8.17+commit.8df45f5f" \
  --flatten \
  --chain-id 42 \
  --num-of-optimizations 1000 \
  --watch \
  --verifier blockscout \
  --verifier-url https://explorer.execution.mainnet.lukso.network/api \
  0xd0d8b3edb593d0a209d8805cf608cfd3da3a34a2 src/Subscriptions.sol:Subscriptions
