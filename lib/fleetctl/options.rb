require 'hashie'

module Fleet
  class Options < Hashie::Mash
    def initialize(opts = {})
      deep_merge!(Hashie::Mash.new(defaults))
      super
    end

    def defaults
      {
        global: {
          strict_host_key_checking: false
        },
        executable: 'fleetctl'
      }
    end
  end
end