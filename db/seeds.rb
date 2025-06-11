# This file should contain all the record creation needed to seed the database
# with its default values. The data can then be loaded with the
# rails db:seed command (or created alongside the database with db:setup).

puts "--- Starting Database Seed ---"

# --- 0. Clear Specified Data for a Fresh Seed ---
# Using delete_all for simplicity. TRUNCATE with RESTART IDENTITY CASCADE is more thorough for raw SQL.
puts "Clearing specified data for a fresh seed..."
# Order matters for deletion due to foreign keys if not using TRUNCATE CASCADE
models_to_clear = [
  Donation,             # Depends on Contribution, Portfolio, Organization, Allocation
  Contribution,         # Depends on Donor, Portfolio, Partner
  Subscription,         # Depends on Donor, Portfolio, Partner
  PartnerAffiliation,   # Depends on Donor, Partner, Campaign
  PaymentMethod,        # Depends on Donor
  Allocation,           # Depends on Portfolio, Organization
  SelectedPortfolio,    # <<<< ADDED: Depends on Donor, Portfolio
  ManagedPortfolio,     # Depends on Partner, Portfolio
  Portfolio,            # Depends on Donor (creator_id) - must be after its dependents
  SearchableOrganization, # Usually independent or only references Organization
  # Potentially Campaign (if PartnerAffiliation depends on it, it's already listed above)
  # Donor, Partner, Organization are tricky. If other tables still reference them,
  # they need to be last, or you need to handle their dependents first.
  # For a full wipe, you'd list almost all tables.
  # For now, let's focus on what your current list implies and add SelectedPortfolio.
]

# For a more complete wipe, you might need to list almost all your application's tables.
# This is a more targeted list based on what was there.
# The TRUNCATE CASCADE approach is more robust for a full wipe if it works for you.

models_to_clear.each do |model|
  # Ensure the model exists before trying to call table_name or delete_all
  if defined?(model) && model.respond_to?(:table_name)
    puts "  Deleting all from #{model.table_name}..."
    model.delete_all # Or model.destroy_all if you need callbacks to run (slower)
  else
    puts "  Skipping deletion for an undefined model or non-ActiveRecord constant in the list."
  end
end
# Donor, Organization, Partner are often best handled with find_or_create_by to preserve some core records
# or selectively deleted if necessary. For a complete wipe, add them to the list above
# IN THE CORRECT ORDER (dependents first).
# For now, let's assume the find_or_create_by below handles them.
puts "Data clearing complete."


# --- 1. Core Organizations and Default Partner ---
puts "\n--- Seeding Core Organizations and Default Partner ---"
one_for_the_world_charity = Organization.find_or_create_by!(name: 'OFTW Operating Costs', ein: '84-2124550')
one_for_the_world_uk_charity = Organization.find_or_create_by!(name: 'OFTW UK Operating Costs', ein: '11-1111111')

default_partner = Partner.find_or_create_by!(name: Partner::DEFAULT_PARTNER_NAME) do |p|
  p.website_url = 'https://donational.org'
  p.description = 'Donational'
  p.donor_questions_schema = { questions: [] }
  p.payment_processor_account_id = ENV.fetch('DEFAULT_PAYMENT_PROCESSOR_ACCOUNT_ID')
  p.currency = 'usd' # Assuming default partner is USD
end
puts "Ensured Default Partner: #{default_partner.name}"

