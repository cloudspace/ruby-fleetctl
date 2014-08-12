require 'net/ssh'
require 'net/scp'
require 'hashie'
require 'forwardable'

require 'fleetctl/version'
require 'fleetctl/command'
require 'fleetctl/runner/runner'
require 'fleetctl/runner/ssh'
require 'fleetctl/runner/shell'
require 'fleetctl/table_parser'
require 'fleetctl/options'
require 'fleetctl/remote_tempfile'

require 'fleet/item_set'
require 'fleet/unit'
require 'fleet/machine'
require 'fleet/controller'
require 'fleet/discovery'
require 'fleet/cluster'

module Fleetctl
  class << self
    extend Forwardable
    def_delegators :instance, :machines, :units, :[], :sync, :start, :submit,
                              :load, :destroy

    attr_reader :options

    # use if you might need more than one fleet
    def new(*args)
      Fleet::Controller.new(*args)
    end

    # get the global singleton controller
    def instance
      @instance ||= Fleet::Controller.new
    end

    # set global configuration options
    def config(cfg)
      @options = Options.new(cfg)
    end

    # get the logger for fleet to use
    def logger
      options.logger
    end
  end
end
