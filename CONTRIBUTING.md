# Contributing to the Conjur Buildpack

Thanks for your interest in contributing to the Conjur Buildpack! Here
are some guidelines on how to get started.

For general contribution and community guidelines, please see the [community repo](https://github.com/cyberark/community).

## Table of Contents

- [Prerequisites](#prerequisites)
- [Pull Request Workflow](#pull-request-workflow)
- [Updating the `conjur-env` Binary](#updating-the-conjur-env-binary)
- [Testing](#testing)
- [Releasing](#releasing)

## Prerequisites

Before getting started, you should install some developer tools. These are not required to deploy the Conjur Buildpack but they will let you develop using a standardized, expertly configured environment.

1. [git][get-git] to manage source code
2. [Docker][get-docker] to manage dependencies and runtime environments
3. [Docker Compose][get-docker-compose] to orchestrate Docker environments

[get-docker]: https://docs.docker.com/engine/installation
[get-git]: https://git-scm.com/downloads
[get-docker-compose]: https://docs.docker.com/compose/install

In addition, if you will be making changes to the `conjur-env` binary, you should
ensure you have [Go installed](https://golang.org/doc/install#install) locally.
Our project uses Go modules, so you will want to install version 1.12+.

### Pull Request Workflow

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

Make sure your Pull Request includes an update to the [CHANGELOG](https://github.com/cyberark/cloudfoundry-conjur-buildpack/blob/master/CHANGELOG.md) describing your changes.

### Updating the `conjur-env` Binary

The `conjur-env` binary uses Go modules to manage dependencies. To update the versions of `summon` / `conjur-api-go` that are included in the `conjur-env` binary in the buildpack, make sure you have Go installed locally (at least version 1.12) and run:

```
$ cd conjur-env/
$ go get github.com/cyberark/[repo]@v[version]
```

This will automatically update go.mod and go.sum.

Commit your changes, and the next time `./package.sh` is run the `vendor/conjur-env` directory will be created with updated dependencies.

When upgrading the version of Go for `conjur-env`, both the pre-built offline version and online version need to be
updated:

- **Offline build:** Update the base image version in `./conjur-env/Dockerfile`

- **Online build:** Update the version and file hashes in `./lib/install_go.sh`. Available versions and hashes are available at https://buildpacks.cloudfoundry.org/#/buildpacks/.

### Testing

To test the usage of the Conjur Service Broker within a CF deployment, you can
follow the demo scripts in the [Cloud Foundry demo repo](https://github.com/conjurinc/cloudfoundry-conjur-demo).

To run the test suite on your local machine:
```
$ ./package.sh   # Create the conjur-env binary in the vendor dir and a ZIP of the project contents
$ ./test.sh      # Run the test suite
```

#### Integration Testing

To run the buildpack integration tests, the test script needs to be given the API endpoint and admin credentials
for a CloudFoundry installation. These are provided as environment variables to the script:

```sh-session
$ export CF_API_ENDPOINT=https://api.sys.cloudfoundry.net
$ CF_ADMIN_PASSWORD=... ./test.sh
```

These variables may also be provided using [Summon](https://cyberark.github.io/summon/) by updating the `secrets.yml`
file as needed and running:

```
$ summon ./test.sh
```

### Releasing

1. Based on the unreleased content, determine the new version number and update the [VERSION](VERSION) file. This project uses [semantic versioning](https://semver.org/).
1. Ensure the [changelog](CHANGELOG.md) is up to date with the changes included in the release.
1. Ensure the [open source acknowledgements](NOTICES.txt) are up to date with the dependencies in the
   [conjur-env binary](./conjur-env/go.mod), and update the file if there have been any new or changed dependencies
   since the last release.
1. Commit these changes - `Bump version to x.y.z` is an acceptable commit message.
1. Once your changes have been reviewed and merged into master, tag the version
   using `git tag -s v0.1.1`. Note this requires you to be  able to sign releases.
   Consult the [github documentation on signing commits](https://help.github.com/articles/signing-commits-with-gpg/)
   on how to set this up. `vx.y.z` is an acceptable tag message.
1. Push the tag: `git push vx.y.z` (or `git push origin vx.y.z` if you are working
   from your local machine).
1. From a **clean checkout of master** run `./package.sh` to generate the release ZIP. Upload this ZIP file
   to the GitHub release.

   **IMPORTANT** Do not upload any artifacts besides the ZIP to the GitHub release. At this time, the tile build
   assumes the project ZIP is the only artifact.
