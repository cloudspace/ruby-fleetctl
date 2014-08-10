module Fleetctl
  class RemoteTempfile
    class << self
      def open(local_file)
        remote_path = File.join(Fleetctl.options.remote_temp_dir,
                                File.basename(local_file.path))

        Net::SCP.upload!(Fleetctl.options.fleet_host,
                         Fleetctl.options.fleet_user,
                         local_file.path,
                         remote_path,
                         ssh: Fleetctl.options.ssh_options)

        yield(remote_path)

        Net::SSH.start(Fleetctl.options.fleet_host,
                       Fleetctl.options.fleet_user,
                       Fleetctl.options.ssh_options) do |ssh|
          ssh.exec!("rm #{remote_path}")
        end
      end
    end
  end
end
