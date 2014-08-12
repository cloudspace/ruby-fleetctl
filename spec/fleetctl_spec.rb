describe Fleetctl do

  it 'should return a new controller' do
    expect(Fleet::Controller).to receive(:new)
                                 .with('some', 'arguments')
                                 .and_return('ctl')

    expect(Fleetctl.new 'some', 'arguments').to eq('ctl')
  end

  it 'should have a single instance available' do
    instance = Fleetctl.instance

    expect(instance).to be_a(Fleet::Controller)
    expect(Fleetctl.instance).to eq(instance)
  end

  it 'should be possible to set global options' do
    cfg = {logger: Support::empty_logger}
    opts = Fleetctl::Options.new(cfg)
    Fleetctl.config cfg

    expect(Fleetctl.options).to eql(opts)
  end

  it 'provide an easy way to access the logger' do
    logger = Support::empty_logger

    Fleetctl.config logger: logger
    expect(Fleetctl.logger).to eq(logger)
  end

  describe 'provide shortcut for' do
    subject { Fleetctl.instance }

    it 'common actions' do
      [:machines, :units, :sync, :start, :submit, :load, :destroy].each do |method|
        expect(subject).to receive(method)
        Fleetctl.send method
      end
    end

    it 'direct access to units' do
      expect(subject).to receive(:[]).with('unit')
      Fleetctl['unit']
    end
  end
end