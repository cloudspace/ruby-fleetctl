describe Fleetctl::Runner::Shell do

  let(:logger) { Support::empty_logger }
  subject { Fleetctl::Runner::Shell.new 'echo', 'system', 'call' }

  before :each do
    Fleetctl.config logger: logger
  end

  it 'should return the cached output if any' do
    subject.instance_eval("@output = 'output'")

    expect(subject.run).to eq('output')
  end

  it 'execute return the result of the command' do
    expect(subject).to receive(:`)
                       .with('echo system call')
                       .and_return('output')

    expect(subject.run).to eq('output')
  end

  it 'should log some information' do
    expect(logger).to receive(:info).with(/RUNNING: echo system call/)
    expect(logger).to receive(:info).with(/EXIT CODE!: [0-9]+/)
    expect(logger).to receive(:info).with(/STDOUT:/)

    subject.run
  end

  describe 'shell status' do
    before(:each) { subject.run }

    it 'should made executed process status accessible' do
      expect(subject.status).to be_a Process::Status
    end

    it 'should provide shortcut for exit information' do
      expect(subject.exit_signal).to eq(subject.status.termsig)
      expect(subject.exit_code).to eq(subject.status.exitstatus)
    end
  end
end