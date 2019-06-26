json.id               contribution.id
json.donor_id         contribution.donor_id
json.amount_cents     contribution.amount_cents
json.scheduled_at     contribution.scheduled_at
json.portfolio do
  json.partial! 'portfolio', portfolio: contribution.portfolio
end