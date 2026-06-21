module Authentication
  extend ActiveSupport::Concern

  included do
    helper_method :current_user, :logged_in?, :can_manage_books?
  end

  def current_user
    return @current_user if defined?(@current_user)

    @current_user = session[:user_id].present? ? User.find_by(id: session[:user_id]) : nil
  end

  def logged_in?
    current_user.present?
  end

  def require_login
    return if logged_in?

    redirect_to login_path, alert: 'Please sign in to continue.'
  end

  def can_manage_books?
    current_user&.can_manage_books?
  end

  def require_editor
    require_login
    return unless logged_in?
    return if can_manage_books?

    redirect_to root_path, alert: 'Editor access required.'
  end

  def require_admin
    require_login
    return unless logged_in?
    return if current_user.admin?

    redirect_to root_path, alert: 'Admin access required.'
  end
end
