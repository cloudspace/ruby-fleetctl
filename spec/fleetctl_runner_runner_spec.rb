describe Fleetctl::Runner::Runner do
  subject { Fleetctl::Runner::Runner.new 'can', 'take', 'many', 'arguments' }

  it 'should assign the command as a property' do
    expect(subject.command).to eq('can take many arguments')
  end

  it 'should not be able to run by itself' do
    expect{subject.run}.to raise_error (NotImplementedError)
  end

  it 'should return the output of #run' do
    expect(subject).to receive(:run).once.and_return('output')

    expect(subject.output).to eq('output')
  end

  it 'should return the cached output if any' do
    allow(subject).to receive(:output).and_return('output')

    expect(subject.output).to eq('output')
  end
end