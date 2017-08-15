require 'mutations'

module Mutations
  class DecimalFilter < AdditionalFilter
    @default_options = {
      :nils => false,       # true allows an explicit nil to be valid. Overrides any other options
      :min => nil,          # lowest value, inclusive
      :max => nil           # highest value, inclusive
    }

    def filter(data)
      # Handle nil case
      if data.nil?
        return [nil, nil] if options[:nils]
        return [nil, :nils]
      end

      # Now check if it's empty:
      return [data, :empty] if data == ""

      # Ensure it's the correct data type (BigDecimal)
      if !data.is_a?(BigDecimal)
        if data.is_a?(String) && data =~ /^[-+]?\d*\.?\d+/
          data = BigDecimal.new(data)
        elsif data.is_a?(Float)
          data = BigDecimal.new(data, Float::DIG)
        elsif data.is_a?(Integer)
          data = BigDecimal.new(data)
        else
          return [data, :big_decimal]
        end
      end

      return [data, :min] if options[:min] && data < options[:min]
      return [data, :max] if options[:max] && data > options[:max]

      # We win, it's valid!
      [data, nil]
    end
  end
end
