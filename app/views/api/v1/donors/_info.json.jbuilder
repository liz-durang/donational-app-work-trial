json.id           donor.id
if donor.person?
  json.first_name   donor.first_name
  json.last_name    donor.last_name
elsif donor.entity?
  json.entity_name  donor.entity_name
end
json.email        donor.email
if donor.uk_gift_aid_accepted 
  json.title                 donor.title
  json.house_name_or_number  donor.house_name_or_number
  json.postcode              donor.postcode
end

