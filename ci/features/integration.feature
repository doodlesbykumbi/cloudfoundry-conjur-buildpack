@integration
Feature: Integrations Tests for PCF 2.4

  These tests verify how the buildpack interacts with other
  final buildpacks. For the given language-specific final
  buildpack, the `conjur-env` should run and populate
  the application environment with the values from
  `secrets.yml`.

  With these tests, we currently do not connect to a Conjur
  instance, but only test the buildpack interactions.

    Background:
      Given I create an org and space
      And I install the buildpack

    Scenario: Python offline buildpack integration
      When I push a Python app with the offline buildpack
      Then the secrets.yml values are available in the app

    Scenario: Ruby offline buildpack integration
      When I push a Ruby app with the offline buildpack
      Then the secrets.yml values are available in the app

    Scenario: Java offline buildpack integration
      When I push a Java app with the offline buildpack
      Then the secrets.yml values are available in the app

    # The online buildpack tests are only valid if the latest commits
    # are push to the Github remote branch.
    Scenario: Java online buildpack integration
      When I push a Java app with the online buildpack
      Then the secrets.yml values are available in the app
