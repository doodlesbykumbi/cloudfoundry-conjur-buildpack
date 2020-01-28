#!/bin/bash

# Borrowing this script from the Node.js Buildpack.
# https://raw.githubusercontent.com/cloudfoundry/nodejs-buildpack/master/scripts/install_go.sh

set -euo pipefail

GO_VERSION="1.13.6"

if [ $CF_STACK == "cflinuxfs3" ]; then
    GO_SHA256="56df080cd10ad7d827abb4e826cae46b66d68451f38bd1286610639d1601ead5"
else
  echo "       **ERROR** Unsupported stack"
  echo "                 See https://docs.cloudfoundry.org/devguide/deploy-apps/stacks.html for more info"
  exit 1
fi

export GoInstallDir="/tmp/go$GO_VERSION"
mkdir -p $GoInstallDir

if [ ! -f $GoInstallDir/go/bin/go ]; then
  URL=https://buildpacks.cloudfoundry.org/dependencies/go/go${GO_VERSION}.linux-amd64-${CF_STACK}-${GO_SHA256:0:8}.tgz

  echo "-----> Download go ${GO_VERSION}"
  curl -s -L --retry 15 --retry-delay 2 $URL -o /tmp/go.tar.gz

  DOWNLOAD_SHA256=$(shasum -a 256 /tmp/go.tar.gz | cut -d ' ' -f 1)

  if [[ $DOWNLOAD_SHA256 != $GO_SHA256 ]]; then
    echo "       **ERROR** SHA256 mismatch: got $DOWNLOAD_SHA256 expected $GO_SHA256"
    exit 1
  fi

  tar xzf /tmp/go.tar.gz -C $GoInstallDir
  rm /tmp/go.tar.gz
fi
if [ ! -f $GoInstallDir/bin/go ]; then
  echo "       **ERROR** Could not download go"
  exit 1
fi
