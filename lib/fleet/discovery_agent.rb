module Fleet
  class DiscoveryAgent
    attr_accessor :discovery_url

    def initialize(url)
      @discovery_url = url
    end

    def run
      @hosts = nil
      hosts
    end

    private

    def discover
      url = URI.parse(discovery_url)
      result = Net::HTTP.get(url)
      JSON.parse(result)
    end

    def hosts
      @hosts ||= discover['node']['nodes'].map{|node| node['value'].split(':')[0..1].join(':').split('//').last}
    rescue => e
      Fleetctl.logger.error "ERROR in Fleet::DiscoveryAgent#hosts from url: #{discovery_url.inspect}, returning empty set"
      Fleetctl.logger.error e.message
      Fleetctl.logger.error e.backtrace.join("\n")
      []
    end
  end
end
