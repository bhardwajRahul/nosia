# Be sure to restart your server when you modify this file.

# Baseline content security policy: containment directives that carry no
# rendering risk. A full script/style policy (with nonces) requires porting
# the remaining inline <script> blocks (dashboards, mcp server form) to
# Stimulus controllers first.
Rails.application.configure do
  config.content_security_policy do |policy|
    policy.frame_ancestors :self
    policy.object_src :none
    policy.base_uri :self
  end
end
