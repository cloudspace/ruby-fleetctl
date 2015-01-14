describe Fleet::Cluster do

  before :all do
    Fleetctl.config logger: Support::empty_logger
  end

  let(:controller) { double 'controller' }
  subject { Fleet::Cluster.new controller: controller }

  it 'should be correctly initialized' do
    expect(subject.controller).to eq(controller)
    expect(subject.fleet_hosts).to be_empty
    expect(subject.fleet_host).to be_nil
  end

  context 'when we have three machines' do

    let(:ips) { [] }
    let(:machines) { [] }
    before :each do
      3.times do
        ip      = Support::random_ipv4
        machine = Fleet::Machine.new ip: ip

        subject.add_or_find machine
        ips << ip
        machines << machine
      end
    end

    it 'should return an array of ips' do
      expect(subject.fleet_hosts).to eq(ips)
    end

    it 'should return an ip from the pool' do
      expect(ips).to include(subject.fleet_host)
    end

    it 'should return all machines' do
      expect(subject.machines).to eq(machines)
    end

    it 'should not discover new machines' do
      expect(subject).to_not receive(:discover!)

      subject.machines
    end
  end

  context "when we don't have any machine" do
    it 'should load the cluster machines' do
      expect(subject).to receive(:discover!)

      subject.machines
    end
  end

  describe '#discover!' do

    let(:fleet_host) { Support::random_ipv4 }
    let(:logger) { Support::empty_logger }

    before :each do
      Fleetctl.config fleet_host: fleet_host, logger: logger
    end

    it 'should rebuild the cluster with the default fleet_host' do
      expect(subject).to receive(:build_from).
                             with([fleet_host]).
                             and_return(fleet_host)

      expect(logger).to receive(:info).with(Regexp.new fleet_host)

      subject.discover!
    end

    it 'should rebuild the cluster with a previously discovered host' do
      # Add previous machines
      ips = [fleet_host]
      3.times do
        ip = Support::random_ipv4

        subject.add_or_find Fleet::Machine.new ip: ip
        ips << ip
      end

      # Specification
      expect(subject).to receive(:build_from).
                             with(ips).
                             and_return(fleet_host)

      expect(logger).to receive(:info).with(Regexp.new fleet_host)

      subject.discover!
    end

    it 'should rebuild the cluster with the discovery URL' do
      Fleetctl.config logger: logger, discovery_url: 'url'
      allow(Fleet::Discovery).to receive(:hosts).and_return([])

      expect(subject).to receive(:build_from).with([nil])
      expect(subject).to receive(:build_from).
                             with(Fleet::Discovery.hosts).
                             and_return(fleet_host)

      expect(logger).to receive(:info).with(Regexp.new fleet_host)

      subject.discover!
    end

    it 'should log a failure' do
      allow(subject).to receive(:build_from)
      expect(logger).to receive(:info).with(/Unable to recover/)

      subject.discover!
    end
  end

  describe '#build_from' do
    let(:ip_addrs) { Array.new(3) { Support::random_ipv4 } }

    it 'should stop fetching machine when the first IP is valid' do
      expect(subject).to receive(:fetch_machines).once.with(ip_addrs[0]).
                             and_return(true)
      expect(subject).to_not receive(:fetch_machines).with(ip_addrs[1])

      expect(subject.build_from ip_addrs).to eq(ip_addrs[0])
    end

    it 'should stop fetching machine when the second IP is valid' do
      expect(subject).to receive(:fetch_machines).once.and_return(false)
      expect(subject).to receive(:fetch_machines).once.with(ip_addrs[1]).
                             and_return(true)
      expect(subject).to_not receive(:fetch_machines).with(ip_addrs[2])

      expect(subject.build_from ip_addrs).to eq(ip_addrs[1])
    end

    it 'should raise and log error if error' do
      allow(subject).to receive(:fetch_machines).and_raise(RuntimeError)

      expect(Fleetctl.logger).to receive(:error).at_least(3).times
      expect(subject.build_from ip_addrs).to be_nil
    end
  end

  describe '#fetch_machines' do
    let(:host) { Support::random_ipv4 }
    let(:runner) { double('runner').as_null_object }

    before :each do
      allow(Fleetctl::Command).to receive(:new).
                                      with('list-machines', '-l').
                                      and_yield(runner)
    end

    it 'should execute the command on the correct host' do
      expect(runner).to receive(:run).with(hash_including(host: host)).once

      subject.fetch_machines host
    end

    it 'should parse the result of the command' do
      allow(runner).to receive(:output).and_return('output')
      expect(subject).to receive(:parse_machines).with('output').once

      subject.fetch_machines host
    end

    it 'should return true if the command was successful' do
      allow(runner).to receive(:exit_code).and_return(0)

      expect(subject.fetch_machines host).to be true
    end

    it 'should return false if the command was unsuccessful' do
      allow(runner).to receive(:exit_code).and_return(42)

      expect(subject.fetch_machines host).to be false
    end
  end

  describe '#parse_machines' do
    let(:raw_table) { 'table' }
    let(:machines_parsed) { [
        {machine: '4ce83dd1b1c94d67af00ba264499b6d0', ip: '10.240.190.254', metadata: nil},
        {machine: 'aafdf1ed253844108ba4f10d75922f2b', ip: '10.240.51.254', metadata: nil},
        {machine: 'd44af62acaf347b4a1f26eeb0393fca3', ip: '10.240.159.164', metadata: nil}
    ] }
    let(:machines_expected) { [
        {id: '4ce83dd1b1c94d67af00ba264499b6d0', ip: '10.240.190.254', metadata: nil, cluster: subject},
        {id: 'aafdf1ed253844108ba4f10d75922f2b', ip: '10.240.51.254', metadata: nil, cluster: subject},
        {id: 'd44af62acaf347b4a1f26eeb0393fca3', ip: '10.240.159.164', metadata: nil, cluster: subject}
    ] }

    before :each do
      allow(Fleetctl::TableParser).to receive(:parse).and_return(machines_parsed)
    end

    it 'should try to add each machine to the cluster' do
      expect(subject).to receive(:add_or_find).exactly(machines_parsed.length).times

      subject.parse_machines raw_table
    end

    it 'should make sure that each machine is valid' do
      expect(subject).to receive(:add_or_find).with Fleet::Machine.new(machines_expected[0])
      expect(subject).to receive(:add_or_find).with Fleet::Machine.new(machines_expected[1])
      expect(subject).to receive(:add_or_find).with Fleet::Machine.new(machines_expected[2])

      subject.parse_machines raw_table
    end

  end

end