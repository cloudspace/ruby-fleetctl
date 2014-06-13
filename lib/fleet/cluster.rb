module Fleet
  class Cluster < Fleet::ItemSet
    attr_accessor :controller

    def initialize(*args, controller: nil)
      @controller = controller
      super(*args)
    end

    def fleet_hosts
      map(&:ip)
    end

    def fleet_host
      fleet_hosts.sample
    end

    def machines
      discover! if empty?
      to_a
    end

    # attempts to rebuild the cluster from any of the hosts passed as arguments
    # returns the first ip that worked, else nil
    def build_from(*ip_addrs)
      ip_addrs = [*ip_addrs].flatten.compact
      begin
        Fleetctl.logger.info 'building from hosts: ' + ip_addrs.inspect
        built_from = ip_addrs.detect { |ip_addr| fetch_machines(ip_addr) }
        Fleetctl.logger.info 'built successfully from host: ' + built_from.inspect if built_from
        built_from
      rescue => e
        Fleetctl.logger.error 'ERROR building from hosts: ' + ip_addrs.inspect
        Fleetctl.logger.error e.message
        Fleetctl.logger.error e.backtrace.join("\n")
        nil
      end
    end

    # attempts a list-machines action on the given host.
    # returns true if successful, else false
    def fetch_machines(host)
      Fleetctl.logger.info 'Fetching machines from host: '+host.inspect
      clear
      Fleetctl::Command.new('list-machines', '-l') do |runner|
        runner.run(host: host)
        new_machines = parse_machines(runner.output)
        if runner.exit_code == 0
          return true
        else
          return false
        end
      end
    end

    def parse_machines(raw_table)
      machine_hashes = Fleetctl::TableParser.parse(raw_table)
      machine_hashes.map do |machine_attrs|
        machine_attrs[:id] = machine_attrs.delete(:machine)
        machine_attrs[:cluster] = self
        add_or_find(Fleet::Machine.new(machine_attrs))
      end
    end

    # attempts to rebuild the cluster by the specified fleet host, then hosts that it
    # has built previously, and finally by using the discovery url
    def discover!
      known_hosts = [Fleetctl.options.fleet_host] | fleet_hosts.to_a
      clear
      success_host = build_from(known_hosts) || build_from(Fleet::Discovery.hosts)
      if success_host
        Fleetctl.logger.info 'Successfully recovered from host: ' + success_host.inspect
      else
        Fleetctl.logger.info 'Unable to recover!'
      end
    end
  end
end
