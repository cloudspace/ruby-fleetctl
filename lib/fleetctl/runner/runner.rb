module Fleetctl
  module Runner
    class Runner
      attr_reader :command, :status, :exit_code, :stdout_data, :stderr_data, :exit_signal

      def initialize(*command)
        @command = [*command].flatten.compact.join(' ')
      end

      def run(*)
        fail NotImplementedError
      end

      def output
        @output || run
      end
    end
  end
end
