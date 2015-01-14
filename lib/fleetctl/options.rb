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
        runner_class: 'SSH',
        command_prefix: nil,
        discovery_url: nil,
        
        # for use with runner_class: 'SSH'
        # these aren't used wih a Shell runner
        fleet_host: nil,
        fleet_user: 'core',
        ssh_options: {},
        remote_temp_dir: '/tmp'
      }
    end

    def ssh_options
      self[:ssh_options].to_hash(symbolize_keys: true)
    end
  end
end
