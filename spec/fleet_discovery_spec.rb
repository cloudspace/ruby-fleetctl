require 'net/http'

describe Fleet::Discovery do

  let(:discovery_url) { 'http://discovery:4001/v2/keys/d8cd78ae' }
  let(:logger) { Support::empty_logger }

  subject { Fleet::Discovery.new discovery_url }

  before :each do
    allow(Net::HTTP).to receive(:get).and_return(
        '{ "node":{ "nodes": [ { "value": "http://10.240.50.254:7001" },
                               { "value": "http://10.240.51.254:7001" } ] } }')
  end

  it 'should be correctly initialized' do
    expect(subject.discovery_url).to eq(discovery_url)
  end

  it 'should return obtain the data of the discovery service' do
    expect(Net::HTTP).to receive(:get).once

    expect(subject.data).to eq(
        {'node' => {'nodes'=> [ {'value' => 'http://10.240.50.254:7001'},
                                {'value' => 'http://10.240.51.254:7001'}]}} )
  end

  it 'should return an array of hosts IP' do
    expect(subject.hosts).to eq(%w(10.240.50.254 10.240.51.254))
  end

  context 'class method' do
    before :each do
      Fleetctl.config logger: logger, discovery_url: discovery_url
    end

    it 'should return an array of hosts IP' do
      expect(Fleet::Discovery.hosts).to eq(%w(10.240.50.254 10.240.51.254))
    end

    it 'should make a new call each times' do
      expect(Net::HTTP).to receive(:get).twice

      2.times { Fleet::Discovery.hosts }
    end
  end
end