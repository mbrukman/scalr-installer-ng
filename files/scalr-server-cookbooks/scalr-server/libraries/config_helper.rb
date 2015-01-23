require 'safe_yaml'
require_relative './path_helper'
require_relative './database_helper'
require_relative './service_helper'

SafeYAML::OPTIONS[:default_mode] = :safe


class Psych::Visitors::YAMLTree

    # We want everything to be sorted
    def visit_Hash(o)
        tag      = o.class == ::Hash ? nil : "!ruby/hash:#{o.class}"
        implicit = !tag

        register(o, @emitter.start_mapping(nil, tag, implicit, Psych::Nodes::Mapping::BLOCK))

        o.keys.sort.each do |k|  # This line is changed.
            accept k
            accept o[k]
        end

        @emitter.end_mapping
    end

    # We want to tolerate hashes and symbols
    def visit_Symbol(o)
        visit_String o.to_s
    end

end


TOP_MESSAGE = '
#####################################################################################################
# Warning                                                                                           #
# This file is auto-generated by the `/opt/scalr-server/bin/scalr-server-ctl reconfigure` command.  #
# Do not edit it manually. Your changes would be lost after an upgrade.                             #
#####################################################################################################
'

module Scalr
    module ConfigHelper
        include Scalr::PathHelper
        include Scalr::DatabaseHelper
        include Scalr::ServiceHelper

        def dump_scalr_configuration(node)

            scalr_conn_details = mysql_base_params(node).merge({
                                                                   :user => node[:scalr_server][:mysql][:scalr_user],
                                                                   :pass => node[:scalr_server][:mysql][:scalr_password],
                                                                   :name => node[:scalr_server][:mysql][:scalr_dbname],
                                                               })
            analytics_conn_details = scalr_conn_details.merge({
                                                                  :name => node[:scalr_server][:mysql][:analytics_dbname],
                                                              })


            # Actual configuration generated here.
            config = {
                :scalr => {
                    :connections => {
                        :mysql => scalr_conn_details.clone  # Ruby wants to use '1' as an alias, and PHP doesn't accept it..
                    },

                    :analytics => {
                        :enabled => true,
                        :connections => {
                            :analytics => analytics_conn_details.clone,
                            :scalr => scalr_conn_details.clone,
                        },
                        :poller => {
                            :cryptokey => "#{scalr_bundle_path node}/app/etc/.cryptokey"
                        }
                    },

                    :email => {
                        :address => node[:scalr_server][:app][:email_from_address],
                        :name => node[:scalr_server][:app][:email_from_name],
                    },

                    :auth_mode => 'scalr',
                    :instances_connection_policy => node[:scalr_server][:app][:instances_connection_policy],

                    :allowed_clouds => %w(ec2 gce eucalyptus cloudstack openstack idcf ocs ecs rackspacenguk rackspacengus nebula),

                    :system => {
                        :default_disable_firewall_management => false,
                        :instances_connection_timeout => 4,
                        :server_terminate_timeout => '+3 minutes',
                        :scripting => {
                            :logs_storage => 'instance',
                        },
                        :default_instance_log_rotation_period => 36000,
                        :default_abort_init_on_script_fail => 1
                    },

                    :endpoint => {
                        :scheme => node[:scalr_server][:routing][:endpoint_scheme],
                        :host => node[:scalr_server][:routing][:endpoint_host],
                    },

                    :aws => {
                        :ip_pool => node[:scalr_server][:app][:ip_ranges],
                        :security_group_name => "scalr.#{node[:scalr_server][:app][:id]}.ip-pool",
                    },

                    :billing => { :enabled => false },

                    :dns => {
                        :mysql => scalr_conn_details.clone,
                        :static => {
                            :enabled => false,
                            :nameservers => %w(ns1.example-dns.net ns2.example-dns.net),
                            :domain_name => 'example-dns.net',
                        },
                        :global => {
                            :enabled => false,
                            :nameservers => %w(ns1.example.net ns2.example.net ns3.example.net ns4.example.net),
                            :default_domain_name => 'provide.domain.here.in'
                        },
                    },


                    :load_statistics => {
                        :connections => {
                            :plotter => {
                                :scheme => node[:scalr_server][:routing][:plotter_scheme],
                                :bind_scheme => node[:scalr_server][:service][:plotter_bind_scheme],
                                :host => node[:scalr_server][:routing][:plotter_host],
                                :bind_host => node[:scalr_server][:service][:plotter_bind_host],
                                :bind_address => node[:scalr_server][:service][:plotter_bind_host],  # Deprecated
                                :port => node[:scalr_server][:routing][:plotter_port],
                                :bind_port => node[:scalr_server][:service][:plotter_bind_port],
                            },
                        },
                        :rrd =>{
                            :dir => data_dir_for(node, 'rrd'),
                            :run_dir => run_dir_for(node, 'rrd'),
                            :rrdcached_sock_path => "#{run_dir_for node, 'rrd'}/rrdcached.sock",
                        },
                        :img => {
                            :scheme => node[:scalr_server][:routing][:graphics_scheme],
                            :host => node[:scalr_server][:routing][:graphics_host],
                            :path => node[:scalr_server][:routing][:graphics_path],
                            :dir => "#{data_dir_for node, 'rrd'}/graphics"
                        }
                    },

                    :ui => { :mindterm_enabled => true },

                    :scalarizr_update => {
                        :mode => 'client',
                        :default_repo => 'stable',
                        :repos => {
                            :stable => {
                                :deb_repo_url => 'http://apt.scalr.net/debian scalr/',
                                :rpm_repo_url => 'http://rpm.scalr.net/rpm/rhel/$releasever/$basearch',
                                :win_repo_url => 'http://win.scalr.net',
                            },
                            :latest => {
                                :deb_repo_url => 'http://apt-delayed.scalr.net/debian scalr/',
                                :rpm_repo_url => 'http://rpm-delayed.scalr.net/rpm/rhel/$releasever/$basearch',
                                :win_repo_url => 'http://win-delayed.scalr.net',
                            },
                        }
                    }
                }
            }

            # The double dump / load stage is here to convert everything to "plain" objects that can then be loaded
            # by PHP / Python (because Chef attributes are *not* plain objects).
            TOP_MESSAGE + YAML.dump(SafeYAML.load(YAML.dump(config)))
        end

    end
end