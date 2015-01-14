module Fleetctl
  module Runner
    class SSH < ::Fleetctl::Runner::Runner
      def run(host: Fleetctl.options.fleet_host, user: Fleetctl.options.fleet_user, ssh_options: {})
        begin
          ssh_options = Fleetctl.options.ssh_options.merge(ssh_options)
          # return @output if @output
          Fleetctl.logger.info "#{self.class.name} #{user}@#{host} RUNNING: #{command.inspect}"
          Net::SSH.start(host, user, ssh_options) do |ssh|
            @stdout_data = ''
            @stderr_data = ''
            @exit_code = nil
            @exit_signal = nil
            ssh.open_channel do |channel|
              channel.exec(command) do |__, success|
                unless success
                  raise "FAILED: couldn't execute command (ssh.channel.exec)"
                end
                channel.on_data do |_,data|
                  @stdout_data+=data
                end

                channel.on_extended_data do |_, _,data|
                  @stderr_data+=data
                end

                channel.on_request('exit-status') do |_,data|
                  @exit_code = data.read_long
                end

                channel.on_request('exit-signal') do |_, data|
                  @exit_signal = data.read_long
                end
              end
            end
            ssh.loop
            @output = @stdout_data
          end
          Fleetctl.logger.info "EXIT CODE!: #{exit_code.inspect}"
          Fleetctl.logger.info "STDOUT: #{@output.inspect}"
          @output
        rescue => e
          Fleetctl.logger.error 'ERROR in Runner#run'
          Fleetctl.logger.error e.message
          Fleetctl.logger.error e.backtrace.join("\n")
          raise e
        end
      end
    end
  end
end
