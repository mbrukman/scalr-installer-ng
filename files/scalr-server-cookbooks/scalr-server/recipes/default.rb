# There's a bit of dark magic going on here, but the idea is that
# - We ensure our configuration dir is ready first
# - We check if a configuration file exists, and if it does, then we load it into the ScalrServer library. The
#   configuration file is basically #   an attributes file, except it must not have the leading default[:scalr_server].
#   For example: `default[:scalr_server][:app][:some_config] = ...` becomes `app[:some_config] = ...`.
# - We load the attributes generated by the ScalrServer library into our node attributes. This includes both attributes
#   loaded from the configuration file, and secrets (loaded from a separate JSON file, though they can be overridden in
#   the config file. Either way they'll be persisted in the JSON file).

include_recipe 'scalr-server::_config_dir'

# Reads configuration from:
# + /etc/scalr-server/scalr-server.rb
# + /etc/scalr-server/scalr-server-local.rb
# + /etc/scalr-server/scalr-secrets.json
node.consume_attributes(ScalrServer.generate_config node)

# Deploy modules
%w{supervisor app mysql cron rrd service web}.each do |mod|  # Todo - supervisor, app shouldn't really be an option.
  # TODO - Create run dir, etc dir here
  if node[:scalr_server][mod][:enable]
    include_recipe "scalr-server::group_#{mod}_enabled"
  else
    include_recipe "scalr-server::group_#{mod}_disabled"
  end
  include_recipe "scalr-server::group_#{mod}_always"
end


# sysctl settings
include_recipe 'scalr-server::sysctl'