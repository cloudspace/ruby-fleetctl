describe Fleet::ItemSet do

  subject { Fleet::ItemSet.new }
  let(:obj) { Object.new }

  it 'should return the object if none exist in' do
    expect(subject.add_or_find obj).to eq obj
  end

  it 'should return the object if already exist in' do
    subject.add_or_find obj

    expect(subject.add_or_find obj).to eq obj
  end
end