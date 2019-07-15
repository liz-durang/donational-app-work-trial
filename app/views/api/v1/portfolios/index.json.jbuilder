json.portfolios @managed_portfolios do |managed_portfolio|
  json.partial! 'info', managed_portfolio: managed_portfolio
end
