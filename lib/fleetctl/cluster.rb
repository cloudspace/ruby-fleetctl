module Fleet
  class Cluster
    attr_writer :machines, :units

    def machines
      return @machines.to_a if @machines
      sync
      @machines.to_a
    end

    def units
      return @units.to_a if @units
      sync
      @units.to_a
    end

    def sync
      fetch_machines
      fetch_units
      true
    end

    def [](unit_name)
      units.detect { |u| u.name == unit_name }
    end

    def submit(*files_or_paths_or_units)
      @units = nil
      paths = files_or_paths_or_units.map { |obj| obj.respond_to?(:path) ? obj.path : obj }
      runner = Fleet::Command.run('submit', paths)
      runner.return_code == 0
    end

    def start(*files_or_paths_or_units)
      @units = nil
      paths = files_or_paths_or_units.map { |obj| obj.respond_to?(:path) ? obj.path : obj }
      runner = Fleet::Command.run('start', paths)
      runner.return_code == 0
    end

    def destroy(*unit_names)
      runner = Fleet::Command.run('destroy', unit_names)
      runner.return_code == 0
    end

    def load
      # TODO: figure out what this is for then implement
    end

    def clear_units
      @units = nil
    end

    private

    def fetch_units
      @units = Fleet::ItemSet.new
      Fleet::Command.run('list-units', '-l') do |command|
        parse_units(command.output)
      end
      @units.to_a
    end

    def parse_units(raw_table)
      unit_hashes = Fleet::TableParser.parse(raw_table)
      unit_hashes.each do |unit_attrs|
        if unit_attrs[:machine]
          machine_id, machine_ip = unit_attrs[:machine].split('/')
          unit_attrs[:machine] = @machines.add_or_find(Fleet::Machine.new(id: machine_id, ip: machine_ip))
        end
        unit_attrs[:name] = unit_attrs.delete(:unit)
        unit_attrs[:cluster] = self
        @units.add_or_find(Fleet::Unit.new(unit_attrs))
      end
    end

    def fetch_machines
      @machines = Fleet::ItemSet.new
      Fleet::Command.run('list-machines', '-l') do |command|
        parse_machines(command.output)
      end
      @machines.to_a
    end

    def parse_machines(raw_table)
      machine_hashes = Fleet::TableParser.parse(raw_table)
      machine_hashes.map do |machine_attrs|
        machine_attrs[:id] = machine_attrs.delete(:machine)
        machine_attrs[:cluster] = self
        @machines.add_or_find(Fleet::Machine.new(machine_attrs))
      end
    end
  end
end