module Fleet
  class Controller
    attr_writer :units
    attr_accessor :cluster, :options

    def initialize(*opts)
      @options = Fleetctl::Options.new(*opts)
      @cluster = Fleet::Cluster.new(controller: self, options: @options)
    end

    # returns an array of Fleet::Machine instances
    def machines
      cluster.machines
    end

    def machines!
      build_fleet
      machines
    end

    # returns an array of Fleet::Unit instances
    def units
      return @units.to_a if @units
      machines
      fetch_units
    end

    def units!
      fetch_units
    end

    # refreshes local state to match the fleet cluster
    def sync
      build_fleet
      fetch_units
      true
    end

    # find a unitfile of a specific name
    def [](unit_name)
      units.detect { |u| u.name == unit_name }
    end

    # accepts one or more File objects, or an array of File objects
    def start(*unit_file_or_files)
      unitfiles = [*unit_file_or_files].flatten
      out = unitfile_operation(:start, unitfiles)
      clear_units
      out
    end

    # def []=(unit_name, unit_file)

    # end

    # accepts one or more File objects, or an array of File objects
    def submit(*unit_file_or_files)
      unitfiles = [*unit_file_or_files].flatten
      out = unitfile_operation(:submit, unitfiles)
      clear_units
      out
    end

    # accepts one or more File objects, or an array of File objects
    def load(*unit_file_or_files)
      unitfiles = [*unit_file_or_files].flatten
      out = unitfile_operation(:load, unitfiles)
      clear_units
      out
    end

    def destroy(*unit_names)
      Fleetctl::Command.new('destroy', unit_names, options: options) do |runner|
        runner.run(command_runner_arguments)
        clear_units
        runner.exit_code == 0
      end
    end

    private

    def build_fleet
      cluster.discover!
    end

    def fleet_host
      cluster.fleet_host
    end

    def clear_units
      @units = nil
    end

    def unitfile_operation(command, files)
      clear_units
      Fleetctl::RemoteTempfile.open(*files) do |*remote_filenames|
        Fleetctl::Command.new(command.to_s, remote_filenames, options: options) do |runner|
          return runner.exit_code == 0
        end
      end
    end

    def fetch_units(host: fleet_host)
      Fleetctl.logger.info 'Fetching units from host: '+host.inspect
      @units = Fleet::ItemSet.new
      Fleetctl::Command.new('list-units', '-l', options: options) do |runner|
        runner.run(command_runner_arguments)
        parse_units(runner.output)
      end
      @units.to_a
    end

    def parse_units(raw_table)
      unit_hashes = Fleetctl::TableParser.parse(raw_table)
      unit_hashes.each do |unit_attrs|
        if unit_attrs[:machine]
          machine_id, machine_ip = unit_attrs[:machine].split('/')
          unit_attrs[:machine] = cluster.add_or_find(Fleet::Machine.new(id: machine_id, ip: machine_ip))
        end
        unit_attrs[:name] = unit_attrs.delete(:unit)
        unit_attrs[:controller] = self
        @units.add_or_find(Fleet::Unit.new(unit_attrs))
      end
    end

    def command_runner_arguments(*opts)
      { host: fleet_host, user: options.fleet_user, ssh_options: options.ssh_options }.merge(opts)
    end
  end
end
