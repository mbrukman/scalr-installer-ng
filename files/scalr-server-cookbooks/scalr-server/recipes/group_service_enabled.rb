# service directories
directory bin_dir_for(node, 'service') do
  owner     'root'
  group     'root'
  mode      0755
  recursive true
end

cookbook_file "#{bin_dir_for node, 'service'}/scalrpy_proxy" do
  owner     'root'
  group     'root'
  source    'scalrpy_proxy'
  mode    0755
end

directory run_dir_for(node, 'service') do
  owner     node[:scalr_server][:app][:user]
  group     node[:scalr_server][:app][:user]
  mode      0755
  recursive true
end

directory log_dir_for(node, 'service') do
  owner     node[:scalr_server][:app][:user]
  group     node[:scalr_server][:app][:user]
  mode      0755
  recursive true
end

directory "#{data_dir_for(node, 'service')}/graphics" do
  # This is where we serve stats graphics from
  owner     node[:scalr_server][:app][:user]
  group     node[:scalr_server][:app][:user]
  mode      0755
  recursive true
end


# Actually launch the services

# Python services first
enabled_services(node, :python).each do |svc|
  name = "service-#{svc[:name]}"
  should_restart = service_is_up?(node, name)

  supervisor_service name do
    command         "#{bin_dir_for node, 'service'}/scalrpy_proxy" \
                    " #{run_dir_for node, 'service'}/#{svc[:name]}.pid" \
                    " #{node[:scalr_server][:install_root]}/embedded/bin/python" \
                    " #{scalr_bundle_path node}/app/python/scalrpy/#{svc[:service_module]}.py" \
                    " --pid-file=#{run_dir_for node, 'service'}/#{svc[:name]}.pid" \
                    " --log-file=#{log_dir_for node, 'service'}/python-#{svc[:name]}.log" \
                    " --user=#{node[:scalr_server][:app][:user]}" \
                    " --group=#{node[:scalr_server][:app][:user]}" \
                    " --config=#{scalr_bundle_path node}/app/etc/config.yml" \
                    ' --verbosity=INFO' \
                    " #{svc[:service_extra_args]}" \
                    # Note: 'start' is added by the proxy.
    stdout_logfile  "#{log_dir_for node, 'supervisor'}/#{name}.log"
    stderr_logfile  "#{log_dir_for node, 'supervisor'}/#{name}.err"
    action          [:enable, :start]
    autostart       true
    subscribes      :restart, 'file[scalr_config]' if should_restart
    subscribes      :restart, 'file[scalr_code]' if should_restart
    subscribes      :restart, 'file[scalr_cryptokey]' if should_restart
    subscribes      :restart, 'file[scalr_id]' if should_restart
    subscribes      :restart, 'user[scalr_user]' if should_restart
  end
end

# The broker should be added if *any* php service is running
if enabled_services(node, :php).any?
  name = 'zmq_service'
  should_restart = service_is_up?(node, name)

  supervisor_service name do
    command         "#{node[:scalr_server][:install_root]}/embedded/bin/php -c #{etc_dir_for node, 'php'}" \
                    " #{scalr_bundle_path node}/app/cron/service.php"
    stdout_logfile  "#{log_dir_for node, 'supervisor'}/zmq_service.log"
    stderr_logfile  "#{log_dir_for node, 'supervisor'}/zmq_service.err"
    action          [:enable, :start]
    autostart       true
    user            node[:scalr_server][:app][:user]
    subscribes      :restart, 'file[scalr_config]' if should_restart
    subscribes      :restart, 'file[scalr_code]' if should_restart
    subscribes      :restart, 'file[scalr_cryptokey]' if should_restart
    subscribes      :restart, 'file[scalr_id]' if should_restart
    subscribes      :restart, 'template[php_ini]' if should_restart
  end
end
