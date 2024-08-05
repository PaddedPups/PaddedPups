# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy.
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header

Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src(:self)
    policy.script_src(:self, "https://www.google.com/recaptcha/", "https://www.gstatic.com/recaptcha/", "https://www.recaptcha.net/", "https://cdnjs.cloudflare.com", "https://plausible.furry.computer")
    policy.style_src(:self, :unsafe_inline, "https://cdnjs.cloudflare.com")
    policy.connect_src(:self, "https://plausible.furry.computer")
    policy.object_src(:self, "static.paddedpups.xyz")
    policy.media_src(:self, "static.paddedpups.xyz")
    policy.frame_ancestors(:none)
    policy.frame_src("https://www.google.com/recaptcha/", "https://www.recaptcha.net/")
    policy.font_src(:self)
    policy.img_src(:self, :data, :blob, "static.paddedpups.xyz")
    policy.child_src(:none)
    policy.form_action(:self, "discord.paddedpups.xyz", "discord.com")
    # Specify URI for violation reports
    # policy.report_uri "/csp-violation-report-endpoint"
  end

  # Generate session nonces for permitted importmap and inline scripts
  config.content_security_policy_nonce_generator = ->(_request) { SecureRandom.base64(16) }
  config.content_security_policy_nonce_directives = %w[script-src]

  # Report violations without enforcing the policy.
  config.content_security_policy_report_only = false
end
