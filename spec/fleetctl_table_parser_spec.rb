describe Fleetctl::TableParser do

  let(:raw) { File.read 'spec/fixtures/table_parser_raw.txt' }

  context 'module' do
    let(:parser) { double('tableParser') }

    it 'should forward #parse to the underline class' do
      expect(Fleetctl::TableParser).to receive(:new).with(raw).and_return(parser)
      expect(parser).to receive(:parse)

      Fleetctl::TableParser.parse raw
    end
  end

  context 'class' do
    subject { Fleetctl::TableParser.new raw }

    it 'should initialize correctly' do
      expect(subject.raw).to eq(raw)
    end

    it 'should parse the raw data to a Hash' do
      expect(subject.parse).to eq([
               {machine: '4ce83dd1b1c94d67a', ip: '10.240.190.254', metadata: nil},
               {machine: 'aafdf1ed253844108', ip: '10.240.51.254', metadata: nil},
               {machine: 'd44af62acaf347b4a', ip: '10.240.159.164', metadata: nil}
                                ])
    end

    it 'should log an error if no data is passed' do
      logger = Support::empty_logger
      Fleetctl.config logger: logger
      subject.raw = ''

      expect(logger).to receive(:error).with(/Fleetctl::TableParser\.parse/)

      subject.parse
    end

    it 'should return an empty array if no data is passed' do
      subject.raw = 'data'

      expect(subject.parse).to eq([])
    end
  end

  context 'parser' do

    it 'should convert first line into hash keys, delimited by tab' do
      data = "h1\th2\th3\nv1"
      hash = Fleetctl::TableParser.parse data

      expect(hash).to eq([{h1: 'v1', h2: nil, h3: nil}])
    end

    it 'should affect next lines as value of hash, delimited by hash' do
      data = "h1\th2\th3\nv11\tv12\tv13\nv21\tv22\tv23"
      hash = Fleetctl::TableParser.parse data

      expect(hash).to eq([
                             {h1: 'v11', h2: 'v12', h3: 'v13'},
                             {h1: 'v21', h2: 'v22', h3: 'v23'}
                         ])
    end

    it 'should fill values as nil if none are found' do
      data = "h1\th2\th3\nv11\tv12\nv21"
      hash = Fleetctl::TableParser.parse data

      expect(hash).to eq([
                             {h1: 'v11', h2: 'v12', h3: nil},
                             {h1: 'v21', h2: nil, h3: nil}
                         ])
    end

    it 'should convert `-` to nil' do
      data = "h1\th2\th3\n-\tv12"
      hash = Fleetctl::TableParser.parse data

      expect(hash).to eq([{h1: nil, h2: 'v12', h3: nil}])
    end
  end
end