# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy.
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header

Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self
    policy.font_src    :self, :https, :data
    policy.img_src     :self, :https, :data
    policy.object_src  :none
    policy.script_src  :self, :unsafe_inline, :https
    policy.style_src   :self, :unsafe_inline, :https
    policy.connect_src :self, :https
    policy.frame_ancestors :none
    policy.base_uri    :self
    policy.form_action :self
  end

  # Start in report-only mode to avoid breaking existing inline scripts/styles.
  # After verifying no violations in production logs, switch to enforcing mode
  # by removing/commenting this line.
  config.content_security_policy_report_only = true
end
