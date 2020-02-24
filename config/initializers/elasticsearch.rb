require 'searchkick'

if ENV['BONSAI_URL']
  Searchkick.client = Elasticsearch::Client.new host: ENV['BONSAI_URL'], port: 443
elsif ENV['SEARCHBOX_URL']
  Searchkick.client = Elasticsearch::Client.new host: ENV['SEARCHBOX_URL'], port: 443
end