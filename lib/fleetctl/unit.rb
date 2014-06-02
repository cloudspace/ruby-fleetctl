module Fleet
  class Unit
    # http://linuxrackers.com/doku.php?id=fedora_systemd_services
    # LOAD   = Reflects whether the unit definition was properly loaded.
    # ACTIVE = The high-level unit activation state, i.e. generalization of SUB.
    # SUB    = The low-level unit activation state, values depend on unit type.
    attr_reader :cluster, :name, :state, :load, :active, :sub, :desc, :machine

    def initialize(cluster:, name:, state:, load:, active:, sub:, desc:, machine:)
      @cluster = cluster
      @name = name
      @state = state
      @load = load
      @active = active
      @sub = sub
      @machine = machine
    end

    [:status, :destroy, :stop, :start, :cat, :unload].each do |mname|
      define_method(mname) do
        Fleet::Command.run(mname, name).output 
      end
    end

    def ip
      machine && machine.ip
    end

    def ssh_port(container_name)
      fetch_port(container_name, 22)
    end

    def docker_inspect(container_name)
      output = execute_docker_command('inspect', container_name)
      JSON.parse(output).first
    end

    def docker_rm(container_name)
      output = execute_docker_command('rm', container_name)
    end

    def ==(other_unit)
      name == other_unit.name
    end

    alias_method :eql?, :==

    private

    def fetch_port(container_name, internal_port)
      execute_docker_command('port', container_name, internal_port)
    end

    def execute_docker_command(*cmd)
      command = Fleet::Command.run('ssh', name, 'docker', cmd)
      command.output
    end
  end
end
