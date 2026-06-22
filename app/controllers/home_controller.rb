class HomeController < ApplicationController
  before_action :require_guest_browse

  def index
    sections = Home::Sections.call
    @recent_books = sections[:recent_books]
    @random_books = sections[:random_books]
    @popular_books = sections[:popular_books]
    @featured_subject = sections[:featured_subject]
    @subject_books = sections[:subject_books]
  end
end
