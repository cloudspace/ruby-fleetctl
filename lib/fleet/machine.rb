module Fleet
  class Machine
    attr_reader :cluster, :id, :ip, :metadata

    def initialize(params)
      @cluster = params[:cluster]
      @id = params[:id]
      @ip = params[:ip]
      @metadata = params[:metadata]
    end

    def controller
      cluster.controller
    end

    def units
      controller.units.select { |unit| unit.machine.id == id }
    end

    # run the command (string, array of command + args, whatever) and return stdout
    def ssh(*command, port: 22)
      runner = Fleetctl::Runner::SSH.new([*command].flatten.compact.join(' '))
      runner.run(host: ip, ssh_options: { port: port })
      runner.output
    end

    def ==(other_machine)
      id == other_machine.id && ip == other_machine.ip
    end

    alias_method :eql?, :==
  end
end
