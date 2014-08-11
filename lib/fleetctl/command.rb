module Fleetctl
  class Command
    attr_accessor :command

    class << self
      def run(*cmd, &blk)
        obj = new(*cmd, &blk)
        obj.run
      end
    end

    def initialize(*cmd)
      @command = cmd
      yield(runner) if block_given?
    end

    def run(*args)
      runner.run(*args)
      runner
    end

    def runner
      klass = Kernel.const_get("Fleetctl::Runner::#{Fleetctl.options.runner_class}")
      @runner ||= klass.new(expression)
    end

    private

    def global_options
      Fleetctl.options.global.map { |k,v| "--#{k.to_s.gsub('_','-')}=#{v}" }
    end

    def prefix
      Fleetctl.options.command_prefix
    end

    def executable
      Fleetctl.options.executable
    end

    def expression
      [prefix, executable, global_options, command].flatten.compact.join(' ')
    end
  end
end
