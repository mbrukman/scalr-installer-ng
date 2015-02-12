require_relative './path_helper'

module Scalr
  module ServiceHelper
    include Scalr::PathHelper

    #############
    # Utilities #
    #############

    def _filter_enabled(node, mod, lst)
      enable = enable_module? node, mod
      disable_override = node[:scalr_server][mod][:disable]

      if enable.kind_of?(Array)
        # If this is a list, then it means it's a list of names of services that should be enabled.
        lst.select { |obj|
          enable.include?(obj[:name])
        }
        # TODO - Check if a service doesn't exist!
      else
        # Otherwise, it either means all or none.
        enable ? lst : []
      end.select { |obj|
        # Remove everything where disable overrides enable.
        not disable_override.include? obj[:name]
      }
    end

    def _filter_disabled(node, mod, lst)
      exclude = _filter_enabled(node, mod, lst).collect {|svc| svc[:name]}
      lst.reject { |svc|
        exclude.include? svc[:name]
      }
    end

    ############
    # Services #
    ############

    def _all_services
      [
          {
              :name => 'msgsender',
              :service_module => 'msg_sender', :service_extra_args => '',
          },

          {
              :name => 'dbqueue',
              :service_module => 'dbqueue_event', :service_extra_args => '',
          },

          {
              :name => 'plotter',
              :service_module => 'load_statistics', :service_extra_args => '--plotter',
          },

          {
              :name => 'poller',
              :service_module => 'load_statistics', :service_extra_args => '--poller',
          },

          {
              :name => 'szrupdater',
              :service_module => 'szr_upd_service', :service_extra_args => '',
          },

          {
              :name => 'analytics_poller',
              :service_module => 'analytics_poller', :service_extra_args => '',
          },

          {
              :name => 'analytics_processor',
              :service_module => 'analytics_processing', :service_extra_args => '',
          },
      ]
    end

    def enabled_services(node)
      _filter_enabled(node, :service, _all_services)
    end

    def disabled_services(node)
      _filter_disabled(node, :service, _all_services)
    end

    def _all_crons
      all_crons = [
          {:hour => '*',    :minute => '*',    :ng => false, :name => 'Scheduler'},
          {:hour => '*',    :minute => '*/5',  :ng => false, :name => 'UsageStatsPoller'},
          {:hour => '*',    :minute => '*/2',  :ng => true,  :name => 'Scaling'},
          {:hour => '*',    :minute => '*/2',  :ng => false, :name => 'BundleTasksManager'},
          {:hour => '*',    :minute => '*/15', :ng => true,  :name => 'MetricCheck'},
          {:hour => '*',    :minute => '*/2',  :ng => true,  :name => 'Poller'},
          {:hour => '*',    :minute => '*',    :ng => false, :name => 'DNSManagerPoll'},
          {:hour => '*',    :minute => '*/2',  :ng => false, :name => 'EBSManager'},
          {:hour => '*',    :minute => '*/20', :ng => false, :name => 'RolesQueue'},
          {:hour => '*',    :minute => '*/5',  :ng => true,  :name => 'DbMsrMaintenance'},
          {:hour => '*',    :minute => '*/20', :ng => true,  :name => 'LeaseManager'},
          {:hour => '*',    :minute => '*',    :ng => true,  :name => 'ServerTerminate'},
          {:hour => '*/5',  :minute => '0',    :ng => false, :name => 'RotateLogs'},
          {:hour => '*/12', :minute => '0',    :ng => false, :name => 'CloudPricing'},
          {:hour => '1',    :minute => '0',    :ng => false, :name => 'AnalyticsNotifications'},
      ]

      all_crons.concat %w{SzrMessagingAll SzrMessagingBeforeHostUp SzrMessagingHostInit SzrMessagingHostUp}.collect {
                           |name| {:hour => '*', :minute => '*/2', :ng => false, :name => name}
                       }

      all_crons
    end

    def enabled_crons(node)
      _filter_enabled(node, :cron, _all_crons)
    end

    def disabled_crons(node)
      _filter_disabled(node, :cron, _all_crons)
    end

    # Web helper

    def _all_web(node)
      [
          {
              :name => 'app',
              :root => "#{scalr_bundle_path node}/app/www",
              :bind_host => node[:scalr_server][:web][:app_bind_host],
              :bind_port => node[:scalr_server][:web][:app_bind_port],
          },
          {
              :name => 'graphics',
              :root => "#{data_dir_for node, 'service'}/graphics",
              :bind_host => node[:scalr_server][:web][:graphics_bind_host],
              :bind_port => node[:scalr_server][:web][:graphics_bind_port],
          },
      ]
    end

    def enabled_web(node)
      _filter_enabled(node, :web, _all_web(node))
    end

    def disabled_web(node)
      _filter_disabled(node, :web, _all_web(node))
    end

    # Generic module status helper #

    def enable_module?(node, mod)
      # Ensure that mod is a symbol
      mod = mod.to_sym

      # Supervisor is always enabled.
      if mod == :supervisor
        return true
      end

      # App is enabled if anything that requires the app user is enabled.
      if mod == :app
        %w{cron rrd service web proxy}.each do |dependent_mod|
          if enable_module?(node, dependent_mod)
            return true
          end
        end
        return false
      end

      # HTTPD is enabled if we have web or proxy
      if mod == :httpd
        return enable_module?(node, :web) || enable_module?(node, :proxy)
      end

      # Ordering matters a lot in the line below. We want to return the module's own enable settings so that if it's
      # not set to false, we get that one back (instead of a generic `true`). This then used in _filter enabled above.
      node[:scalr_server][mod][:enable] || node[:scalr_server][:enable_all]
    end

    # Service status helpers #

    # From: https://github.com/poise/supervisor/blob/master/providers/service.rb
    def service_status(node, svc)
      cmd = "#{node[:scalr_server][:install_root]}/embedded/bin/supervisorctl -c #{etc_dir_for node, 'supervisor'}/supervisord.conf status"
      result = Mixlib::ShellOut.new(cmd).run_command
      match = result.stdout.match("(^#{svc}(\\:\\S+)?\\s*)([A-Z]+)(.+)")
      if match.nil?
        'UNAVAILABLE'
      else
        match[3]
      end
    end

    def service_exists?(node, svc)
      File.exist?("#{node['supervisor']['dir']}/#{svc}.conf")
    end

    def service_is_up?(node, svc)
      service_exists?(node, svc) && (%w{RUNNING STARTING}.include? service_status(node, svc))
    end

  end
end


# Hook in
unless Chef::Recipe.ancestors.include?(Scalr::ServiceHelper)
  Chef::Recipe.send(:include, Scalr::ServiceHelper)
  Chef::Resource.send(:include, Scalr::ServiceHelper)
  Chef::Provider.send(:include, Scalr::ServiceHelper)
end
