
FactoryBot.define do
  factory :uk_donor do
    first_name { 'John' }
    last_name { 'Donor' }
    title { 'Mr.' }
    house_name_or_number { '10' }
    postcode { 'PO1 3AX' }
  end
end
