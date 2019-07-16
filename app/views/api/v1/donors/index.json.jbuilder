json.donors @donors do |donor|
  json.partial! 'info', donor: donor
end
