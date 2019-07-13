require 'searchkick'

if ENV['SEARCHBOX_URL']
  Searchkick.client = Elasticsearch::Client.new host: ENV['SEARCHBOX_URL'], port: 443
end