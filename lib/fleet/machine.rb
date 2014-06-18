module Fleet
  class Machine
    attr_reader :cluster, :id, :ip, :metadata

    def initialize(cluster: nil, id: nil, ip: nil, metadata: nil)
      @cluster = cluster
      @id = id
      @ip = ip
      @metadata = metadata
    end

    def options
      cluster.options
    end

    def controller
      cluster.controller
    end

    def units
      controller.units.select { |unit| unit.machine.id == id }
    end

    # run the command (string, array of command + args, whatever) and return stdout
    def ssh(*command, port: 22)
      runner = Fleetctl::Runner.new([*command].flatten.compact.join(' '), host: ip, ssh_options: { port: port })
      runner.run
    end

    def ==(other_machine)
      id == other_machine.id && ip == other_machine.ip
    end

    alias_method :eql?, :==
  end
end
