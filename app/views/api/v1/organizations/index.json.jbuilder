json.organizations @organizations do |organization|
  json.ein    organization.ein
  json.name   organization.name.titleize
  json.state  organization.state
end
