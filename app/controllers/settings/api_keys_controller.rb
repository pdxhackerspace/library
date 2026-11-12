module Settings
  class ApiKeysController < ApplicationController
    before_action :require_admin

    def create
      @api_key = ApiKey.generate(name: params.dig(:api_key, :name).to_s.strip, created_by: current_user)

      if @api_key.save
        # Rendered (not redirected) so the plain token never lands in the session cookie.
        response.headers['Cache-Control'] = 'no-store'
        render :create
      else
        redirect_to settings_path(anchor: 'api-keys'), alert: @api_key.errors.full_messages.to_sentence
      end
    end

    def destroy
      ApiKey.find(params.expect(:id)).destroy!
      redirect_to settings_path(anchor: 'api-keys'), notice: 'API key revoked.'
    end
  end
end
