Stripe.api_key = ENV.fetch('STRIPE_SECRET_KEY')

# Enable automatic, idempotent retries on requests that fail due to a transient network problem by configuring the maximum number of retries
# https://github.com/stripe/stripe-ruby?tab=readme-ov-file#configuring-automatic-retries
Stripe.max_network_retries = 2
