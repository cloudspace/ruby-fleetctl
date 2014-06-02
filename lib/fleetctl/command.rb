module Fleet
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

    def run
      runner.run
      runner
    end

    def runner
      @runner ||= CommandRunner.new(expression)
    end

    private

    def prefix
      # TODO: figure out a better way to avoid auth issues
      "eval `ssh-agent -s` >/dev/null 2>&1; ssh-add >/dev/null 2>&1;"
    end

    def global_options
      Fleet.options.global.map { |k,v| "--#{k.to_s.gsub('_','-')}=#{v}" }
    end

    def executable
      Fleet.options.executable
    end

    def expression
      [prefix, executable, global_options, command].flatten.compact.join(' ')
    end
  end
end