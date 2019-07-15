json.organizations @organizations do |organization|
  json.partial! 'info', organization: organization
end
