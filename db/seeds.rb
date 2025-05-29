# This file should contain all the record creation needed to seed the database
# with its default values. The data can then be loaded with the
# rails db:seed command (or created alongside the database with db:setup).

one_for_the_world_charity = Organization.find_or_create_by(name: 'OFTW Operating Costs', ein: '84-2124550')
one_for_the_world_uk_charity = Organization.find_or_create_by(name: 'OFTW UK Operating Costs', ein: '11-1111111')

default_partner = Partner.find_or_create_by(name: Partner::DEFAULT_PARTNER_NAME) do |p|
  p.website_url = 'https://donational.org'
  p.description = 'Donational'
  p.donor_questions_schema = { questions: [] }
  p.payment_processor_account_id = ENV.fetch('DEFAULT_PAYMENT_PROCESSOR_ACCOUNT_ID')
end

oftw_donor_questions = [{ 'name' => 'phone_number',
                          'type' => 'text',
                          'title' => 'Mobile phone',
                          'options' => [],
                          'required' => true },
                        { 'name' => 'comms_email',
                          'type' => 'checkbox',
                          'title' => 'Yes, sign me up for email updates',
                          'options' => [],
                          'required' => false },
                        { 'name' => 'comms_phone',
                          'type' => 'checkbox',
                          'title' => 'Yes, sign me up for SMS updates',
                          'options' => [],
                          'required' => false },
                        { 'name' => 'birthday',
                          'type' => 'date',
                          'title' => 'When is your birthday?',
                          'options' => [],
                          'required' => false },
                        { 'name' => 'chapter',
                          'type' => 'select',
                          'title' => 'Enter your chapter name',
                          'options' => ['Accenture',
                                        'Australian National University',
                                        'Bain',
                                        'Bridgewater',
                                        'Boston Consulting Group',
                                        'Brock University',
                                        'Chicago Booth School of Business',
                                        'Cardozo Law School',
                                        'Columbia University',
                                        'Durham University',
                                        'George Washington University',
                                        'Google',
                                        'Kansas University Medical Center',
                                        'London School of Economics',
                                        'McGill University',
                                        'McKinsey',
                                        'Meta',
                                        'Microsoft',
                                        'Northeastern University',
                                        'Ohio State University',
                                        'Princeton University',
                                        'Queens University',
                                        'Syracuse University',
                                        'Tuck School of Business at Darthmouth',
                                        'UNC Kenan-Flagler',
                                        'University of Calgary',
                                        'University of Cambridge',
                                        'University of Cinncinati',
                                        'University of Maryland',
                                        'University of Miami',
                                        'University of Michigan',
                                        'University of Nebraska Medical Center',
                                        'University of Pennsylvania',
                                        'University of Pennsylvania Wharton',
                                        'University of Saskatchewan',
                                        'University of St Andrews',
                                        'University of Virginia Darden School of Business',
                                        'University of Virginia Law School',
                                        'Vanderbilt University',
                                        'Virginia Commonwealth University',
                                        'Western University',
                                        'Yale School of Management'],
                          'required' => true },
                        { 'name' => 'givewell_familiar',
                          'type' => 'select',
                          'title' => "Were you familiar with GiveWell's recommended nonprofits before you encountered One for the World?",
                          'options' => %w[Yes No],
                          'required' => true },
                        { 'name' => 'nonprofit_comms',
                          'type' => 'checkbox',
                          'title' => 'Share my name, contact info, and donation info with <b>the nonprofits I support</b>, so that they can email me and track their donations better',
                          'options' => [],
                          'required' => false },
                        { 'name' => 'givewell_comms',
                          'type' => 'checkbox',
                          'title' =>
                        'Share my name, contact info, and donation info with <b>GiveWell</b> so that they can email me and track their donations better',
                          'options' => [],
                          'required' => false },
                        { 'name' => 'OFTW_discretion',
                          'type' => 'checkbox',
                          'title' =>
                        'Just like other regranting nonprofits, One for the World has final say on donation allocation. We follow member preferences and will inform you before redirecting donations, if our recommended nonprofits change.',
                          'options' => [],
                          'required' => true }]

['Seeded/test OFTW US', 'Seeded/test OFTW UK', 'Seeded/test OFTW Canada',
 'Seeded/test OFTW Australia'].each do |oftw_partner_name|
  Partner.find_or_create_by(name: oftw_partner_name) do |p|
    p.website_url = 'http://1fortheworld.org'
    p.description = "[set by partner] 1% of the developed world's income can eliminate extreme poverty. Let it start with you. Voluptas modi molestias. Modi ipsum reprehenderit. Libero sunt optio."
    p.donor_questions_schema = { questions: oftw_donor_questions }
    p.after_donation_thank_you_page_url = 'https://1fortheworld.org/thank-you-page'
    p.platform_fee_percentage = 0.02
    p.uses_one_for_the_world_checkout = true
    p.operating_costs_text = 'For every $1 donated to One for the World, we raise $12 for effective charities. Please select here if you are happy for some of your donations to go to One for the World.'

    if 'UK'.in?(oftw_partner_name)
      p.currency = 'GBP'
      p.payment_processor_account_id = ENV.fetch('STRIPE_TEST_UK_ACCOUNT_ID')
      p.operating_costs_text = p.operating_costs_text.gsub('$', '£')
      p.operating_costs_organization = one_for_the_world_uk_charity
    elsif 'Canada'.in?(oftw_partner_name)
      p.currency = 'CAD'
      p.payment_processor_account_id = ENV.fetch('STRIPE_TEST_CAN_ACCOUNT_ID')
    elsif 'Australia'.in?(oftw_partner_name)
      p.currency = 'AUD'
      p.payment_processor_account_id = ENV.fetch('STRIPE_TEST_AUS_ACCOUNT_ID')
    else
      p.operating_costs_organization = one_for_the_world_charity
      p.currency = 'USD'
      p.payment_processor_account_id = ENV.fetch('STRIPE_TEST_US_ACCOUNT_ID')
    end
  end
