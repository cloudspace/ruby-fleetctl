require 'matrix'

describe Fleet::Unit do

  let(:controller) { double('controller') }
  let(:machine) { double('machine', ip: Support::random_ipv4) }
  let(:name) { 'Awesome Unit' }
  let(:states) { %w(inactive loaded launched) }
  let(:loads) { %w(inactive loaded) }
  let(:actives) { %w(failed activating active) }
  let(:subs) { %w(start-pre failed running) }

  subject { Fleet::Unit.new controller: controller,
                            machine: machine,
                            name: name,
                            state: states[2],
                            load: loads[1],
                            active: actives[4],
                            sub: subs[2]
  }

  it 'should be correctly initialized' do
    expect(subject.controller).to eq(controller)
    expect(subject.name).to eq(name)
    expect(subject.state).to eq(states[2])
    expect(subject.load).to eq(loads[1])
    expect(subject.active).to eq(actives[4])
    expect(subject.sub).to eq(subs[2])
    expect(subject.machine).to eq(machine)
  end

  describe 'unit actions' do
    let(:actions) { [:status, :destroy, :stop, :start, :cat, :unload] }

    let(:runner) { double('runner').as_null_object }

    before :each do
      allow(Fleetctl::Command).to receive(:new).and_return(runner)
    end

    it 'should execute the correct command' do
      actions.each do |action|
        expect(Fleetctl::Command).to receive(:new).once.with(action, name)

        subject.send action
      end
    end

    it 'should execute the ssh command against the correct host' do
      actions.each do |action|
        expect(runner).to receive(:run).with(host: machine.ip)

        subject.send action
      end
    end

    it 'should return the output of the command' do
      actions.each do |action|
        allow(runner).to receive(:output).and_return(action)

        expect(subject.send action).to eq(action)
      end
    end
  end

  it 'should return it\'s machine IP' do
    expect(subject.ip).to eq(machine.ip)
  end

  describe 'active/sub helpers' do
    let(:matrix) do
      Matrix.build(actives.length, subs.length) do |row, col|
        [actives[row], subs[col]]
      end
    end

    def test(method, active, sub)
      matrix.each do |state|
        machine = Fleet::Unit.new active: state[0], sub: state[1]
        if state[0] == active && state[1] == sub
          expect(machine.send method).to be true
        else
          expect(machine.send method).to be false
        end
      end
    end

    it 'should indicate when unit is creating' do
      test :creating?, 'activating', 'start-pre'
    end

    it 'should indicate when unit failed' do
      test :failed?, 'failed', 'failed'
    end

    it 'should indicate when unit is running' do
      test :running?, 'active', 'running'
    end
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
      expect(runner).to receive(:run).with(host: machine.ip,
                                           ssh_options: { port: 42 })

      subject.ssh %w(fleetctl cat service), port: 42
    end

    it 'should return the output of the command' do
      allow(runner).to receive(:output).and_return('ssh result')

      expect(subject.ssh %w(fleetctl cat service)).to eq('ssh result')
    end
  end

  describe '#docker_port' do
    let(:internal_port) { 8080 }

    let(:runner) { double('runner').as_null_object }

    before :each do
      allow(Fleetctl::Runner::SSH).to receive(:new).and_return(runner)
    end

    it 'should execute the correct ssh command' do
      expect(Fleetctl::Runner::SSH).to receive(:new).once
                                       .with('docker', 'port', 'container', internal_port)

      subject.docker_port internal_port, 'container'
    end

    it 'should execute the correct ssh command with default value' do
      expect(Fleetctl::Runner::SSH).to receive(:new).once
                                       .with('docker', 'port', subject.name, internal_port)

      subject.docker_port internal_port
    end

    it 'should execute the ssh command against the correct host:port' do
      expect(runner).to receive(:run).with(host: machine.ip)

      subject.docker_port internal_port
    end

    it 'should return the internal port of the container' do
      allow(runner).to receive(:output).and_return('0.0.0.0:8080')

      expect(subject.docker_port internal_port).to eq('8080')
    end
  end

  it 'should return the detail of the container' do
    expect(subject).to receive(:ssh).
                           with('docker', 'inspect', 'container').
                           and_return('[{"Name": "/container"}]')

    expect(subject.docker_inspect 'container').to eq([{'Name' => '/container'}])
  end

  it 'should return use the unit name as container name' do
    expect(subject).to receive(:ssh).
                           with('docker', 'inspect', 'Awesome Unit').
                           and_return('[]')

    subject.docker_inspect
  end

  specify ':eql? is an alias of :==' do
    expect(subject.method(:==)).to eq(subject.method(:eql?))
  end

  it 'should be equal' do
    expect(subject).to eq(Fleet::Unit.new name: name)
  end
end