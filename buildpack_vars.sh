#!/bin/bash -e

version=$(cat VERSION)

SRC_DIR=$(cd "$(dirname $0)/."  && pwd)
NAME=${BUILDPACK_NAME:-$(basename "$SRC_DIR" | sed s/-/_/g)}
TGT_DIR=${SRC_DIR}
ZIP_FILE="$TGT_DIR/$NAME-$version.zip"
