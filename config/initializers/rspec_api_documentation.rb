RspecApiDocumentation.configure do |config|
  config.docs_dir = Rails.root.join('doc', 'api')
  config.format = :JSON
end
