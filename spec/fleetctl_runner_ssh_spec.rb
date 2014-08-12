describe Fleetctl::Runner::SSH do

  let(:logger) { Support::empty_logger }
  subject { Fleetctl::Runner::SSH.new 'echo', 'system', 'call' }

  before :each do
    Fleetctl.config logger: logger
  end

  context 'SSH connection' do
    it 'should connect with the given parameters' do
      expect(Net::SSH).to receive(:start).with('host', 'user', { port: 42 })

      subject.run host:'host', user:'user', ssh_options: { port: 42 }
    end

    it 'should use default parameters if none given' do
      expect(Net::SSH).to receive(:start).with(Fleetctl.options.fleet_host,
                                               Fleetctl.options.fleet_user,
                                               {})

      subject.run
    end

    it 'should raise and log errors if connection failed' do
      allow(Net::SSH).to receive(:start)
                         .and_raise(Net::SSH::AuthenticationFailed)
      expect(logger).to receive(:error).at_least(:twice)

      expect{subject.run}.to raise_error Net::SSH::AuthenticationFailed
    end
  end

  context 'Channel connection' do
    let(:session_mock) { double('session') }

    before :each do
      allow(Net::SSH).to receive(:start).and_yield(session_mock)

      allow(session_mock).to receive(:open_channel)
      allow(session_mock).to receive(:loop)
    end

    it 'open a channel and loop until it close' do
      expect(session_mock).to receive(:open_channel)
      expect(session_mock).to receive(:loop)

      subject.run
    end

    it 'should initialize some properties' do
      subject.run

      expect(subject.stdout_data).to eq('')
      expect(subject.stderr_data).to eq('')
      expect(subject.exit_code).to be_nil
      expect(subject.exit_signal).to be_nil
    end

    it 'should define output as stdout data' do
      allow(session_mock).to receive(:open_channel) do
        subject.instance_eval "@stdout_data = 'output'"
      end
      subject.run

      expect(subject.output).to eq('output')
    end
  end

  context 'Command execution' do
    let(:session_mock) { double('session') }
    let(:channel_mock) { double('channel') }
    let(:ssh_data) { double('data') }

    before :each do
      allow(Net::SSH).to receive(:start).and_yield(session_mock)

      allow(session_mock).to receive(:open_channel).and_yield(channel_mock)
      allow(session_mock).to receive(:loop)

      allow(channel_mock).to receive(:open_channel).and_yield(channel_mock)

      allow(channel_mock).to receive(:exec)
    end

    it 'should execute the correct command' do
      expect(channel_mock).to receive(:exec).with('echo system call')
      subject.run
    end
  end

  context 'Command processing' do
    let(:session_mock) { double('session') }
    let(:channel_mock) { double('channel') }
    let(:ssh_data) { double('data', read_long: 1) }

    before :each do
      allow(Net::SSH).to receive(:start).and_yield(session_mock)

      allow(session_mock).to receive(:open_channel).and_yield(channel_mock)
      allow(session_mock).to receive(:loop)

      allow(channel_mock).to receive(:open_channel).and_yield(channel_mock)

      allow(channel_mock).to receive(:exec).and_yield(channel_mock, true)

      allow(channel_mock).to receive(:on_data)
      allow(channel_mock).to receive(:on_extended_data)
      allow(channel_mock).to receive(:on_request)
    end

    it 'should raise an error if command unsuccessful' do
      allow(channel_mock).to receive(:exec).and_yield(channel_mock, false)

      expect{subject.run}.to raise_error /FAILED/
    end

    it 'should affect stdout data to property' do
      allow(channel_mock).to receive(:on_data)
                             .and_yield(nil, 'data')
      subject.run
      expect(subject.stdout_data).to eq('data')
    end

    it 'should concat stdout data to property' do
      allow(channel_mock).to receive(:on_data)
                             .and_yield(nil, 'data')
                             .and_yield(nil, '_data')
      subject.run
      expect(subject.stdout_data).to eq('data_data')
    end

    it 'should affect stderr data to property' do
      allow(channel_mock).to receive(:on_extended_data)
                             .and_yield(nil, nil, 'data_err')
      subject.run
      expect(subject.stderr_data).to eq('data_err')
    end

    it 'should concat stderr data to property' do
      allow(channel_mock).to receive(:on_extended_data)
                             .and_yield(nil, nil, 'data_err')
                             .and_yield(nil, nil, '_data_err')
      subject.run
      expect(subject.stderr_data).to eq('data_err_data_err')
    end

    it 'should affect exit code to property' do
      allow(channel_mock).to receive(:on_request).with('exit-status')
                             .and_yield(nil, ssh_data)

      subject.run
      expect(subject.exit_code).to eq(ssh_data.read_long)
    end

    it 'should affect exit signal to property' do
      allow(channel_mock).to receive(:on_request).with('exit-signal')
                             .and_yield(nil, ssh_data)

      subject.run
      expect(subject.exit_signal).to eq(ssh_data.read_long)
    end
  end
end