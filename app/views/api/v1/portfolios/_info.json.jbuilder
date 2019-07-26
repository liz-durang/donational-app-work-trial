json.id           managed_portfolio.id
json.name         managed_portfolio.name
json.description  managed_portfolio.description
json.image        polymorphic_url(managed_portfolio.image) if managed_portfolio.image.attached?
json.allocations do
  json.array! managed_portfolio.portfolio.active_allocations do |allocation|
    json.organization_ein   allocation.organization_ein
    json.percentage         allocation.percentage
    json.name               allocation.organization.name
  end
end
