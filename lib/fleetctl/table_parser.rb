module Fleetctl
  class TableParser
    attr_accessor :raw

    class << self
      def parse(raw)
        self.new(raw).parse
      end
    end

    def initialize(raw)
      @raw = raw
    end

    def parse
      rows = raw.split("\n").map { |row| row.split(/\t+/) }
      header = rows.shift
      if header
        keys = header.map { |key| key.downcase.to_sym }
        [].tap do |output|
          rows.each do |row|
            scrubbed_row = row.map { |val| val == '-' ? nil : val }
            output << Hash[keys.zip(scrubbed_row)]
          end
        end
      else
        Fleetctl.logger.error('ERROR in Fleetctl::TableParser.parse - no header row found')
        []
      end
    end  
  end
end