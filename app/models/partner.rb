# frozen_string_literal: true

# == Schema Information
#
# Table name: partners
#
#  id                                :uuid             not null, primary key
#  name                              :string
#  website_url                       :string
#  description                       :text
#  platform_fee_percentage           :decimal(, )      default(0.0)
#  primary_branding_color            :string
#  created_at                        :datetime         not null
#  updated_at                        :datetime         not null
#  donor_questions_schema            :jsonb
#  payment_processor_account_id      :string
#  api_key                           :string
#  operating_costs_text              :string
#  operating_costs_organization_ein  :string
#  currency                          :string           default("usd"), not null
#  email_receipt_preamble            :text
#  after_donation_thank_you_page_url :string
#  receipt_first_paragraph           :text
#  receipt_second_paragraph          :text
#  receipt_tax_info                  :text
#  receipt_charity_name              :string
#  donor_advised_fund_fee_percentage :decimal(, )      default(0.01)
#

class Partner < ApplicationRecord
  has_many :campaigns
  has_many :contributions
  has_many :subscriptions
  has_many :managed_portfolios, -> { order(:display_order) }
  has_many :zapier_webhooks
  # Partner administrators
  has_and_belongs_to_many :donors
  has_one_attached :logo
  has_one_attached :email_banner
  belongs_to :operating_costs_organization,
             class_name: 'Organization',
             optional: true,
             foreign_key: :operating_costs_organization_ein

  validates :currency, inclusion: { in: Money::Currency,
                                    message: '%{value} is not a valid currency iso code' }

  before_create :generate_api_key

  DEFAULT_PARTNER_NAME = 'Donational'

  def accepts_operating_costs_donations?
    operating_costs_organization_ein.present?
  end

  def default_operating_costs_donation_percentages
    [0, 5, 10]
  end

  def donor_questions
    return if donor_questions_schema.nil?

    donor_questions_schema['questions'].map do |q|
      DonorQuestion.new(
        name: q['name'],
        title: q['title'],
        type: q['type'],
        options: q['options'],
        required: q['required']
      )
    end
  end

  def donor_questions=(questions)
    donor_questions_schema['questions'] = questions
  end

  class DonorQuestion
    include ActiveModel::Model

    attr_reader :name, :title, :type, :options, :required

    def initialize(name: nil, title: nil, type: nil, options: nil, required: nil)
      @name = name
      @title = title
      @type = type
      @options = options || []
      @required = required || false
    end

    def binary_select?
      type == 'select' && options.sort == %w[Yes No].sort
    end

    def dropdown?
      type == 'select' && !binary_select?
    end
  end

  def supports_gift_aid?
    currency.downcase == 'gbp'
  end

  def supports_plaid?
    return false unless ENV['PLAID_ENABLED'].presence == 'true'

    currency.downcase == 'usd'
  end

  def active?
    deactivated_at.nil?
  end

  def supports_acss?
    return false unless ENV['ACSS_ENABLED'].presence == 'true'

    /cad/i.match?(currency)
  end

  private

  def generate_api_key
    return if api_key.present?

    candidate_api_key = SecureRandom.base64.tr('+/=', 'Qrt')

    if Partner.exists?(api_key: candidate_api_key)
      generate_api_key
    else
      self.api_key = candidate_api_key
    end
  end
end
