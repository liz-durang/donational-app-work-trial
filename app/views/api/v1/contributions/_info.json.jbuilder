json.id                     contribution.id
json.donor_id               contribution.donor_id
json.amount_cents           contribution.amount_cents
json.scheduled_at           contribution.scheduled_at
json.external_reference_id  contribution.external_reference_id
json.portfolio_id           contribution.portfolio.id
json.portfolio_allocations do
 json.array! contribution.portfolio.active_allocations do |allocation|
   json.organization_ein   allocation.organization_ein
   json.percentage         allocation.percentage
   json.name               allocation.organization.name
 end
end
