# == Schema Information
#
# Table name: partners
#
#  id                           :uuid             not null, primary key
#  name                         :string
#  website_url                  :string
#  description                  :text
#  platform_fee_percentage      :decimal(, )      default(0.0)
#  primary_branding_color       :string
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#  donor_questions_schema       :jsonb
#  payment_processor_account_id :string
#

class Partner < ApplicationRecord
  has_many :campaigns
  has_many :managed_portfolios, -> { order(:display_order) }
  # Partner administrators
  has_and_belongs_to_many :donors
  has_one_attached :logo
  has_one_attached :email_banner

  before_create :generate_api_key

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
  end

  private

  def generate_api_key
    return if api_key.present?

    candidate_api_key = SecureRandom.base64.tr('+/=', 'Qrt')

    if Partner.exists?(api_key: api_key)
      generate_api_key
    else
      self.api_key = candidate_api_key
    end
  end
end
