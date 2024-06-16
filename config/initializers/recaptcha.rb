# frozen_string_literal: true

Recaptcha.configure do |config|
  config.site_key   = FemboyFans.config.recaptcha_site_key
  config.secret_key = FemboyFans.config.recaptcha_secret_key
  # config.proxy = "http://example.com"
end
