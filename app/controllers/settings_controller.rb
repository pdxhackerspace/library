class SettingsController < ApplicationController
  before_action :require_admin

  def show
    @site_setting = SiteSetting.instance
    @locations = Location.with_inventory_counts.ordered.to_a
  end

  def update
    @site_setting = SiteSetting.instance

    if @site_setting.update(site_setting_params)
      redirect_to settings_path, notice: 'Settings saved.'
    else
      @locations = Location.with_inventory_counts.ordered.to_a
      render :show, status: :unprocessable_content
    end
  end

  def books_csv
    send_data Books::ExportCsv.call,
              filename: "books-#{Date.current.iso8601}.csv",
              type: 'text/csv; charset=utf-8',
              disposition: 'attachment'
  end

  private

  def site_setting_params
    params.expect(site_setting: %i[site_name loan_period_days overdue_nag_interval_days matomo_url matomo_site_id])
  end
end
