class SubjectsController < ApplicationController
  before_action :require_login
  before_action :set_subject, only: :show

  def index
    @subjects = Subject.with_inventory_counts.order(:name).to_a
  end

  def show
    @books = @subject.books.includes(:authors, :isbns, :location).ordered
    @copies_count = @books.sum(&:copies_count)
  end

  private

  def set_subject
    @subject = Subject.find(params.expect(:id))
  end
end
