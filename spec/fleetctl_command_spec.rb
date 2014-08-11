describe Fleetctl::Command do

  class Fleetctl::Runner::MockRunner < Fleetctl::Runner::Runner
    def run(*_)
    end
  end

  let(:blk) { Proc.new { |_| } }

  subject { Fleetctl::Command.new 'some', 'command' }

  before :each do
    Fleetctl.config logger: Support::empty_logger, runner_class: 'MockRunner'
  end

  it 'should expose a run class method' do
    expect(Fleetctl::Command).to receive(:new)
                                 .with('some', 'command', blk)
                                 .and_return(double('command', run: 'output'))

    expect(Fleetctl::Command.run 'some', 'command', blk).to eq('output')
  end

  it 'should initialize correctly' do
    expect(subject.command).to eq(%w(some command))
  end

  it 'should yield the runner if block given' do
    Fleetctl::Command.new 'some', 'command' do |runner|
      expect(runner).to be_a Fleetctl::Runner::MockRunner
    end
  end

  it 'should return a runner' do
    expect(subject.runner).to be_a Fleetctl::Runner::Runner
  end

  it 'should reuse the same runner' do
    runner = subject.runner

    expect(subject.runner).to eq(runner)
  end

  it 'should execute the runner with the correct arguments and return the runner' do
    expect(subject.runner).to receive(:run)
                             .with('some', 'argument')
                             .and_return('result')

    expect(subject.run 'some', 'argument').to eq(subject.runner)
  end
end