module Settings
  class LocationsController < ApplicationController
    before_action :require_admin
    before_action :set_location, only: %i[update destroy]

    def create
      @location = Location.new(location_params)

      if @location.save
        redirect_to settings_path(anchor: 'locations'), notice: 'Location added.'
      else
        redirect_to settings_path(anchor: 'locations'), alert: @location.errors.full_messages.to_sentence
      end
    end

    def update
      if @location.update(location_params)
        redirect_to settings_path(anchor: 'locations'), notice: 'Location updated.'
      else
        redirect_to settings_path(anchor: 'locations'), alert: @location.errors.full_messages.to_sentence
      end
    end

    def destroy
      @location.destroy!
      redirect_to settings_path(anchor: 'locations'), notice: 'Location removed.'
    end

    private

    def set_location
      @location = Location.find(params.expect(:id))
    end

    def location_params
      params.expect(location: %i[name position])
    end
  end
end