# --- 2. OFTW Partner Setup ---
puts "\n--- Seeding OFTW Partners ---"
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
                          'options' => ['Accenture', 'Australian National University', 'Bain', 'Bridgewater', 'Boston Consulting Group', 'Brock University', 'Chicago Booth School of Business', 'Cardozo Law School', 'Columbia University', 'Durham University', 'George Washington University', 'Google', 'Kansas University Medical Center', 'London School of Economics', 'McGill University', 'McKinsey', 'Meta', 'Microsoft', 'Northeastern University', 'Ohio State University', 'Princeton University', 'Queens University', 'Syracuse University', 'Tuck School of Business at Darthmouth', 'UNC Kenan-Flagler', 'University of Calgary', 'University of Cambridge', 'University of Cinncinati', 'University of Maryland', 'University of Miami', 'University of Michigan', 'University of Nebraska Medical Center', 'University of Pennsylvania', 'University of Pennsylvania Wharton', 'University of Saskatchewan', 'University of St Andrews', 'University of Virginia Darden School of Business', 'University of Virginia Law School', 'Vanderbilt University', 'Virginia Commonwealth University', 'Western University', 'Yale School of Management'],
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
                          'title' => 'Share my name, contact info, and donation info with <b>GiveWell</b> so that they can email me and track their donations better',
                          'options' => [],
                          'required' => false },
                        { 'name' => 'OFTW_discretion',
                          'type' => 'checkbox',
                          'title' => 'Just like other regranting nonprofits, One for the World has final say on donation allocation. We follow member preferences and will inform you before redirecting donations, if our recommended nonprofits change.',
                          'options' => [],
                          'required' => true }]

['Seeded/test OFTW US', 'Seeded/test OFTW UK', 'Seeded/test OFTW Canada', 'Seeded/test OFTW Australia'].each do |oftw_partner_name|
  Partner.find_or_create_by!(name: oftw_partner_name) do |p|
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
    else # US
      p.operating_costs_organization = one_for_the_world_charity
      p.currency = 'USD'
      p.payment_processor_account_id = ENV.fetch('STRIPE_TEST_US_ACCOUNT_ID')
    end
  end
end
puts "Ensured OFTW Partners."

# --- 3. Fetch Specific Partners for Campaigns and ManagedPortfolios ---
# Use find_by! to ensure these exist, otherwise seeding later parts will fail.
us_partner = Partner.find_by!(name: 'Seeded/test OFTW US')
uk_partner = Partner.find_by!(name: 'Seeded/test OFTW UK')
puts "Fetched specific partners: #{us_partner.name}, #{uk_partner.name}"

# --- 4. Seed Campaigns ---
puts "\n--- Seeding Campaigns ---"
Campaign.find_or_create_by!(slug: '1ftw-wharton') do |c|
  c.partner = us_partner # Corrected to use the fetched us_partner
  c.title = 'The Wharton School Chapter'
  c.default_contribution_amounts = [10, 20, 50, 100]
  c.minimum_contribution_amount = 15
  c.contribution_amount_help_text = "$x a month is x% of an x students' average starting salary post-graduation (x% of $x). [this text comes from the 1ftw-wharton campaign settings]"
  c.description = "In the U.S., individuals with incomes between $100K-$200K donate on average 2.6% of their income to charity..." # Shortened for brevity
end

Campaign.find_or_create_by!(slug: '1ftw-uk') do |c|
  c.partner = uk_partner # Corrected to use the fetched uk_partner
  c.title = 'UK'
  c.default_contribution_amounts = [10, 20, 50, 100]
  c.description = "In the U.K., individuals with incomes between £100-£200K donate on average 2.6% of their income to charity..." # Shortened
end
puts "Ensured Campaigns."

# --- 5. Load Organizations from External Sources ---
# These need to run BEFORE ManagedPortfolios that depend on Organization.all
puts "\n--- Loading Organizations from External Sources ---"
puts "Running Organizations::CreateOrUpdateOrganizationsFromGoogleSheets..."
Organizations::CreateOrUpdateOrganizationsFromGoogleSheets.run
puts "Running Organizations::CreateOrUpdateTaxExemptOrganizationsFromCSV..."
Organizations::CreateOrUpdateTaxExemptOrganizationsFromCSV.run(files: ['small_sample_for_testing.csv.zip'])
puts "External organizations loaded. Total Organizations: #{Organization.count}"

