module GuestAccess
  extend ActiveSupport::Concern

  included do
    helper_method :on_space?, :guest_browse?
  end

  def on_space?
    return @on_space if defined?(@on_space)

    @on_space = NetworkAccess.on_space?(request.remote_ip)
  end

  def guest_browse?
    logged_in? || on_space?
  end

  def require_guest_browse
    return if guest_browse?

    redirect_to login_path, alert: 'Please sign in to continue.'
  end
end
