module Fleetctl
  class Options < Hashie::Mash
    def initialize(*)
      deep_merge!(Hashie::Mash.new(defaults))
      super
    end

    def defaults
      {
        global: {},
        executable: 'fleetctl',
        logger: Logger.new(STDOUT),
        command_prefix: nil,
        discovery_url: nil,
        fleet_host: nil,
        fleet_user: 'core',
        ssh_options: {},
        remote_temp_dir: '/tmp'
      }
    end

    def ssh_options
      self[:ssh_options].symbolize_keys
    end
  end
end
