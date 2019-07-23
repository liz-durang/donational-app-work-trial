json.id           donor.id
if donor.person?
  json.first_name   donor.first_name
  json.last_name    donor.last_name
elsif donor.entity?
  json.entity_name  donor.entity_name
end
json.email        donor.email
