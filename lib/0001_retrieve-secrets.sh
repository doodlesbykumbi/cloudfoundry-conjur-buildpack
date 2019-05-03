#!/usr/bin/env bash

# Check whether the conjur-env output has already been sourced
# into the environment. If so, return early.
if [ ! -z "$CONJUR_ENV_SOURCED" ]; then
  return
fi

echo "[cyberark-conjur-buildpack]: retrieving & injecting secrets"

err_report() {
  local previous_exit=$?
  trap - ERR
  echo "${BASH_SOURCE}: Error on line $1" 1>&2
  exit ${previous_exit}
}
trap 'err_report $LINENO' ERR

#export VCAP_SERVICES='
#{
#  "cyberark-conjur": [{
#    "credentials": {
#      "appliance_url": "https://conjur.myorg.com/",
#      "authn_api_key": "2389fh3hf9283niiejwfhjsb83ydbn23u",
#      "authn_login": "3F20D12E-A470-4B7B-8778-C8885769887F",
#      "account": "brokered-services",
#      "ssl_certificate": "-----BEGIN CERTIFICATE-----...",
#      "version": 5
#    }
#  }]
#}
#'

# Prevent tracing to ensures secrets won't be leaked.
declare xtrace=""
case $- in
  (*x*) xtrace="xtrace";;
esac
set +x

# $HOME points to the app directory, which should contains a secrets.yml file.
pushd $HOME
  # __BUILDPACK_INDEX__ is replaced by sed in the 'supply' script.
  eval "$($DEPS_DIR/__BUILDPACK_INDEX__/vendor/conjur-env)"
popd

[ ! -z "$xtrace" ] && set -x
trap - ERR

export CONJUR_ENV_SOURCED=true
