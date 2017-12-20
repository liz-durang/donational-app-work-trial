require 'json'

module PandaPay
  def self.errors_from_response(api_response_json)
    response = JSON.parse(api_response_json, symbolize_names: true)

    response[:errors] || Array(response[:error])
  end
end
