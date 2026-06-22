class ApplicationController < ActionController::Base
  include Authentication
  include GuestAccess
  include SentryContext

  allow_browser versions: :modern

  before_action :load_nav_locations, if: :logged_in?

  helper_method :site_name, :site_setting, :app_version, :github_repo_url

  def app_version
    AppInfo.version
  end

  def github_repo_url
    AppInfo.github_repo_url
  end

  def site_name
    SiteSetting.instance.site_name
  rescue ActiveRecord::StatementInvalid, ActiveRecord::NoDatabaseError, ActiveRecord::RecordNotFound
    'PDX Hackerspace Library'
  end

  def site_setting
    SiteSetting.instance
  rescue ActiveRecord::StatementInvalid, ActiveRecord::NoDatabaseError, ActiveRecord::RecordNotFound
    SiteSetting.new(site_name: 'PDX Hackerspace Library', loan_period_days: 30)
  end

  def load_nav_locations
    @nav_locations = Location.with_inventory_counts.alphabetical
  rescue ActiveRecord::StatementInvalid, ActiveRecord::NoDatabaseError
    @nav_locations = []
  end
end
