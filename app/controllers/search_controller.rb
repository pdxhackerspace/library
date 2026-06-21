class SearchController < ApplicationController
  before_action :require_login

  def index
    @query = params.permit(:q)[:q].to_s.strip
    @results = GlobalSearch::Query.call(@query, include_users: current_user.admin?)
  end
end
