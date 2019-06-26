json.organizations @organizations do |organization|
  json.ein    organization.formatted_ein
  json.name   organization.formatted_name
  json.state  organization.state
end
