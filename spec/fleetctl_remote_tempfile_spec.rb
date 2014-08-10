describe Fleetctl::RemoteTempfile do

  let(:local_file) { double('local_file', path: 'path') }
  let(:remote_path) { File.join Fleetctl.options.remote_temp_dir, local_file.path }
  let(:ssh) { double('ssh') }

  before :all do
    Fleetctl.config logger: Support::empty_logger
  end

  before :each do
    allow(Net::SCP).to receive(:upload!)
    allow(Net::SSH).to receive(:start)
  end

  it 'upload the correct local file to the correct remote path' do
    expect(Net::SCP).to receive(:upload!).with(anything, anything,
                                               local_file.path, remote_path,
                                               anything)

    Fleetctl::RemoteTempfile.open local_file do end
  end

  it 'upload the file to the correct remote' do
    expect(Net::SCP).to receive(:upload!).with(Fleetctl.options.fleet_host,
                                               Fleetctl.options.fleet_user,
                                               anything, anything,
                                               ssh: Fleetctl.options.ssh_options)

    Fleetctl::RemoteTempfile.open local_file do end
  end

  it 'yield the remote path' do
    Fleetctl::RemoteTempfile.open local_file do |*remote_filenames|
      expect(remote_filenames).to eq([remote_path])
    end
  end

  it 'ssh the remote host to remove the temporary file' do
    expect(Net::SSH).to receive(:start).and_yield(ssh)
    expect(ssh).to receive(:exec!).with("rm #{remote_path}")

    Fleetctl::RemoteTempfile.open local_file do end
  end

  it 'ssh to the correct remote host to remove the temporary file' do
    expect(Net::SSH).to receive(:start).with(Fleetctl.options.fleet_host,
                                             Fleetctl.options.fleet_user,
                                             Fleetctl.options.ssh_options)

    Fleetctl::RemoteTempfile.open local_file do end
  end
end