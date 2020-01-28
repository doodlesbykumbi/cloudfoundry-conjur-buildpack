#!/bin/bash -e

. ./buildpack_vars.sh

echo "Buildpack name: $NAME"
echo "Source directory: $SRC_DIR"
echo "Target file: $ZIP_FILE"

pushd ${SRC_DIR}
  ls vendor/conjur-env || {
    echo "ERROR: conjur-env isn't present in ${SRC_DIR}/vendor."
    echo "ERROR: conjur-env should be built and placed in ${SRC_DIR}/vendor before running this script";
    exit 1;
  }
  rm -f "$ZIP_FILE"
  zip -r "$ZIP_FILE" LICENSE NOTICES.txt VERSION bin lib vendor upload.sh buildpack_vars.sh package_buildpack.sh
popd
