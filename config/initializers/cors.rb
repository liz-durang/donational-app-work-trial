Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins '*'
    resource '/api/v1/organizations*',
      headers: :any,
      methods: %i(get options head)
  end
end