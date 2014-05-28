module Fleet
  class Unit
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

    def ==(other_unit)
      name == other_unit.name
    end

    alias_method :eql?, :==

    private

    def fetch_port(container_name, internal_port)
      execute_docker_command('port', container_name, internal_port)
    end

    def execute_docker_command(cmd)
      command = Fleet::Command.run('ssh', name, 'docker', cmd)
      command.output
    end
  end
end
