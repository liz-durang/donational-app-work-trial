# This file should contain all the record creation needed to seed the database
# with its default values. The data can then be loaded with the
# rails db:seed command (or created alongside the database with db:setup).

one_for_the_world = Partner.find_or_create_by(name: 'One For The World') do |p|
  p.website_url = 'http://1fortheworld.org'
  p.platform_fee_percentage = 0.02
  p.payment_processor_account_id = 'acct_1Cq2tLDFX5Cbjrb9'
  p.donor_questions_schema = {
    questions: [
      {
        name: 'school',
        title: 'What organization/school are you affiliated with?',
        type: 'select',
        options: ['Harvard', 'The Wharton School', 'Other'],
        required: true
      },
      {
        name: 'city',
        title: 'Which city will you be living in when your donation commences?',
        type: 'text',
        required: true
      }
    ]
  }
  p.description = "1% of the developed world's income can eliminate extreme poverty. Let it start with you."
end

Campaign.find_or_create_by(slug: '1ftw-wharton') do |c|
  c.partner = one_for_the_world
  c.title = 'The Wharton School Chapter'
  c.default_contribution_amounts = [10, 20, 50, 100]
  c.description = <<~EOTXT
    In the U.S., individuals with incomes between $100K-$200K donate on average 2.6% of their income to charity. How much will you give?

    Your generous contribution will provide life-saving solutions to impoverished communities, where millions of children die from health problems with well-known solutions. Donate now and help us end these preventable deaths.
  EOTXT
end

Organizations::CreateOrUpdateOrganizationsFromGoogleSheets.run

Organizations::CreateOrUpdateTaxExemptOrganizationsFromCSV.run(files: ['small_sample_for_testing.csv.zip'])

def create_portfolio_with_charities(charity_eins)
  Portfolio.create!.tap do |portfolio|
    Portfolios::AddOrganizationsAndRebalancePortfolio.run(
      portfolio: portfolio,
      organization_eins: charity_eins
    )
  end
end
ManagedPortfolio.create(
  partner: one_for_the_world,
  name: 'Random Picks',
  portfolio: create_portfolio_with_charities(Organization.all.pluck(:ein).sample(8))
)
ManagedPortfolio.create(
  partner: one_for_the_world,
  name: "One charity - #{Organization.first.name}",
  portfolio: create_portfolio_with_charities([Organization.last.ein])
)
ManagedPortfolio.create(
  partner: one_for_the_world,
  name: "All Charities",
  portfolio: create_portfolio_with_charities(Organization.all.pluck(:ein))
)
