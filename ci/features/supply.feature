Feature: Supply script
  Supply script installs conjur-env and profile.d script

  @BUILD_DIR
  Scenario: Successfully installs conjur-env and profile.d scripts
    Given the build directory has a secrets.yml file
    And VCAP_SERVICES contains cyberark-conjur credentials
    When the supply script is run against the app's root folder
    Then the result should have a 0 exit status
    And conjur-env is installed
    And the retrieve secrets profile.d script is installed

  @BUILD_DIR
  Scenario: When the app does not have a secrets.yml file
    When the supply script is run against the app's root folder
    Then the result should have a 1 exit status

  @BUILD_DIR
  Scenario: When the app has a secrets.yml file not in the root
    Given the build directory has a secrets.yml file at 'lib/secrets.yml'
    When the supply script is run against the app's root folder
    Then the result should have a 0 exit status

  @BUILD_DIR
  Scenario: When VCAP_SERVICES does not have Conjur credentials
    Given the build directory has a secrets.yml file
    And VCAP_SERVICES does not have a cyberark-conjur key
    When the supply script is run against the app's root folder
    Then the result should have a 1 exit status
