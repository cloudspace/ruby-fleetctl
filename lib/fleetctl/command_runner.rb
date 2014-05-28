module Fleet
  class CommandRunner
    attr_reader :command, :status, :return_code

    def initialize(command)
      @command = command.to_s
    end

    def run
      return @output if @output
      Rails.logger.info "RUNNING: #{command}"
      @output = `#{command}`
      @status = $?
      @return_code = @status.exitstatus
      @output
    end

    def output
      @output || run
    end
  end
end