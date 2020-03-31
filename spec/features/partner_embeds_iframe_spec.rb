require 'rails_helper'

RSpec.describe 'Partner embeds iframe', type: :feature do
  before do
    create_new_partner!
  end

  skip 'campaign page', js: true do
    given_a_partner_embeds_iframe('campaign')
    campaign_page_iframe_should_be_rendered
  end

  skip 'donation box', js: true do
    given_a_partner_embeds_iframe('donation_box')
    donation_box_iframe_should_be_rendered
  end

  def given_a_partner_embeds_iframe(page)
    if page == 'campaign'
      widget_js_url = campaigns_url(
        '1ftw-wharton',
        format: :js,
        host: Capybara.current_session.server.host,
        port: Capybara.current_session.server.port
      )
    else
      widget_js_url = campaigns_donation_box_url(
        '1ftw-wharton',
        format: :js,
        host: Capybara.current_session.server.host,
        port: Capybara.current_session.server.port
      )
    end

    proxy
      .stub('http://1fortheworld.org/')
      .and_return(
        code: 200,
        body: "<html><body><script id='load_widget' src='#{widget_js_url}'></script></body></html>"
      )

    visit "http://1fortheworld.org/"
  end

  def campaign_page_iframe_should_be_rendered
    expect(page).to have_selector('iframe')

    iframe = all('iframe')[0]
    within_frame iframe do
      expect(page).to have_content('Donational')
      expect(page).to have_content('One for the World')
      expect(page).to have_content('The Wharton School')
      expect(page).to have_content('Donate now')
      expect(page).to have_content('Donation frequency')
    end
  end

  def donation_box_iframe_should_be_rendered
    expect(page).to have_selector('iframe')

    iframe = all('iframe')[0]
    within_frame iframe do
      expect(page).to have_content('Donate now')
      expect(page).to have_content('Donation frequency')
      expect(page).to have_content('We use smart and secure online payments to ensure that your donations are simple, secure, and avoid fees.')
      expect(page).to have_content('Next')
    end
  end

  def create_new_partner!
    partner = Partner.create(
      name: 'One for the World',
      website_url: 'http://1fortheworld.org',
      platform_fee_percentage: 0.02,
      currency: 'usd',
      payment_processor_account_id: 'acc_123',
      donor_questions_schema: {
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
    )

    Campaign.create(
      partner: partner,
      title: 'The Wharton School',
      slug: '1ftw-wharton',
      default_contribution_amounts: [10, 20, 50, 100, 200]
    )
  end
end
