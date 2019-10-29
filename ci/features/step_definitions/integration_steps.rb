Given("I create an org and space") do
  login_to_pcf
  cf_ci_org
  cf_ci_space
end

Given("I install the buildpack") do
  cf_auth('admin', ENV['CF_ADMIN_PASSWORD'])

  Dir.chdir('..') do
    ShellSession.execute('./upload.sh', 'BUILDPACK_NAME' => cf_ci_buildpack_name)
  end
end

When("I push a Python app with the offline buildpack") do
  login_to_pcf
  cf_target(cf_ci_org, cf_ci_space)

  Dir.chdir('apps/python') do
    create_app_manifest
    ShellSession.execute('cf push --random-route')
  end

  @app_name = 'python-app'
end

When("I push a Ruby app with the offline buildpack") do
  login_to_pcf
  cf_target(cf_ci_org, cf_ci_space)

  Dir.chdir('apps/ruby') do
    create_app_manifest
    ShellSession.execute('cf push --random-route')
  end

  @app_name = 'ruby-app'
end

When("I push a PHP app with the offline buildpack") do
  login_to_pcf
  cf_target(cf_ci_org, cf_ci_space)

  Dir.chdir('apps/php') do
    create_app_manifest
    ShellSession.execute('cf push --random-route')
  end

  @app_name = 'php-app'
end

When(/^I push a Java app with the ([^ ]*) buildpack$/) do |buildpack_type|
  login_to_pcf
  cf_target(cf_ci_org, cf_ci_space)

  buildpack_path = buildpack_type == 'offline' ? cf_ci_buildpack_name : cf_online_buildpack_route

  Dir.chdir('apps/java') do
    create_app_manifest(buildpack_path)
    ShellSession.execute('./bin/deploy')
  end

  @app_name = 'java-app'
end

Then("the secrets.yml values are available in the app") do
  page_content = cf_app_content
  expect(page_content).to match(/Database Username: space_username/)
  expect(page_content).to match(/Database Password: space_password/)
end
