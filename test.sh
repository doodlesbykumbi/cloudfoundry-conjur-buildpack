#!/bin/bash -e

function finish {
  echo 'Removing environment'
  echo '-----'
  docker-compose down -v
}
trap finish EXIT

# sets up conjur and retrieves credentials
. ./setup-conjur.sh

# Skip the integration tests if the Summon variables are not present
if [ -z "$CF_API_ENDPOINT" ]; then
    INTEGRATION_TAG="--tags ~@integration"
else
    # Make sure all of the environment are present for the integration tests
    : ${CF_ADMIN_PASSWORD?"Need to set CF_ADMIN_PASSWORD"}

    # Build the Java CI application
    pushd ci/apps/java
      ./bin/build
    popd
fi  

# build latest test images
docker-compose build

# unpack latest build of buildpack
docker-compose run --rm tester bash ./unpack.sh

# run tests against latest build of buildpack
docker-compose run --rm \
 -w "$BUILDPACK_ROOT_DIR/ci" \
 tester cucumber \
 --format pretty \
 --format junit \
 --out ./features/reports \
 ${INTEGRATION_TAG}
