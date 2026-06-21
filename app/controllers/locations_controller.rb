class LocationsController < ApplicationController
  before_action :require_login
  before_action :set_location, only: :show

  def index
    @locations = Location.with_inventory_counts.order(:name).to_a
  end

  def show
    @locations = Location.with_inventory_counts.alphabetical.to_a
    @books = @location.books.includes(:authors, :isbns, :location).ordered
    @copies_count = @books.sum(&:copies_count)
  end

  private

  def set_location
    @location = Location.find(params.expect(:id))
  end
end
