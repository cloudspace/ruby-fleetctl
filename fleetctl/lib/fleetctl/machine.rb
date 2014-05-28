module Fleet
  class Machine

    attr_reader :cluster, :id, :ip, :metadata

    def initialize(cluster: nil, id: nil, ip: nil, metadata: nil)
      @cluster = cluster
      @id = id
      @ip = ip
      @metadata = metadata
    end

    def units
      cluster.units.select { |unit| unit.machine.id == id }
    end

    def ==(other_machine)
      id == other_machine.id && ip == other_machine.ip
    end

    alias_method :eql?, :==
  end
end
