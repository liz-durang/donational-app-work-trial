# This file should contain all the record creation needed to seed the database
# with its default values. The data can then be loaded with the
# rails db:seed command (or created alongside the database with db:setup).

one_for_the_world = Partner.find_or_create_by(name: 'One For The World') do |p|
  p.website_url = 'http://1fortheworld.org'
  p.platform_fee_percentage = 0.02
end

Campaign.find_or_create_by(slug: '1ftw-wharton') do |c|
  c.partner = one_for_the_world
  c.title = 'The Wharton School Chapter'
  c.default_contribution_amounts = [10, 20, 50, 100]
end

Organizations::CreateOrUpdateOrganizationsFromGoogleSheets.run
