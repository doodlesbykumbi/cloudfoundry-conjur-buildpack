Then(/^conjur-env is installed$/) do
  expect(File.exist?("#{@DEPS_DIR}/#{@INDEX_DIR}/vendor/conjur-env")).to be_truthy
end

Then(/^the retrieve secrets profile\.d script is installed$/) do
  expect(File.exist?("#{@DEPS_DIR}/#{@INDEX_DIR}/profile.d/0001_retrieve-secrets.sh")).to be_truthy
end