end

us_partner = Partner.find_by(name: 'Seeded/test OFTW UK')
uk_partner = Partner.find_by(name: 'Seeded/test OFTW UK')

Campaign.find_or_create_by(slug: '1ftw-wharton') do |c|
  c.partner = us_partner
  c.title = 'The Wharton School Chapter'
  c.default_contribution_amounts = [10, 20, 50, 100]
  c.minimum_contribution_amount = 15
  c.contribution_amount_help_text = "$x a month is x% of an x students' average starting salary post-graduation (x% of $x). [this text comes from the 1ftw-wharton campaign settings]"
  c.description = <<~EOTXT
    In the U.S., individuals with incomes between $100K-$200K donate on average 2.6% of their income to charity. How much will you give?

    Your generous contribution will provide life-saving solutions to impoverished communities, where millions of children die from health problems with well-known solutions. Donate now and help us end these preventable deaths.
    [this text comes from the 1ftw-wharton campaign settings]
  EOTXT
end

Campaign.find_or_create_by(slug: '1ftw-uk') do |c|
  c.partner = uk_partner
  c.title = 'UK'
  c.default_contribution_amounts = [10, 20, 50, 100]
  c.description = <<~EOTXT
    In the U.K., individuals with incomes between £100-£200K donate on average 2.6% of their income to charity. How much will you give?

    Your generous contribution will provide life-saving solutions to impoverished communities, where millions of children die from health problems with well-known solutions. Donate now and help us end these preventable deaths.
    [this text comes from the 1ftw-uk campaign settings]
  EOTXT
end

Organizations::CreateOrUpdateOrganizationsFromGoogleSheets.run

Organizations::CreateOrUpdateTaxExemptOrganizationsFromCSV.run(files: ['small_sample_for_testing.csv.zip'])

def create_portfolio_with_charities(charity_eins)
  Portfolio.create!.tap do |portfolio|
    Portfolios::AddOrganizationsAndRebalancePortfolio.run(
      portfolio:,
      organization_eins: charity_eins
    )
  end
end
ManagedPortfolio.find_or_create_by(
  partner: us_partner,
  name: 'Random Picks',
  description: 'Molestiae rem esse. Qui ipsum vel. Dolores earum quaerat.',
  portfolio: create_portfolio_with_charities(Organization.all.pluck(:ein).sample(8))
)
ManagedPortfolio.find_or_create_by(
  partner: us_partner,
  name: "One charity - #{Organization.first.name}",
  description: 'Officiis dolorum tenetur. Molestiae suscipit id. Enim voluptas vero.',
  portfolio: create_portfolio_with_charities([Organization.last.ein])
)
ManagedPortfolio.find_or_create_by(
  partner: us_partner,
  name: 'All Charities',
  description: 'Unde non nihil. Magnam expedita voluptatem. Ea ut vel.',
  portfolio: create_portfolio_with_charities(Organization.all.pluck(:ein))
)
ManagedPortfolio.find_or_create_by(
  partner: default_partner,
  name: 'Random Picks',
  description: 'Soluta voluptatum et. Id impedit consequuntur. Aut consequatur id.',
  portfolio: create_portfolio_with_charities(Organization.all.pluck(:ein).sample(8))
)

ManagedPortfolio.find_or_create_by(
  partner: uk_partner,
  name: 'Random Picks',
  description: 'Totam ut perspiciatis. Cumque a consectetur. Soluta voluptate et.',
  portfolio: create_portfolio_with_charities(Organization.all.pluck(:ein).sample(8))
)
ManagedPortfolio.find_or_create_by(
  partner: uk_partner,
  name: "One charity - #{Organization.first.name}",
  description: 'Inventore vero officiis. Iste necessitatibus non. Et accusantium natus.',
  portfolio: create_portfolio_with_charities([Organization.last.ein])
)
ManagedPortfolio.find_or_create_by(
  partner: uk_partner,
  name: 'All Charities',
  description: 'Et vel repudiandae. Quam quos consequatur. Soluta recusandae omnis.',
  portfolio: create_portfolio_with_charities(Organization.all.pluck(:ein))
)

Partners::GetOftwPartners.call.each do |partner|
  ManagedPortfolio.find_or_create_by(
    partner:,
    display_order: 0,
    name: "Example Portfolio A for #{partner.name}",
    description: 'This example portfolio is associated to all of the charities. In quia alias. Nihil qui dolore. Incidunt molestiae quam.',
    portfolio: create_portfolio_with_charities(Organization.all.pluck(:ein)),
    featured: true
  )

  ManagedPortfolio.find_or_create_by(
    partner:,
    display_order: 1,
    name: "Example Portfolio B for #{partner.name}",
    description: 'This example portfolio is associated to just one charity. In quia alias. Nihil qui dolore. Incidunt molestiae quam.',
    portfolio: create_portfolio_with_charities([Organization.last.ein]),
    featured: true
  )

  ManagedPortfolio.find_or_create_by(
    partner:,
    display_order: 2,
    name: "Example Portfolio C for #{partner.name}",
    description: 'This example portfolio is associated to 8 randomly picked charities. In quia alias. Nihil qui dolore. Incidunt molestiae quam.',
    portfolio: create_portfolio_with_charities(Organization.all.pluck(:ein).sample(8)),
    featured: true
  )
end
