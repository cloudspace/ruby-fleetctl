module Fleet
  class Unit
    # http://linuxrackers.com/doku.php?id=fedora_systemd_services
    # LOAD   = Reflects whether the unit definition was properly loaded.
    # ACTIVE = The high-level unit activation state, i.e. generalization of SUB.
    # SUB    = The low-level unit activation state, values depend on unit type.
    attr_reader :controller, :name, :state, :load, :active, :sub, :desc, :machine

    def initialize(controller, name, state, load, active, sub, desc, machine)
      @controller = controller
      @name       = name
      @state      = state
      @load       = load
      @active     = active
      @sub        = sub
      @desc       = desc
      @machine    = machine
    end

    [:status, :destroy, :stop, :start, :cat, :unload].each do |method_name|
      define_method(method_name) do
        cmd    = Fleetctl::Command.new(method_name, self.name)
        runner = cmd.run(host: ip)
        runner.output
      end
    end

    def ip
      machine && machine.ip
    end

    def creating?
      active == 'activating' && sub == 'start-pre'
    end

    def failed?
      active == 'failed' && sub == 'failed'
    end

    def running?
      active == 'active' && sub == 'running'
    end

    # run the command on host (string, array of command + args, whatever) and return stdout
    def ssh(*command, port: 22)
      runner = Fleetctl::Runner::SSH.new([*command].flatten.compact.join(' '))
      runner.run(host: ip, ssh_options: {port: port})
      runner.output
    end

    # gets the external port corresponding to the internal port specified
    # assumes that this unit corresponds to a docker container
    # TODO: split this sort of docker-related functionality out into a separate class
    def docker_port(internal_port, container_name = name)
      docker_runner = Fleetctl::Runner::SSH.new('docker', 'port', container_name, internal_port)
      docker_runner.run(host: ip)
      output = docker_runner.output
      if output
        output.rstrip!
        output.split(':').last
      end
    end

    # TODO: GET THIS WORKING
    # # attempts to execute a command via ssh directly on the container
    # # assumes that this unit corresponds to a docker container
    # def container_ssh(*command, container_name: name, key: Dir.home+'/.ssh/id_rsa', username: 'root', password: nil)
    #   cmd_runner = Fleetctl::Runner::SSH.new([*command].flatten.compact.join(' '))
    #   cmd_runner.run(host: ip, ssh_options: { port: container_ssh_port(container_name), keys: [*key], username: username, password: password})
    #   runner.output
    # end

    # returns a JSON object representing the container
    # assumes that this unit corresponds to a docker container
    def docker_inspect(container_name = name)
      raw = ssh('docker', 'inspect', container_name)
      JSON.parse(raw)
    end

    def ==(other_unit)
      name == other_unit.name
    end

    alias_method :eql?, :==
  end
end
