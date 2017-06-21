module Questions
  class LocalOrGlobalImpact < MultipleChoiceQuestion
    message 'Individuals in high-income countries have the ability to do an incredible amount of good.'
    message 'The decision to give globally or locally is personal, but has strong implications on the *effectiveness* of every dollar donated.'
    message "A dollar donated to a program that helps the world's poorest people can go much further than a similar program in the USA (or other countries with substantially higher costs)"
    message 'For example, a single visit an emergency room in the USA costs upwards of $1000, whereas just $50 can fund an operation to restore sight to a blind person in a developing country.'
    message 'Knowing that your money goes further overseas, where would you like to focus your portfolio of charities?'

    allowed_response 1, 'Local'
    allowed_response 2, 'Mostly local'
    allowed_response 4, 'Mostly global'
    allowed_response 5, 'Global'

    def save(response)
      Rails.logger.info(response)
      true
    end

    def coerce(raw_value)
      raw_value.to_i
    end
  end
end
