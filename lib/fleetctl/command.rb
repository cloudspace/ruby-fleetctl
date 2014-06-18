module Fleetctl
  class Command
    attr_accessor :command, :options

    class << self
      def run(*cmd, &blk)
        obj = new(*cmd, &blk)
        obj.run
      end
    end

    def initialize(*cmd, options: nil)
      @command = cmd
      @options = options
      yield(runner) if block_given?
    end

    def run(*args)
      runner.run(*args)
      runner
    end

    def runner
      @runner ||= Fleetctl::Runner.new(expression)
    end

    private

    def runner_options
      { host: options.fleet_host, user: options.fleet_user, ssh_options: options.ssh_options }
    end

    def global_options
      options.global.map { |k,v| "--#{k.to_s.gsub('_','-')}=#{v}" }
    end

    def prefix
      options.command_prefix
    end

    def executable
      options.executable
    end

    def expression
      [prefix, executable, global_options, command].flatten.compact.join(' ')
    end
  end
end