# --- 6. Seed ManagedPortfolios ---
puts "\n--- Seeding ManagedPortfolios ---"
def create_portfolio_with_charities(charity_eins)
  # Ensure charity_eins are valid and exist if Portfolios::AddOrganizationsAndRebalancePortfolio expects persisted orgs
  valid_eins = Organization.where(ein: charity_eins).pluck(:ein)
  if valid_eins.empty? && charity_eins.any?
    puts "WARNING: No valid organizations found for EINS: #{charity_eins}. Portfolio will be empty or might fail."
    # Fallback to a generic known good organization if possible for seeding, or raise error
    # valid_eins = [Organization.first!.ein] if Organization.any? # Risky, ensure Organization.first! exists
  end
  
  Portfolio.create!.tap do |portfolio|
    if valid_eins.any?
      Portfolios::AddOrganizationsAndRebalancePortfolio.run!( # Use run! to see errors
        portfolio: portfolio,
        organization_eins: valid_eins
      )
    else
      puts "  Skipping AddOrganizationsAndRebalancePortfolio for portfolio #{portfolio.id} due to no valid EINs."
    end
  end
end

# Ensure there are some organizations to sample from for portfolio creation
unless Organization.any?
  raise "CRITICAL ERROR: No organizations found in the database. Cannot create ManagedPortfolios that require organizations."
end

# Create ManagedPortfolios for us_partner
ManagedPortfolio.find_or_create_by!(partner: us_partner, name: 'Random Picks') do |mp|
  mp.description = 'Molestiae rem esse. Qui ipsum vel. Dolores earum quaerat.'
  mp.portfolio = create_portfolio_with_charities(Organization.all.pluck(:ein).sample(8))
end
# ... (other ManagedPortfolios for us_partner, ensure Organization.first/last exist if used) ...

# Create ManagedPortfolios for default_partner
ManagedPortfolio.find_or_create_by!(partner: default_partner, name: 'Random Picks') do |mp|
  mp.description = 'Soluta voluptatum et. Id impedit consequuntur. Aut consequatur id.'
  mp.portfolio = create_portfolio_with_charities(Organization.all.pluck(:ein).sample(8))
end

# Create ManagedPortfolios for uk_partner
ManagedPortfolio.find_or_create_by!(partner: uk_partner, name: 'Random Picks') do |mp|
  mp.description = 'Totam ut perspiciatis. Cumque a consectetur. Soluta voluptate et.'
  mp.portfolio = create_portfolio_with_charities(Organization.all.pluck(:ein).sample(8))
end
# ... (other ManagedPortfolios for uk_partner) ...

# Create "Example Portfolio A/B/C" for all OFTW Partners
Partners::GetOftwPartners.call.each do |partner|
  next unless Organization.any? # Skip if no orgs for sampling

  ManagedPortfolio.find_or_create_by!(partner: partner, name: "Example Portfolio A for #{partner.name}") do |mp|
    mp.display_order = 0
    mp.description = 'This example portfolio is associated to all of the charities...'
    mp.portfolio = create_portfolio_with_charities(Organization.all.pluck(:ein))
    mp.featured = true
  end
  # ... (Example B and C, ensure Organization.last exists or sample robustly) ...
  if Organization.any?
    ManagedPortfolio.find_or_create_by!(partner: partner, name: "Example Portfolio B for #{partner.name}") do |mp|
      mp.display_order = 1
      mp.description = 'This example portfolio is associated to just one charity...'
      mp.portfolio = create_portfolio_with_charities([Organization.order("RANDOM()").first.ein]) # Get a random one
      mp.featured = true
    end
    ManagedPortfolio.find_or_create_by!(partner: partner, name: "Example Portfolio C for #{partner.name}") do |mp|
      mp.display_order = 2
      mp.description = 'This example portfolio is associated to 8 randomly picked charities...'
      mp.portfolio = create_portfolio_with_charities(Organization.all.pluck(:ein).sample(8))
      mp.featured = true
    end
  end
end
puts "Ensured ManagedPortfolios."


# === SECTION FOR ADDITIONAL TEST DONORS, SUBSCRIPTIONS, CONTRIBUTIONS ===
puts "\n--- Seeding Additional Test Donors, Subscriptions, and Contributions ---"

# 1. Fetch prerequisite Partner and Portfolio data robustly
puts "Fetching prerequisite Partner and Portfolio data for additional seeds..."
# These partners (us_partner, uk_partner) should already be defined and fetched from earlier in this script.
# Let's ensure they are not nil just in case.
us_partner ||= Partner.find_by!(name: 'Seeded/test OFTW US')
uk_partner ||= Partner.find_by!(name: 'Seeded/test OFTW UK')

