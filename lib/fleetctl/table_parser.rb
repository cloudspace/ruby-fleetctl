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
      keys = rows.shift.map { |key| key.downcase.to_sym }
      [].tap do |output|
        rows.each do |row|
          scrubbed_row = row.map { |val| val == '-' ? nil : val }
          output << Hash[keys.zip(scrubbed_row)]
        end
      end
    end  
  end
end