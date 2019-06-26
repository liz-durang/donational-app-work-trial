json.id               portfolio.id
json.allocations do
  json.array! portfolio.active_allocations do |allocation|
    json.organization_ein  allocation.organization_ein
    json.percentage        allocation.percentage
  end
end