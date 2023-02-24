#!/usr/bin/env bash
# Copyright (C) 2023, Ava Labs, Inc. All rights reserved.
# See the file LICENSE for licensing terms.

set -e

# Set the CGO flags to use the portable version of BLST
#
# We use "export" here instead of just setting a bash variable because we need
# to pass this flag to all child processes spawned by the shell.
export CGO_CFLAGS="-O -D__BLST_PORTABLE__"

# to run E2E tests (terminates cluster afterwards)
# MODE=test ./scripts/run.sh
if ! [[ "$0" =~ scripts/run.sh ]]; then
  echo "must be run from repository root"
  exit 255
fi

VERSION=1.9.8
MODE=${MODE:-run}
LOGLEVEL=${LOGLEVEL:-info}
STATESYNC_DELAY=${STATESYNC_DELAY:-0}
if [[ ${MODE} != "run" ]]; then
  STATESYNC_DELAY=500000000 # 500ms
fi

AVALANCHE_LOG_LEVEL=${AVALANCHE_LOG_LEVEL:-INFO}

echo "Running with:"
echo VERSION: ${VERSION}
echo MODE: ${MODE}

############################
# build avalanchego
# https://github.com/ava-labs/avalanchego/releases
GOARCH=$(go env GOARCH)
GOOS=$(go env GOOS)
AVALANCHEGO_PATH=/tmp/avalanchego-v${VERSION}/avalanchego
AVALANCHEGO_PLUGIN_DIR=/tmp/avalanchego-v${VERSION}/plugins

if [ ! -f "$AVALANCHEGO_PATH" ]; then
  echo "building avalanchego"
  CWD=$(pwd)

  # Clear old folders
  rm -rf /tmp/avalanchego-v${VERSION}
  mkdir -p /tmp/avalanchego-v${VERSION}
  rm -rf /tmp/avalanchego-src
  mkdir -p /tmp/avalanchego-src

  # Download src
  cd /tmp/avalanchego-src
  git clone https://github.com/ava-labs/avalanchego.git
  cd avalanchego
  git checkout v${VERSION}

  # Build avalanchego
  ./scripts/build.sh
  mv build/avalanchego /tmp/avalanchego-v${VERSION}

  cd ${CWD}
else
  echo "using previously built avalanchego"
fi

############################

############################
echo "building indexvm"

# delete previous (if exists)
rm -f /tmp/avalanchego-v${VERSION}/plugins/oS6k2RdwvBbUhmnDwCXw1cGWy4w9WD4FKJgUYWeh8vPLrxj3Y

# rebuild with latest code
go build \
-o /tmp/avalanchego-v${VERSION}/plugins/oS6k2RdwvBbUhmnDwCXw1cGWy4w9WD4FKJgUYWeh8vPLrxj3Y \
./cmd/indexvm

echo "building index-cli"
go build -v -o /tmp/index-cli ./cmd/index-cli

# log everything in the avalanchego directory
find /tmp/avalanchego-v${VERSION}

############################

############################

# Always create allocations (linter doesn't like tab)
echo "creating allocations file"
cat <<EOF > /tmp/allocations.json
[{"address":"index1rvzhmceq997zntgvravfagsks6w0ryud3rylh4cdvayry0dl97nsqrawg5", "balance":1000000000000}]
EOF

GENESIS_PATH=$2
if [[ -z "${GENESIS_PATH}" ]]; then
  echo "creating VM genesis file with allocations"
  rm -f /tmp/indexvm.genesis
  /tmp/index-cli genesis /tmp/allocations.json \
  --genesis-file /tmp/indexvm.genesis
else
  echo "copying custom genesis file"
  rm -f /tmp/indexvm.genesis
  cp ${GENESIS_PATH} /tmp/indexvm.genesis
fi

############################

############################

