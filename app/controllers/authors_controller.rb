class AuthorsController < ApplicationController
  before_action :require_login
  before_action :set_author, only: :show

  def index
    @authors = Author.with_inventory_counts.order(:name).to_a
  end

  def show
    @books = @author.books.includes(:authors, :isbns, :location).ordered
    @copies_count = @books.sum(&:copies_count)
  end

  private

  def set_author
    @author = Author.find(params.expect(:id))
  end
end
