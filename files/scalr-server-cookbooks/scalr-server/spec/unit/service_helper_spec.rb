require 'spec_helper'

describe Scalr::ServiceHelper do
  let(:node) { ChefSpec::SoloRunner.new.node }
  let(:dummy_class) { Class.new { include Scalr::ServiceHelper } }

  describe '#services' do
    it 'should return the right services' do
      node.set[:scalr_server][:service][:enable] = true
      node.set[:scalr_server][:service][:disable] = []

      enabled_services = dummy_class.new.enabled_services(node).collect {|service| service[:name]}
      expect(enabled_services).to eq(%w{msgsender dbqueue plotter poller szrupdater analytics_poller analytics_processor})
    end

    it 'should work implicitly' do
      node.set[:scalr_server][:enable_all] = true
      node.set[:scalr_server][:service][:enable] = false
      node.set[:scalr_server][:service][:disable] = []

      services = dummy_class.new.enabled_services(node).collect {|service| service[:name]}
      expect(services.length).to eq(7)
    end

    it 'should support false' do
      node.set[:scalr_server][:service][:enable] = false
      expect(dummy_class.new.enabled_services(node).length).to eq(0)
      expect(dummy_class.new.disabled_services(node).length).to eq(7)
    end

    it 'should support filtered services' do
      node.set[:scalr_server][:service][:enable] = %w{plotter poller}
      node.set[:scalr_server][:service][:disable] = []
      expect(dummy_class.new.enabled_services(node).length).to eq(2)
      expect(dummy_class.new.disabled_services(node).length).to eq(5)
    end

    it 'should support disable' do
      node.set[:scalr_server][:service][:enable] = %w{plotter poller}
      node.set[:scalr_server][:service][:disable] = %w{plotter}

      expect(dummy_class.new.enabled_services(node).length).to eq(1)
      expect(dummy_class.new.disabled_services(node).length).to eq(6)
    end

    it 'should support disable' do
      node.set[:scalr_server][:service][:enable] = true
      node.set[:scalr_server][:service][:disable] = %w{plotter poller}
      expect(dummy_class.new.enabled_services(node).length).to eq(5)
      expect(dummy_class.new.disabled_services(node).length).to eq(2)
    end
  end

  describe '#crons' do
    it 'should return the right crons' do
      node.set[:scalr_server][:cron][:enable] = true
      node.set[:scalr_server][:cron][:disable] = []
    end

    it 'should support false' do
      node.set[:scalr_server][:cron][:enable] = false
      node.set[:scalr_server][:cron][:disable] = []
      expect(dummy_class.new.enabled_crons(node).length).to eq(0)
      expect(dummy_class.new.disabled_crons(node).length).to eq(19)
    end

    it 'should support filtered crons' do
      node.set[:scalr_server][:cron][:enable] = %w{Scheduler RotateLogs}
      node.set[:scalr_server][:cron][:disable] = []
      expect(dummy_class.new.enabled_crons(node).length).to equal(2)
      expect(dummy_class.new.disabled_crons(node).length).to equal(17)
    end

    it 'should support filters' do
      node.set[:scalr_server][:cron][:enable] = []
      node.set[:scalr_server][:cron][:disable] = []
      expect(dummy_class.new.enabled_crons(node).length).to eq(0)
      expect(dummy_class.new.disabled_crons(node).length).to eq(19)
    end

    it 'should support filters' do
      node.set[:scalr_server][:cron][:enable] = %w(DNSManagerPoll RotateLogs)
      node.set[:scalr_server][:cron][:disable] = []
      expect(dummy_class.new.enabled_crons(node).length).to eq(2)
      expect(dummy_class.new.disabled_crons(node).length).to eq(17)
    end

    it 'should support disabled' do
      node.set[:scalr_server][:cron][:enable] = true
      node.set[:scalr_server][:cron][:disable] = %w{DNSManagerPoll}
      expect(dummy_class.new.enabled_crons(node).length).to eq(18)
      expect(dummy_class.new.disabled_crons(node).length).to eq(1)
    end
  end

  describe '#enable_module?' do
     it 'should always enable supervisor' do
       expect(dummy_class.new.enable_module?(node, :supervisor)).to eq(true)
       expect(dummy_class.new.enable_module?(node, 'supervisor')).to eq(true)
     end

    it 'should special-case app' do
      # Check with all modules off
      node.set[:scalr_server][:enable_all] = false
      %w{web proxy rrd cron service}.each do |mod|
        node.set[:scalr_server][mod][:enable] = false
      end
      expect(dummy_class.new.enable_module?(node, :app)).to eq(false)

      # Check them one by one
      %w{web proxy rrd cron service}.each do |mod|
        node.set[:scalr_server][mod][:enable] = true
        expect(dummy_class.new.enable_module?(node, :app)).to eq(true)
        node.set[:scalr_server][mod][:enable] = false
      end

      # Check everything reset properly
      expect(dummy_class.new.enable_module?(node, :app)).to eq(false)

      # Check with all modules implicitly on
      node.set[:scalr_server][:enable_all] = true
      expect(dummy_class.new.enable_module?(node, :app)).to eq(true)
    end
  end

  it 'should special-case httpd' do
    %w{web proxy}.each do |mod|
      node.set[:scalr_server][mod][:enable] = true
      expect(dummy_class.new.enable_module?(node, :httpd)).to eq(true)
      node.set[:scalr_server][mod][:enable] = false
    end

    node.set[:scalr_server][:enable_all] = false
    expect(dummy_class.new.enable_module?(node, :httpd)).to eq(false)

    node.set[:scalr_server][:enable_all] = true
    expect(dummy_class.new.enable_module?(node, :httpd)).to eq(true)
  end

  it 'should work for other modules' do
    node.set[:scalr_server][:enable_all] = false
    node.set[:scalr_server][:mysql][:enable] = true
    expect(dummy_class.new.enable_module?(node, 'mysql')).to eq(true)

    node.set[:scalr_server][:mysql][:enable] = false
    expect(dummy_class.new.enable_module?(node, 'mysql')).to eq(false)

    node.set[:scalr_server][:enable_all] = true
    expect(dummy_class.new.enable_module?(node, 'mysql')).to eq(true)
  end
end
