class PublishersController < ApplicationController
  before_action :require_login

  def index
    @publishers = Book.where.not(publisher: [nil, ''])
                      .group(:publisher)
                      .order(Arel.sql('LOWER(publisher)'))
                      .count
  end

  def show
    @publisher_name = params.expect(:name)
    @books = Book.includes(:authors, :isbns, :location)
                 .where(publisher: @publisher_name)
                 .ordered
  end
end
