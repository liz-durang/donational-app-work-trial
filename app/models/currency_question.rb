class CurrencyQuestion < Question
  def coerce(raw_value)
    raw_value.gsub(/[^0-9\.]/, '')
  end
end
