module Fleet
  class Controller
    attr_writer :units
    attr_accessor :cluster

    def initialize
      @cluster = Fleet::Cluster.new(controller: self)
    end

    # returns an array of Fleet::Machine instances
    def machines
      cluster.machines
    end

    # returns an array of Fleet::Unit instances
    def units
      return @units.to_a if @units
      machines
      fetch_units
      @units.to_a
    end

    def units_once
      fetch_units_once
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
      runner = Fleetctl::Command.run('destroy', unit_names)
      clear_units
      runner.exit_code == 0
    end

    private

    def build_fleet
      cluster.discover!
    end

    def fleet_host
      Fleetctl.options.fleet_host || cluster.fleet_host
    end

    def clear_units
      @units = nil
    end

    def unitfile_operation(command, files)
      clear_units
      if Fleetctl.options.runner_class.to_s == 'Shell'
        runner = Fleetctl::Command.run(command.to_s, files.map(&:path))
      else
        runner = nil
        Fleetctl::RemoteTempfile.open(*files) do |*remote_filenames|
          runner = Fleetctl::Command.run(command.to_s, remote_filenames)
        end
      end
      runner.exit_code == 0
    end

    def fetch_units(host: fleet_host)
      Fleetctl.logger.info 'Fetching units from host: '+host.inspect
      @units = Fleet::ItemSet.new
      Fleetctl::Command.new('list-units', '-l') do |runner|
        runner.run(host: host)
        parse_units(runner.output)
      end
      @units.to_a
    end

    #This was specific for getting the info back as a hash rather than as objects
    def fetch_units_once(host: fleet_host)
      Fleetctl.logger.info 'Fetching units from host: '+host.inspect
      command = Fleetctl::Command.new('list-units', '-l') do |runner|
        runner.run(host: host)
      end
      output_data = Fleetctl::TableParser.parse(command.runner.stdout_data)
      parse_units_once(output_data)
    end

    def parse_units_once(units)
      units.map do |unit|
        new_unit = {}
        new_unit[:name] = unit[:unit]
        new_unit[:ip] = unit[:machine].split('/').last
        new_unit[:active] = unit[:active]
        new_unit[:sub] = unit[:sub]
        new_unit
      end
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
  end
end