# Find the ManagedPortfolio and ensure its associated Portfolio exists
# Using the "Example Portfolio A for..." which is explicitly created above for these partners
us_mp = ManagedPortfolio.find_by(partner: us_partner, name: "Example Portfolio A for #{us_partner.name}")
unless us_mp && us_mp.portfolio && us_mp.portfolio.persisted?
  raise "Critical Error: US Managed Portfolio 'Example Portfolio A for #{us_partner.name}' or its underlying Portfolio not found/persisted. Check main seed section."
end
us_portfolio_for_seeds = us_mp.portfolio # Use a distinct variable name
puts "Using US Portfolio ID: #{us_portfolio_for_seeds.id} (from MP: #{us_mp.name}) for test seeds."

uk_mp = ManagedPortfolio.find_by(partner: uk_partner, name: "Example Portfolio A for #{uk_partner.name}")
unless uk_mp && uk_mp.portfolio && uk_mp.portfolio.persisted?
  raise "Critical Error: UK Managed Portfolio 'Example Portfolio A for #{uk_partner.name}' or its underlying Portfolio not found/persisted. Check main seed section."
end
uk_portfolio_for_seeds = uk_mp.portfolio # Use a distinct variable name
puts "Using UK Portfolio ID: #{uk_portfolio_for_seeds.id} (from MP: #{uk_mp.name}) for test seeds."


# 2. Create Test Donors
puts "\nCreating test donors..."
test_donor1 = Donor.find_or_create_by!(email: "seed.donor1@example.com") do |d|
  d.first_name = "Seed"
  d.last_name = "DonorOne"
end
puts "Ensured Donor: #{test_donor1.name}"

test_donor2 = Donor.find_or_create_by!(email: "seed.donor2@example.com") do |d|
  d.first_name = "Seed"
  d.last_name = "DonorTwo"
end
puts "Ensured Donor: #{test_donor2.name}"

# 3. Affiliate Donors with Partners
puts "\nCreating partner affiliations..."
Partners::AffiliateDonorWithPartner.run(donor: test_donor1, partner: us_partner)
Partners::AffiliateDonorWithPartner.run(donor: test_donor2, partner: uk_partner)
puts "Affiliated test donors with partners."

# 4. Create Payment Methods for these Test Donors
puts "\nCreating payment methods for test donors..."
PaymentMethods::Card.find_or_create_by!(donor: test_donor1, payment_processor_source_id: "pm_seed_visa_td1") do |pm|
  pm.name = "#{test_donor1.first_name} #{test_donor1.last_name}"
  pm.last4 = "4242"
  pm.institution = "Visa"
  pm.payment_processor_customer_id = "cus_seed_#{test_donor1.id}"
end
puts "Payment method for #{test_donor1.email} ensured."

PaymentMethods::Card.find_or_create_by!(donor: test_donor2, payment_processor_source_id: "pm_seed_visa_td2") do |pm|
  pm.name = "#{test_donor2.first_name} #{test_donor2.last_name}"
  pm.last4 = "1234"
  pm.institution = "Mastercard"
  pm.payment_processor_customer_id = "cus_seed_#{test_donor2.id}"
end
puts "Payment method for #{test_donor2.email} ensured."

# Verify active payment methods exist
unless Payments::GetActivePaymentMethod.call(donor: test_donor1)
  raise "Active payment method NOT found for #{test_donor1.email} after direct creation."
end
unless Payments::GetActivePaymentMethod.call(donor: test_donor2)
  raise "Active payment method NOT found for #{test_donor2.email} after direct creation."
end
puts "Verified active payment methods exist for these test donors."


# 5. Create Subscriptions for these Test Donors (using migration: true)
puts "\nCreating subscriptions for test donors (with migration flag)..."
sub1_outcome = Contributions::CreateOrReplaceSubscription.run(
  donor: test_donor1,
  portfolio: us_portfolio_for_seeds,
  partner: us_partner,
  frequency: "monthly",
  amount_cents: 1500,
  start_at: 1.day.from_now.to_date,
  tips_cents: 0,
  partner_contribution_percentage: us_partner.platform_fee_percentage.to_i,
  migration: true
)
puts "Subscription 1 for #{test_donor1.email} outcome success?: #{sub1_outcome.success?}"
# Corrected error check:
puts "Errors: #{sub1_outcome.errors.full_messages.join(', ')}" if sub1_outcome.errors&.any?


