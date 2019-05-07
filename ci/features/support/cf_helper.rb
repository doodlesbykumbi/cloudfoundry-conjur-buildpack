module CfHelper
  def cf_online_buildpack_route
    branch_name = `git rev-parse --abbrev-ref HEAD`
    hash = "##{branch_name}" unless branch_name == 'master'
    "https://github.com/cyberark/cloudfoundry-conjur-buildpack#{hash}"
  end

  def cf_app_route
    route = ShellSession.execute(<<~SHELL
      cf app #{@app_name} | \
      awk -F ':' -v key="routes" '$1==key {print $2}'
    SHELL
                                ).output.strip!
    "https://#{route}/"
  end

  def cf_app_content
    uri = URI(cf_app_route)
    req = Net::HTTP::Get.new(uri.path)

    res = Net::HTTP.start(
            uri.host, uri.port, 
            use_ssl: uri.scheme == 'https', 
            verify_mode: OpenSSL::SSL::VERIFY_NONE
          ) do |https|
      https.request(req)
    end

    res.body.strip
  end

  def org_guid(org_name)
    ShellSession.execute(%(cf org --guid "#{org_name}")).output.chomp
  end

  def space_guid(org_name, space_name)
    cf_target(org_name, space_name)
    ShellSession.execute(%(cf space --guid "#{space_name}")).output.chomp
  end

  def login_to_pcf
    api_endpoint = ENV['CF_API_ENDPOINT']

    cf_api(api_endpoint)
    cf_auth(ci_user[:username], ci_user[:password])
  end

  def create_ci_user
    cf_target(cf_ci_org, cf_ci_space)
    cf_auth('admin', ENV['CF_ADMIN_PASSWORD'])

    username = "ci-user-#{SecureRandom.hex}"
    password = SecureRandom.hex

    ShellSession.execute(%(cf create-user "#{username}" "#{password}"))
                .execute(%(cf set-space-role "#{username}" "#{cf_ci_org}" "#{cf_ci_space}" "SpaceDeveloper"))

    {
      username: username,
      password: password
    }
  end

  def admin_user
    @admin_user ||= {
      username: 'admin',
      password: CF_ADMIN_PASSWORD
    }
  end

  def create_app_manifest(name=cf_ci_buildpack_name)
    ShellSession.execute(%(sed -e 's/{conjur_buildpack}/#{name}/g' manifest.yml.template > manifest.yml))
  end

  def create_org
    cf_auth('admin', ENV['CF_ADMIN_PASSWORD'])

    name = "ci-org-#{SecureRandom.hex}"
    ShellSession.execute(%(cf create-org #{name}))
    name
  end

  def cf_delete_org(org_name)
    cf_auth('admin', ENV['CF_ADMIN_PASSWORD'])
    ShellSession.execute(%(cf delete-org -f #{org_name}))
  end

  def cf_delete_buildpack(buildpack_name)
    cf_auth('admin', ENV['CF_ADMIN_PASSWORD'])
    ShellSession.execute(%(cf delete-buildpack -f #{buildpack_name}))
  end

  def create_space(org = nil)
    name = "ci-space-#{SecureRandom.hex}"
    ShellSession.execute(%(cf create-space #{name} #{"-o #{org}" if org}))
    name
  end

  def ci_app_route
    route = ShellSession.execute(<<~SHELL
      cf app hello-world | \
      awk -F ':' -v key="routes" '$1==key {print $2}'
    SHELL
                                ).output.strip!
      
    "https://#{route}/"
  end

  def ci_app_content
    uri = URI(ci_app_route)
    req = Net::HTTP::Get.new(uri.path)

    res = Net::HTTP.start(
            uri.host, uri.port, 
            :use_ssl => uri.scheme == 'https', 
            :verify_mode => OpenSSL::SSL::VERIFY_NONE) do |https|
      https.request(req)
    end

    res.body.strip!
  end

  def cf_api(api)
    ShellSession.execute(%(cf api "#{api}" --skip-ssl-validation))
  end

  def cf_auth(user, password)
    ShellSession.execute(%(cf auth "#{user}"), "CF_PASSWORD" => password)
  end

  def cf_target(org, space=nil)
    if space
      ShellSession.execute(%(cf target -o "#{org}" -s "#{space}"))
    else
      ShellSession.execute(%(cf target -o "#{org}"))
    end
  end

  def cf_service_instance_id
    @cf_service_instance_id ||= ShellSession.execute(%(cf service --guid conjur)).output.chomp
  end
end
