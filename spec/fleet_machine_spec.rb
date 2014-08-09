describe Fleet::Machine do

  let(:cluster) { double('cluster') }
  let(:machine_id) { '253844108ba4f10d' }
  let(:machine_ip) { Support::random_ipv4 }
  let(:machine_metadata) { 'region=us-west,az=us-west-1' }

  subject { Fleet::Machine.new cluster: cluster,
                               id: machine_id,
                               ip: machine_ip,
                               metadata: machine_metadata }

  it 'should be correctly initialized' do
    expect(subject.cluster).to eq(cluster)
    expect(subject.id).to eq(machine_id)
    expect(subject.ip).to eq(machine_ip)
    expect(subject.metadata).to eq(machine_metadata)
  end

  it 'should return the controller of it\'s cluster' do
    ctrl = double('controller')
    allow(cluster).to receive(:controller).and_return(ctrl)

    expect(subject.controller).to eq(ctrl)
  end

  it 'should return an array of it\'s units' do
    units_machines = []
    ctrl = double('controller', units: Array.new(4) {
          m = [subject, double('other_machine', id: 'another', ip: '')].sample
          u = Fleet::Unit.new machine: m
          units_machines << u if subject == m
          u
    })
    allow(cluster).to receive(:controller).and_return(ctrl)

    expect(subject.units).to eq(units_machines)
  end

  describe '#ssh' do
    let(:runner) { double('runner').as_null_object }

    before :each do
      allow(Fleetctl::Runner::SSH).to receive(:new).and_return(runner)
    end

    it 'should execute the correct ssh command' do
      expect(Fleetctl::Runner::SSH).to receive(:new).once
                                       .with('fleetctl cat service')

      subject.ssh %w(fleetctl cat service)
    end

    it 'should execute the ssh command against the correct host:port' do
      expect(runner).to receive(:run).with(host: machine_ip,
                                           ssh_options: { port: 42 })

      subject.ssh %w(fleetctl cat service), port: 42
    end

    it 'should return the output of the command' do
      allow(runner).to receive(:output).and_return('ssh result')

      expect(subject.ssh %w(fleetctl cat service)).to eq('ssh result')
    end
  end

  specify ':eql? is an alias of :==' do
    expect(subject.method(:==)).to eq(subject.method(:eql?))
  end

  it 'should be equal' do
    expect(subject).to eq(Fleet::Machine.new ip: machine_ip, id: machine_id)
    expect(subject).to eq(Fleet::Machine.new ip: machine_ip, id: machine_id, metadata: machine_metadata)
    expect(subject).to eq(Fleet::Machine.new ip: machine_ip, id: machine_id, metadata: 'machine_metadata')
  end

  it 'should not be equal' do
    # no metadata
    expect(subject).to_not eq(Fleet::Machine.new ip: Support::random_ipv4, id: 'a7424')
    expect(subject).to_not eq(Fleet::Machine.new ip: machine_ip, id: 'a7424')
    expect(subject).to_not eq(Fleet::Machine.new ip: Support::random_ipv4, id: machine_id)

    # same metadata
    expect(subject).to_not eq(Fleet::Machine.new ip: Support::random_ipv4, id: 'a7424', metadata: machine_metadata)
    expect(subject).to_not eq(Fleet::Machine.new ip: machine_ip, id: 'a7424', metadata: machine_metadata)
    expect(subject).to_not eq(Fleet::Machine.new ip: Support::random_ipv4, id: machine_id, metadata: machine_metadata)

    # different metadata
    expect(subject).to_not eq(Fleet::Machine.new ip: Support::random_ipv4, id: 'a7424', metadata: 'machine_metadata')
    expect(subject).to_not eq(Fleet::Machine.new ip: machine_ip, id: 'a7424', metadata: 'machine_metadata')
    expect(subject).to_not eq(Fleet::Machine.new ip: Support::random_ipv4, id: machine_id, metadata: 'machine_metadata')
  end
end