sub2_outcome = Contributions::CreateOrReplaceSubscription.run(
  donor: test_donor2,
  portfolio: uk_portfolio_for_seeds,
  partner: uk_partner,
  frequency: "annually",
  amount_cents: 12000,
  start_at: 2.days.from_now.to_date,
  tips_cents: 1000,
  partner_contribution_percentage: uk_partner.platform_fee_percentage.to_i,
  migration: true
)
puts "Subscription 2 for #{test_donor2.email} outcome success?: #{sub2_outcome.success?}"
# Corrected error check:
puts "Errors: #{sub2_outcome.errors.full_messages.join(', ')}" if sub2_outcome.errors&.any?

# 6. Create a "Past" Donor with Past Contributions
puts "\n--- Seeding Past Donor, Subscription, Contributions, and Donations ---"
past_donor = Donor.find_or_create_by!(email: "past.donor.gamma@example.com") do |d|
  d.first_name = "PastGamma"
  d.last_name = "Contributor"
end
puts "Ensured Past Donor: #{past_donor.name}"

Partners::AffiliateDonorWithPartner.run(donor: past_donor, partner: us_partner)
puts "Affiliated Past Donor with Partner: #{us_partner.name}"

PaymentMethods::Card.find_or_create_by!(donor: past_donor, payment_processor_source_id: "pm_seed_visa_past_gamma") do |pm|
  pm.name = "#{past_donor.first_name} #{past_donor.last_name}"; pm.last4 = "PAST"; pm.institution = "Visa"; pm.payment_processor_customer_id = "cus_seed_#{past_donor.id}"
end
puts "Created Payment Method for Past Donor."

puts "Creating past subscription for #{past_donor.email} using portfolio_id: #{us_portfolio_for_seeds.id}..."
past_subscription_outcome = Contributions::CreateOrReplaceSubscription.run(
  donor: past_donor,
  portfolio: us_portfolio_for_seeds,
  partner: us_partner,
  frequency: "monthly",
  amount_cents: 2500,
  start_at: 4.months.ago.beginning_of_month.to_date,
  tips_cents: 0,
  partner_contribution_percentage: us_partner.platform_fee_percentage.to_i,
  migration: true
)

unless past_subscription_outcome.success?
  raise "ERROR: Failed to create past_subscription for #{past_donor.email}. Errors: #{past_subscription_outcome.errors.full_messages.join(', ')}"
end

# Reliably fetch the active subscription for this donor/partner/portfolio
past_subscription = Subscription.where(
  donor: past_donor,
  partner: us_partner,
  portfolio: us_portfolio_for_seeds,
  deactivated_at: nil
).order(created_at: :desc).first

unless past_subscription
  raise "ERROR: Could not find the active subscription for #{past_donor.email} after service call. This should not happen if the service succeeded."
end
puts "Found/Created active past subscription ID: #{past_subscription.id} for #{past_donor.email}, starting #{past_subscription.start_at.to_date}"

