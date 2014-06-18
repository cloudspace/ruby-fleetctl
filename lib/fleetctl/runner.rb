module Fleetctl
  class Runner
    attr_reader :command, :status, :exit_code, :stdout, :stderr, :exit_signal

    def initialize(*command)
      @command = [*command].flatten.compact.join(' ')
    end

    def run(host:, user:, ssh_options: {})
      # return @output if @output
      Fleetctl.logger.info(self.class.name) { "#{self.class.name} #{user}@#{host} RUNNING: #{command.inspect}" }
      Net::SSH.start(host, user, ssh_options) do |ssh|
        @stdout = ''
        @stderr = ''
        @exit_code = nil
        @exit_signal = nil
        ssh.open_channel do |channel|
          channel.exec(command) do |ch, success|
            unless success
              abort "FAILED: couldn't execute command (ssh.channel.exec)"
            end
            channel.on_data do |ch,data|
              @stdout_data+=data
            end

            channel.on_extended_data do |ch,type,data|
              @stderr_data+=data
            end

            channel.on_request('exit-status') do |ch,data|
              @exit_code = data.read_long
            end

            channel.on_request('exit-signal') do |ch, data|
              @exit_signal = data.read_long
            end
          end
        end
        ssh.loop
      end
      Fleetctl.logger.info(self.class.name) { "EXIT CODE!: #{exit_code.inspect}" }
      Fleetctl.logger.info(self.class.name) { "STDOUT: #{stdout.inspect}" }
      @output
    rescue Exception => e
      Fleetctl.logger.error(self.class.name) { 'Exception in Runner#run' }
      Fleetctl.logger.error(self.class.name) { e }
      raise e
    end
  end
end
