module SentryContext
  extend ActiveSupport::Concern

  included do
    before_action :set_sentry_context
  end

  private

  def set_sentry_context
    return unless SentryConfig.configured?

    if logged_in?
      Sentry.set_user(
        id: current_user.id.to_s,
        email: current_user.email,
        username: current_user.name
      )
    else
      Sentry.set_user(ip_address: request.remote_ip)
    end
  end
end