puts "Creating past contributions and donations for subscription ID: #{past_subscription.id}..."
num_past_contributions_to_seed = 3
num_past_contributions_to_seed.times do |i|
  contribution_date = past_subscription.start_at + i.months
  next if contribution_date > Time.current

  contribution = Contribution.find_or_create_by!(
    donor_id: past_subscription.donor_id,
    portfolio_id: past_subscription.portfolio_id,
    partner_id: past_subscription.partner_id,
    scheduled_at: contribution_date
  ) do |c|
    c.amount_cents = past_subscription.amount_cents
    c.amount_currency = past_subscription.amount_currency
    c.tips_cents = past_subscription.tips_cents || 0
    c.payment_status = "succeeded"
    c.processed_at = contribution_date + 1.hour
    c.payment_processor_account_id = past_subscription.partner.payment_processor_account_id
    c.amount_donated_after_fees_cents = c.amount_cents # Or apply fee logic
    c.external_reference_id = "seed_past_#{past_subscription.id}_#{contribution_date.strftime('%Y%m%d')}" # More unique
  end
  puts "  Ensured past Contribution ID: #{contribution.id} for #{contribution_date.to_date}"

  if contribution.persisted? && contribution.donations.empty?
    puts "    Running Donations::CreateDonationsFromContributionIntoPortfolio for Contribution ID: #{contribution.id}..."
    service_result = Donations::CreateDonationsFromContributionIntoPortfolio.run(
      contribution: contribution,
      donation_amount_cents: contribution.amount_donated_after_fees_cents || contribution.amount_cents
    )
    if service_result.success?
      puts "      Created #{contribution.donations.reload.count} donations for this contribution."
    else
      puts "      ERROR creating donations for Contribution ID #{contribution.id}: #{service_result.errors.try(:full_messages)&.join(', ') || service_result.try(:errors).inspect}"
    end
  elsif contribution.persisted?
    puts "    Donations already exist or contribution wasn't in a state to process for Contribution ID: #{contribution.id}"
  end
end

puts "\n--- Additional test data seeding complete! ---"
puts "\n--- Full Database Seed Process Finished ---"

# --- In Heroku Rails Console ---

# 1. Define your admin user's details
admin_email = "lizeth.durang@gmail.com"
admin_first_name = "Lizeth"
admin_last_name = "Duran"

# 2. Find or Create the Admin Donor record
# Using find_or_create_by! to avoid duplicates and ensure it's created if missing.
# The block sets attributes only if a new record is being created.
admin_donor = Donor.find_or_create_by!(email: admin_email) do |d|
  d.first_name = admin_first_name
  d.last_name = admin_last_name
  # Add any other attributes that are absolutely required by Donor model validations
  # The `username` will be auto-generated by the `before_create :generate_username` callback.
end

if admin_donor.persisted?
  puts "SUCCESS: Admin Donor ensured/found: ID #{admin_donor.id}, Email: #{admin_donor.email}, Name: #{admin_donor.name}"
else
  # This case should not be reached if find_or_create_by! is used without it raising an error.
  puts "ERROR: Admin Donor could not be created or found. Errors: #{admin_donor.errors.full_messages.join(', ')}"
  # If you see this, there was a validation error during create. STOP HERE.
end

# 3. Identify the Partners you want this donor to administer
# These names come from your db/seeds.rb file.
partner_names_to_admin = [
  Partner::DEFAULT_PARTNER_NAME, # This is 'Donational'
  'Seeded/test OFTW US',
  'Seeded/test OFTW UK'
  # Add 'Seeded/test OFTW Canada', 'Seeded/test OFTW Australia' if needed
]

# 4. Associate the Admin Donor with these Partners
if admin_donor.persisted? # Proceed only if donor record is valid
  puts "\nAssociating '#{admin_donor.email}' with partners..."
  partner_names_to_admin.each do |partner_name|
    partner_to_link = Partner.find_by(name: partner_name)

    if partner_to_link
      # The `has_and_belongs_to_many :donors` association on Partner model is used here.
      # Adding to `admin_donor.partners` creates the link in the join table.
      unless admin_donor.partners.include?(partner_to_link)
        admin_donor.partners << partner_to_link
        puts "  SUCCESS: Associated with Partner '#{partner_to_link.name}'."
      else
        puts "  INFO: Already associated with Partner '#{partner_to_link.name}'."
      end
    else
      puts "  WARNING: Partner '#{partner_name}' not found in the database. Skipping association."
    end
  end

  # Verify the associations
  puts "\nVerification: Admin Donor '#{admin_donor.email}' (ID: #{admin_donor.id}) is now administrator for partners:"
  admin_donor.partners.reload.each do |p| # Use reload to get the freshest association data
    puts "  - #{p.name} (ID: #{p.id})"
  end
  if admin_donor.partners.empty? && partner_names_to_admin.any? { |name| Partner.exists?(name: name) }
     puts "VERIFICATION FAILED: No partners seem to be associated. Check partner names and previous logs."
  end
else
  puts "Admin donor record was not successfully created or found. Cannot associate with partners."
end

puts "\nAdmin setup for '#{admin_email}' complete."