# This file should contain all the record creation needed to seed the database
# with its default values. The data can then be loaded with the
# rails db:seed command (or created alongside the database with db:setup).

one_for_the_world = Partner.find_or_create_by(name: 'One For The World') do |p|
  p.website_url = 'http://1fortheworld.org'
  p.platform_fee_percentage = 0.02
  p.donor_questions_schema = {
    questions: [
      {
        name: 'school',
        title: 'What organization/school are you affiliated with?',
        type: 'select',
        options: ['Harvard', 'Wharton', 'Other'],
        required: true
      },
      {
        name: 'city',
        title: 'Which city will you be living in when your donation commences?',
        type: 'text',
        required: false
      }
    ]
  }
end

Campaign.find_or_create_by(slug: '1ftw-wharton') do |c|
  c.partner = one_for_the_world
  c.title = 'The Wharton School Chapter'
  c.default_contribution_amounts = [10, 20, 50, 100]
end

Organizations::CreateOrUpdateOrganizationsFromGoogleSheets.run

PortfolioTemplate.create(
  partner: one_for_the_world,
  title: 'Random Picks',
  organization_eins: Organization.all.pluck(:ein).sample(8)
)
PortfolioTemplate.create(
  partner: one_for_the_world,
  title: "One charity - #{Organization.first.name}",
  organization_eins: [Organization.first.ein]
)
