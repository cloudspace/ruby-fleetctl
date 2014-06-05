require "fleetctl/version"
require 'fleetctl/command'
require 'fleetctl/command_runner'
require 'fleetctl/unit'
require 'fleetctl/machine'
require 'fleetctl/cluster'
require 'fleetctl/table_parser'
require 'fleetctl/options'
require 'fleetctl/item_set'

module Fleet
  class << self
    attr_reader :options

    def new
      Fleet::Cluster.new
    end

    def instance
      @instance ||= Fleet::Cluster.new
    end

    def sync
      instance.sync
    end

    def start(*units)
      Fleet::Cluster.new.start(*units)
    end

    def submit(*units)
      Fleet::Cluster.new.submit(*units)
    end

    def destroy(*units)
      Fleet::Cluster.new.destroy(*units)
    end

    def config(cfg)
      @options = Options.new(cfg)
    end
  end
end

