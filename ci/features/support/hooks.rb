After("@integration") do |scenario|
  if scenario.status == :passed
    cf_delete_org(cf_ci_org)
    cf_delete_buildpack(cf_ci_buildpack_name)
  end
end