echo "creating vm config"
rm -f /tmp/indexvm.config
cat <<EOF > /tmp/indexvm.config
{
  "mempoolSize": 10000000,
  "mempoolExemptPayers":["index1rvzhmceq997zntgvravfagsks6w0ryud3rylh4cdvayry0dl97nsqrawg5"],
  "parallelism": 5,
  "logLevel": "${LOGLEVEL}",
  "stateSyncServerDelay": ${STATESYNC_DELAY}
}
EOF

############################

############################

echo "creating subnet config"
rm -f /tmp/indexvm.subnet
cat <<EOF > /tmp/indexvm.subnet
{
  "proposerMinBlockDelay":0
}
EOF

############################

############################
echo "building e2e.test"
# to install the ginkgo binary (required for test build and run)
go install -v github.com/onsi/ginkgo/v2/ginkgo@v2.1.4

# alert the user if they do not have $GOPATH properly configured
if ! command -v ginkgo &> /dev/null
then
    echo -e "\033[0;31myour golang environment is misconfigued...please ensure the golang bin folder is in your PATH\033[0m"
    echo -e "\033[0;31myou can set this for the current terminal session by running \"export PATH=\$PATH:\$(go env GOPATH)/bin\"\033[0m"
    exit
fi

ACK_GINKGO_RC=true ginkgo build ./tests/e2e
./tests/e2e/e2e.test --help

#################################
# download avalanche-network-runner
# https://github.com/ava-labs/avalanche-network-runner
ANR_REPO_PATH=github.com/ava-labs/avalanche-network-runner
ANR_VERSION=v1.3.5
# version set
go install -v ${ANR_REPO_PATH}@${ANR_VERSION}

#################################
# run "avalanche-network-runner" server
GOPATH=$(go env GOPATH)
if [[ -z ${GOBIN+x} ]]; then
  # no gobin set
  BIN=${GOPATH}/bin/avalanche-network-runner
else
  # gobin set
  BIN=${GOBIN}/avalanche-network-runner
fi

killall avalanche-network-runner || true

echo "launch avalanche-network-runner in the background"
$BIN server \
--log-level verbo \
--port=":12352" \
--grpc-gateway-port=":12353" &
PID=${!}

############################
# By default, it runs all e2e test cases!
# Use "--ginkgo.skip" to skip tests.
# Use "--ginkgo.focus" to select tests.

KEEPALIVE=false
function cleanup() {
  if [[ ${KEEPALIVE} = true ]]; then
    echo "avalanche-network-runner is running in the background..."
    echo ""
    echo "use the following command to terminate:"
    echo ""
    echo "killall avalanche-network-runner"
    echo ""
    exit
  fi

  echo "avalanche-network-runner shutting down..."
  killall avalanche-network-runner
}
trap cleanup EXIT

echo "running e2e tests"
./tests/e2e/e2e.test \
--ginkgo.v \
--network-runner-log-level verbo \
--network-runner-grpc-endpoint="0.0.0.0:12352" \
--network-runner-grpc-gateway-endpoint="0.0.0.0:12353" \
--avalanchego-path=${AVALANCHEGO_PATH} \
--avalanchego-plugin-dir=${AVALANCHEGO_PLUGIN_DIR} \
--vm-genesis-path=/tmp/indexvm.genesis \
--vm-config-path=/tmp/indexvm.config \
--subnet-config-path=/tmp/indexvm.subnet \
--output-path=/tmp/avalanchego-v${VERSION}/output.yaml \
--mode=${MODE}

############################
# e.g., print out MetaMask endpoints
if [[ -f "/tmp/avalanchego-v${VERSION}/output.yaml" ]]; then
  echo "cluster is ready!"
  cat /tmp/avalanchego-v${VERSION}/output.yaml
else
  echo "cluster is not ready in time..."
  exit 255
fi

############################
if [[ ${MODE} == "run" ]]; then
  # We made it past initialization and should avoid shutting down the network
  KEEPALIVE=true
fi
