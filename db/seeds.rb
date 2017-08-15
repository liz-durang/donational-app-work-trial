# This file should contain all the record creation needed to seed the database
# with its default values. The data can then be loaded with the
# rails db:seed command (or created alongside the database with db:setup).
Organization.create(
  ein: 'give-directly',
  name: 'Give Directly',
  local_impact: false,
  global_impact: true,
  immediate_impact: true,
  long_term_impact: true
)
Organization.create(
  ein: 'research',
  name: 'Disease Research',
  local_impact: true,
  global_impact: true,
  immediate_impact: false,
  long_term_impact: true
)
Organization.create(
  ein: 'usa-relief',
  name: 'USA relief',
  local_impact: true,
  global_impact: false,
  immediate_impact: true,
  long_term_impact: false
)
Organization.create(
  ein: 'global-relief',
  name: 'Global relief',
  local_impact: false,
  global_impact: true,
  immediate_impact: true,
  long_term_impact: false
)
Organization.create(
  ein: 'usa-awareness',
  name: 'USA awareness',
  local_impact: true,
  global_impact: false,
  immediate_impact: false,
  long_term_impact: true
)
Organization.create(
  ein: 'global-awareness',
  name: 'Global awareness',
  local_impact: false,
  global_impact: true,
  immediate_impact: false,
  long_term_impact: true
)
Organization.create(
  ein: 'we-do-it-all',
  name: 'Does it all',
  local_impact: true,
  global_impact: true,
  immediate_impact: false,
  long_term_impact: true
)
