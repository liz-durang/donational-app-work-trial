# This form object duplicates some front-end validations and adds some others.
class PledgeForm
  include ActiveModel::Model

  ATTRIBUTES = %i[amount_cents
                  associated_with_chapter
                  email
                  estimated_future_annual_income
                  first_name
                  house_name_or_number
                  last_name
                  managed_portfolio_id
                  partner_id
                  payment_method_id
                  payment_processor_customer_id
                  payment_processor_payment_method_id
                  payment_processor_payment_method_type
                  pledge_percentage
                  postcode
                  start_at_month
                  start_at_year
                  start_pledge_in_future
                  stripe_session_id
                  title
                  trial_amount_dollars
                  uk_gift_aid_accepted].freeze
  attr_accessor(*ATTRIBUTES)

  def steps_before_payment_processor_are_valid?
    must_be_present = %i[partner_id managed_portfolio_id estimated_future_annual_income pledge_percentage
                         payment_method_id]
    must_be_present += %i[uk_gift_aid_accepted] if partner.supports_gift_aid?
    must_be_present += %i[start_at_month start_at_year] if start_pledge_in_future.to_s == '1'
    must_be_present.each { |attr| errors.add(attr, 'blank') if send(attr).blank? }
    validate_portfolio
    errors.empty?
  end

  # TODO: Add more validations
  validates :estimated_future_annual_income, numericality: { greater_than: 0 }
  validates :pledge_percentage, numericality: { greater_than: 0, less_than_or_equal_to: 100 }
  validate :ensure_email_not_used!

  private

  def ensure_email_not_used!
    return unless Donor.exists?(email:, deactivated_at: nil)

    errors.add(:email, :email_already_used,
               message: 'This email address has already been used. If you already have a One for the World pledge, you can edit it at any time by logging into Donational.org')
  end

  def validate_portfolio
    # Validates that the portfolio selected and the partner match up as expected.
    return if managed_portfolio_id.in?(Partners::GetManagedPortfoliosForPartner.call(partner:).pluck(:id))

    errors.add(:managed_portfolio_id, 'invalid')
  end

  def partner
    @partner = Partners::GetPartnerById.call(id: partner_id)
  end
end
