# frozen_string_literal: true

Mailgun.configure do |config|
  config.api_key = FemboyFans.config.mailgun_api_key
end
