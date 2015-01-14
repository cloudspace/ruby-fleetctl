describe Fleetctl::Options do

  subject { Fleetctl::Options.new }

  it 'should have default values' do
    options = subject.to_hash symbolize_keys: true
    default_options_without_logger = subject.defaults.delete_if { |k| k == :logger }

    expect(options).to include(default_options_without_logger)
    expect(subject.logger).to be_a(Logger)
  end

  it 'should merge the given values' do
    options = Fleetctl::Options.new logger: 'log', global: { foo: 'bar' }

    expect(options.logger).to eq('log')
    expect(options.global).to include(foo: 'bar')
  end

  it 'should return the ssh_options values symbolized' do
    options = Fleetctl::Options.new ssh_options: {'port' => 22}

    expect(options.ssh_options).to eq({port: 22})
  end
end
