module Fleet
  class Unit
    # http://linuxrackers.com/doku.php?id=fedora_systemd_services
    # LOAD   = Reflects whether the unit definition was properly loaded.
    # ACTIVE = The high-level unit activation state, i.e. generalization of SUB.
    # SUB    = The low-level unit activation state, values depend on unit type.
    attr_reader :controller, :name, :state, :load, :active, :sub, :desc, :machine

    def initialize(controller:, name:, state:, load:, active:, sub:, desc:, machine:)
      @controller = controller
      @name = name
      @state = state
      @load = load
      @active = active
      @sub = sub
      @machine = machine
    end

    [:status, :destroy, :stop, :start, :cat, :unload].each do |method_name|
      define_method(method_name) do
        cmd = Fleetctl::Command.new(method_name, self.name)
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
      runner = Fleetctl::Runner::SSH.new(*command.flatten.compact.join(' '))
      runner.run(host: ip, ssh_options: { port: port })
      runner.output
    end

    # gets the external port mapped to port 22 inside this unit's docker container
    # assumes that this unit corresponds to a docker container
    def container_ssh_port(container_name = name)
      return @container_ssh_port if defined? @container_ssh_port
      docker_runner = Fleetctl::Runner::SSH.new('docker', 'port', container_name, 22)
      docker_runner.run(host: ip)
      @container_ssh_port = docker_runner.output.split(':').last.rstrip
    end

    # attempts to execute a command via ssh directly on the container
    # assumes that this unit corresponds to a docker container
    def container_ssh(*command, container_name: name, key: Dir.home+'/.ssh/id_rsa')
      cmd_runner = Fleetctl::Runner::SSH.new(*command.flatten.compact.join(' '))
      cmd_runner.run(host: ip, ssh_options: { port: container_ssh_port(container_name), keys: [key] })
      runner.output
    end

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
