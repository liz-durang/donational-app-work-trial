module Questions
  class LocalOrGlobalImpact < MultipleChoiceQuestion
    message 'Individuals in high-income countries have the ability to do an incredible amount of good.'
    message 'The decision to give globally or locally is personal, but has strong implications on the *effectiveness* of every dollar donated.'
    message "A dollar donated to a program that helps the world's poorest people can go much further than a similar program in the USA (or other countries with substantially higher costs)"
    message 'For example, a single visit an emergency room in the USA costs upwards of $1000, whereas just $50 can fund an operation to restore sight to a blind person in a developing country.'
    message 'Knowing that your money goes further overseas, where would you like to focus the impact of your portfolio of charities?'

    allowed_response :local, 'Local (USA only)'
    allowed_response :both, 'Local and Global'
    allowed_response :global, 'Global'

    def save
      Rails.logger.info(response)
      true
    end
  end
end
