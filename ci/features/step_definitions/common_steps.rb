require 'tempfile'

Given(/^the '([^"]*)' command is run$/) do |script_command|
  @commands ||= []

  # all this fuss to use a bash shell as opposed to sh shell

  f = Tempfile.open('command.sh')
  file_contents = <<EOS
#!/bin/bash -e
#{ @commands.join("\n") }
#{ script_command }
EOS
  f.write(file_contents)
  f.close

  `chmod +x #{f.path}`

  @output = `bash #{f.path}`
  @result = $?

  f.unlink
end

Given(/^the supply script is run against the app's root folder$/) do
  step "the following command is run:", <<EOS
#{ENV['BUILDPACK_BUILD_DIR']}/bin/supply #{@BUILD_DIR} #{@CACHE_DIR} #{@DEPS_DIR} #{@INDEX_DIR}
EOS
end

Given(/^the following command is run:$/) do |multiline_text|
  step "the '#{multiline_text}' command is run"
end

Then(/^the result should have a non\-zero exit status$/) do
  expect(@result.exitstatus).not_to eq(0)
end

Then(/^the result should have a 0 exit status$/) do
  expect(@result.exitstatus).to eq(0)
end

Then(/^the result should have a 1 exit status$/) do
  expect(@result.exitstatus).to eq(1)
end

Given(/^VCAP_SERVICES contains cyberark\-conjur credentials$/) do
  @commands ||= []
  @commands << <<eos
export VCAP_SERVICES='
{
 "cyberark-conjur": [{
  "credentials": {
   "appliance_url": "#{Conjur.configuration.appliance_url}",
   "authn_api_key": "#{admin_api_key}",
   "authn_login": "admin",
   "account": "#{Conjur.configuration.account}",
   "ssl_certificate": "",
   "version": 5
  }
 }],
 "some-other-service": [{
   "credentials": {
     "version": "1.0"
   }
 }]
}
'
eos
end

Given(/^VCAP_SERVICES has a cyberark\-conjur key$/) do
  @commands ||= []
  @commands << <<EOS
export VCAP_SERVICES='
{
 "cyberark-conjur": []
}
'
EOS
end

Given(/^VCAP_SERVICES does not have a cyberark\-conjur key$/) do
  @commands ||= []
  @commands << <<EOS
export VCAP_SERVICES='
{
}
'
EOS
end

And(/^the build directory has a secrets\.yml file(?: at ["']([^'"]+)["'])?/) do |secrets_yaml_path|
  secretsyml = <<EOS
LITERAL_SECRET: a literal secret
EOS
  secrets_yaml_path ||= 'secrets.yml'
  full_path = "#{@BUILD_DIR}/#{secrets_yaml_path}"
  FileUtils.mkdir_p(File.dirname(full_path))
  File.open(full_path, 'w') { |file| file.write(secretsyml) }
end

When(/^the build directory has this secrets\.yml file$/) do |secretsyml|
  File.open("#{@BUILD_DIR}/secrets.yml", 'w') { |file| file.write(secretsyml) }
end
