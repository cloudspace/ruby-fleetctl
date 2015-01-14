describe Fleet::Controller do

  subject { Fleet::Controller.new }

  it 'should be correctly initialized' do
    expect(subject.cluster).to be_a(Fleet::Cluster)
    expect(subject.cluster.controller).to eq(subject)
  end

  it 'should return all machines in the cluster' do
    expect(subject.cluster).to receive(:machines).once.and_return('machines')

    expect(subject.machines).to eq('machines')
  end

  it 'should return all units in the cluster' do
    subject.units = double('units', to_a: 'units')

    expect(subject).to_not receive(:machines)
    expect(subject).to_not receive(:fetch_units)

    expect(subject.units).to eq('units')
  end

  it 'should return all units in the cluster and fetch if none' do
    expect(subject).to receive(:machines)
    expect(subject).to receive(:fetch_units) { subject.units = ['unit'] }

    expect(subject.units).to eq(['unit'])
  end

  it 'should return units like an array' do
    subject.units = Array.new(3) { |i| double(name: "unit-#{i}") }

    expect(subject['unit-0']).to_not be_nil
    expect(subject['unit-3']).to be_nil
  end

  it 'let us sync the local cluster state' do
    expect(subject).to receive(:build_fleet).once
    expect(subject).to receive(:fetch_units).once

    expect(subject.sync).to be true
  end

  describe 'let us do some actions' do
    let(:actions) { [:start, :submit, :load] }

    it 'on one unit' do
      actions.each do |action|
        expect(subject).to receive(:unitfile_operation)
                           .with(action, ['unit-1'])
                           .and_return('out')
        expect(subject).to receive(:clear_units).once

        expect(subject.send action, 'unit-1').to eq('out')
      end
    end

    it 'on many units' do
      actions.each do |action|
        expect(subject).to receive(:unitfile_operation)
                           .with(action, %w(unit-1 unit-2))
                           .and_return('out')
        expect(subject).to receive(:clear_units).once

        expect(subject.send action, 'unit-1', 'unit-2' ).to eq('out')
      end
    end
  end

  context 'let us destroy' do
    let(:runner) { double('runner', exit_code: 0) }

    before :each do
      expect(subject).to receive(:clear_units).once
    end

    it 'one unit' do
      expect(Fleetctl::Command).to receive(:run)
                                   .with('destroy', %w(unit-1))
                                   .and_return(runner)

      expect(subject.destroy 'unit-1').to be true
    end

    it 'one unit and inform us if it failed' do
      expect(Fleetctl::Command).to receive(:run)
                                   .and_return(runner)
      allow(runner).to receive(:exit_code).and_return(42)

      expect(subject.destroy 'unit-1').to be false
    end

    it 'many units' do
      expect(Fleetctl::Command).to receive(:run)
                                   .with('destroy', %w(unit-1 unit-2))
                                   .and_return(runner)

      expect(subject.destroy 'unit-1', 'unit-2').to be true
    end

    it 'many units and inform us if it failed' do
      expect(Fleetctl::Command).to receive(:run)
                                   .and_return(runner)
      allow(runner).to receive(:exit_code).and_return(42)

      expect(subject.destroy 'unit-1', 'unit-2').to be false
    end
  end

end